#!/bin/bash
# =============================================================================
# Fedora Post-Install Setup Script
# =============================================================================
# Run this script AFTER formatting and installing Fedora (with sudo).
# It automates the system-level part of the setup:
# - DNF speed optimizations
# - Custom repositories (RPM Fusion, Docker, Terra, Tailscale)
# - Package installations (setup/packages/fedora.txt, setup/packages/flatpak.txt)
# - Flathub as the only Flatpak remote (replaces Fedora's own)
# - Restoring backed-up data (SSH keys, home configs, crontab) and ~/dev
# - System services (Docker, Tailscale, cron, key-only sshd, user lingering)
#
# Everything dotfiles-related (dotter, deploy, starship, fish as login shell,
# systemd user services) is delegated to ../install.sh, run as the target user.
# =============================================================================

set -euo pipefail

SETUP_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$SETUP_DIR")"
PACKAGES_DIR="$SETUP_DIR/packages"

# --- Color Codes for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if run as root for system-wide changes
check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_err "This script or section needs to be run with sudo/root privileges."
    exit 1
  fi
}

# Prints the packages listed in packages/<name>.txt, skipping comments
read_packages() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$PACKAGES_DIR/$1.txt" | grep -v '^$'
}

# Runs a command as the target user with access to their systemd user session
run_as_user() {
  local username="$1"
  shift
  local uid
  uid="$(id -u "$username")"
  sudo -u "$username" -H env \
    XDG_RUNTIME_DIR="/run/user/$uid" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
    "$@"
}

# --- 1. DNF Optimizations ---
optimize_dnf() {
  log_info "Optimizing DNF settings..."
  # DNF5 config path is /etc/dnf/dnf.conf (or similar, same as DNF4)
  local dnf_conf="/etc/dnf/dnf.conf"
  if [[ -f "$dnf_conf" ]]; then
    # Check if settings are already present, if not add them
    if ! grep -q "max_parallel_downloads" "$dnf_conf"; then
      echo "max_parallel_downloads=10" >>"$dnf_conf"
      log_info "   - Added max_parallel_downloads=10"
    fi
    if ! grep -q "fastestmirror" "$dnf_conf"; then
      echo "fastestmirror=True" >>"$dnf_conf"
      log_info "   - Added fastestmirror=True"
    fi
  else
    log_warn "   - $dnf_conf not found. Skipping DNF optimization."
  fi
}

# --- 2. Add Repositories ---
add_repos() {
  log_info "Adding custom repositories..."

  # RPM Fusion Free & Nonfree
  log_info "   - Enabling RPM Fusion..."
  dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

  # Docker CE
  log_info "   - Adding Docker CE repository..."
  # curl -L https://download.docker.com/linux/fedora/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
  if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
    dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
  fi

  # Tailscale
  log_info "   - Adding Tailscale repository..."
  if [[ ! -f /etc/yum.repos.d/tailscale.repo ]]; then
    dnf config-manager addrepo --from-repofile https://pkgs.tailscale.com/stable/fedora/tailscale.repo
  fi

  # Terra Repository (Fyra Labs)
  log_info "   - Enabling Terra repository..."
  dnf install -y --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra\$(rpm -E %fedora)" terra-release

  dnf clean all
  dnf makecache -y
}

# --- 3. Install RPM Packages ---
install_rpm_packages() {
  log_info "Installing RPM packages from packages/fedora.txt..."
  local -a packages
  mapfile -t packages < <(read_packages fedora)

  # Missing packages are reported but don't abort the whole transaction
  dnf install -y --skip-unavailable "${packages[@]}"
}

# --- 4. Install Flatpaks ---
# Fedora ships its own "fedora" remote (apps rebuilt from Fedora RPMs) and GNOME
# Software prefers it. Use the official, unfiltered Flathub only, moving any app
# installed from Fedora's remotes over to Flathub
setup_flathub() {
  log_info "Making Flathub the only Flatpak remote..."
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak remote-modify --enable --no-filter flathub

  local remote app
  for remote in fedora fedora-testing; do
    grep -qx "$remote" < <(flatpak remotes --columns=name) || continue
    while read -r app; do
      log_info "   - Reinstalling $app from Flathub..."
      flatpak install -y --noninteractive --reinstall flathub "$app" ||
        log_warn "   - $app is not on Flathub, it stays without updates"
    done < <(flatpak list --app --columns=application,origin | awk -v r="$remote" '$2 == r { print $1 }')
    log_info "   - Removing the '$remote' remote..."
    flatpak remote-delete --force "$remote"
  done
  flatpak uninstall -y --noninteractive --unused
}

install_flatpaks() {
  setup_flathub

  log_info "Installing Flatpak applications from packages/flatpak.txt..."
  local -a flatpaks
  mapfile -t flatpaks < <(read_packages flatpak)
  flatpak install -y --noninteractive flathub "${flatpaks[@]}"
}

# --- 6. Restore backed up data (Non-root user context) ---
# Matches the layout written by backup.sh
restore_backup() {
  local username="$1"
  local backup_path="$2"
  local user_home
  user_home="$(getent passwd "$username" | cut -d: -f6)"

  if [[ ! -d "$backup_path" ]]; then
    log_err "Backup path '$backup_path' does not exist. Skipping restoration."
    return 1
  fi

  log_info "Restoring data from backup at $backup_path..."

  # 1. SSH keys, gh, Syncthing identity, fonts, shell history, home configs.
  # Restored before install.sh, so it neither generates a new SSH key nor gives
  # Syncthing a new device ID
  if [[ -f "$backup_path/home.tar.gz" ]]; then
    log_info "   - Restoring home files (SSH keys, Syncthing, fonts, configs)..."
    sudo -u "$username" tar -xzpf "$backup_path/home.tar.gz" -C "$user_home"
    [[ -d "$user_home/.ssh" ]] && chmod 700 "$user_home/.ssh"
    sudo -u "$username" fc-cache -f >/dev/null 2>&1 || true
  fi

  # 2. A fresh https clone of the dotfiles can't push, switch it to SSH
  local origin
  origin="$(sudo -u "$username" git -C "$user_home/.dotfiles" remote get-url origin 2>/dev/null || true)"
  if [[ "$origin" == https://github.com/* && -f "$user_home/.ssh/id_ed25519" ]]; then
    log_info "   - Switching the dotfiles remote to SSH..."
    sudo -u "$username" git -C "$user_home/.dotfiles" remote set-url origin "git@github.com:${origin#https://github.com/}"
  fi

  # 3. Crontab (runs scripts/rsync.sh), unless the user already has one
  if [[ -s "$backup_path/crontab.txt" ]] && ! crontab -u "$username" -l >/dev/null 2>&1; then
    log_info "   - Restoring crontab..."
    crontab -u "$username" "$backup_path/crontab.txt"
  fi

  if [[ -f "$backup_path/dconf.ini" ]]; then
    log_warn "   - GNOME settings saved at $backup_path/dconf.ini, load what you need with: dconf load / < dconf.ini"
  fi
  if [[ -f "$backup_path/fstab.bak" ]]; then
    log_warn "   - Old fstab kept at $backup_path/fstab.bak, merge mounts into /etc/fstab manually."
  fi
}

# --- 6b. Restore ~/dev from the drive copy made by scripts/rsync.sh ---
# NTFS/exFAT copies have every file at 777 and core.filemode off, so the modes
# are reset to 644/755 and the executable bits come back from each git index
restore_dev() {
  local username="$1"
  local src="$2"
  local user_home
  user_home="$(getent passwd "$username" | cut -d: -f6)"
  local dest="$user_home/dev"

  if [[ ! -d "$src" ]]; then
    log_warn "No ~/dev copy at $src, skipping."
    return
  fi
  if [[ -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
    log_warn "$dest is not empty, not restoring it."
    return
  fi

  log_info "Restoring $dest from $src..."
  sudo -u "$username" rsync -rtp --chmod=D755,F644 "$src/" "$dest/"

  local git_dir repo entry
  while IFS= read -r -d '' git_dir; do
    repo="$(dirname "$git_dir")"
    sudo -u "$username" git -C "$repo" config core.filemode true
    while IFS= read -r -d '' entry; do
      if [[ "$entry" == 100755* ]]; then
        chmod +x "$repo/${entry#*$'\t'}" 2>/dev/null || true
      fi
    done < <(sudo -u "$username" git -C "$repo" ls-files -s -z)
    find "$git_dir/hooks" -type f ! -name '*.sample' -exec chmod +x {} + 2>/dev/null || true
  done < <(find "$dest" -name node_modules -prune -o -name .git -type d -print0 -prune)
}

# --- 7. Configure System Services ---
configure_services() {
  local username="$1"
  log_info "Configuring system services..."

  systemctl daemon-reload
  systemctl enable --now docker
  systemctl enable --now tailscaled
  systemctl enable --now crond

  # SSH server: keys only, since it is reachable from the LAN as well as Tailscale.
  # The 10- prefix wins over Fedora's 50-redhat.conf (first value set is used)
  log_info "Enabling sshd (key authentication only)..."
  printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\n' >/etc/ssh/sshd_config.d/10-keys-only.conf
  systemctl enable --now sshd

  # Enable linger so user services start at boot without active graphical sessions
  log_info "Enabling user lingering for $username..."
  loginctl enable-linger "$username"
}

# --- 8. Deploy dotfiles (Non-root user context) ---
# install.sh owns dotter, deploy, starship, fish as login shell and user services
deploy_dotfiles() {
  local username="$1"
  local user_home
  user_home="$(getent passwd "$username" | cut -d: -f6)"

  local installer="$user_home/.dotfiles/install.sh"
  [[ -x "$installer" ]] || installer="$DOTFILES_DIR/install.sh"

  log_info "Running $installer as $username..."
  run_as_user "$username" "$installer" --profile fedora
}

# --- Main Flow ---
main() {
  check_root

  # Get target username
  local real_user="${SUDO_USER:-$USER}"
  if [[ "$real_user" == "root" ]]; then
    read -p "Enter username to configure: " real_user
  fi

  log_info "============================================================="
  log_info "Fedora Post-Install Provisioning"
  log_info "Targeting User: $real_user"
  log_info "============================================================="

  optimize_dnf
  add_repos
  install_rpm_packages
  install_flatpaks

  # Ask user for backup location to restore
  echo -e "\n============================================================="
  read -p "Would you like to restore data from a backup directory? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    read -p "Enter backup source path [/mnt/media/fedora_migration_backup]: " backup_src
    backup_src="${backup_src:-/mnt/media/fedora_migration_backup}"
    restore_backup "$real_user" "$backup_src" || true
    # rsync.sh keeps ~/dev next to the backup folder, at <drive>/dev
    restore_dev "$real_user" "$(dirname "$backup_src")/dev"
  else
    log_info "Skipping data restore step."
  fi

  configure_services "$real_user"
  deploy_dotfiles "$real_user"

  echo -e "\n============================================================="
  log_info "System configuration completed!"
  log_warn "Log in to Tailscale with 'sudo tailscale up', then pair the phone (ssh/README.md)."
  log_warn "Log in to the GitHub CLI with 'gh auth login' (its token was in the old keyring)."
  log_warn "Please REBOOT your computer to apply all changes (including the shell change)."
  echo -e "============================================================="
}

main "$@"
