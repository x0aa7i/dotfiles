#!/bin/bash
# =============================================================================
# Fedora Post-Install Setup Script
# =============================================================================
# Run this script AFTER formatting and installing Fedora (with sudo).
# It automates the system-level part of the setup:
# - DNF speed optimizations
# - Custom repositories (RPM Fusion, Docker, Terra)
# - Package installations (setup/packages/fedora.txt, setup/packages/flatpak.txt)
# - NVIDIA drivers (when an NVIDIA GPU is detected)
# - Zed editor (installed for the target user)
# - Restoring backed-up data (SSH, GPG, home configs, Wakapi, Flatpak profiles)
# - System services (Docker, user lingering)
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

  # NVIDIA Drivers installation (optional block - run if Nvidia GPU is present)
  if lspci | grep -i nvidia &>/dev/null; then
    log_info "NVIDIA GPU detected. Installing drivers..."
    dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    log_warn "NVIDIA driver installation initiated. NOTE: The kernel modules will compile in the background."
    log_warn "Please wait 5-10 minutes before rebooting, or monitor progress using: 'journalctl -fl -u akmods'"
  fi
}

# --- 4. Install Flatpaks ---
install_flatpaks() {
  log_info "Installing Flatpak applications from packages/flatpak.txt..."
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  local -a flatpaks
  mapfile -t flatpaks < <(read_packages flatpak)
  flatpak install -y flathub "${flatpaks[@]}"
}

# --- 5. Install standalone apps (Non-root user context) ---
install_manual_tools() {
  local username="$1"

  log_info "Installing standalone apps for $username..."

  # Zed installs into the user's ~/.local, so it must not run as root
  log_info "   - Installing Zed Editor..."
  sudo -u "$username" -H sh -c 'curl -f https://zed.dev/install.sh | sh'
}

# --- 6. Restore backed up data (Non-root user context) ---
# Matches the layout written by backup.sh
restore_backup() {
  local username="$1"
  local user_home
  user_home="$(getent passwd "$username" | cut -d: -f6)"
  local backup_path="$2"

  if [[ ! -d "$backup_path" ]]; then
    log_err "Backup path '$backup_path' does not exist. Skipping restoration."
    return 1
  fi

  log_info "Restoring data from backup at $backup_path..."

  # 1. Restore SSH keys (backup.sh stores them as ssh/.ssh)
  local ssh_src="$backup_path/ssh/.ssh"
  [[ -d "$ssh_src" ]] || ssh_src="$backup_path/ssh"
  if [[ -n "$(ls -A "$ssh_src" 2>/dev/null)" ]]; then
    log_info "   - Restoring SSH keys..."
    sudo -u "$username" mkdir -p "$user_home/.ssh"
    sudo -u "$username" cp -rp "$ssh_src/." "$user_home/.ssh/"
    chmod 700 "$user_home/.ssh"
    find "$user_home/.ssh" -type f -exec chmod 600 {} +
    find "$user_home/.ssh" -type f -name '*.pub' -exec chmod 644 {} +
  fi

  # 2. Restore GPG keys
  if [[ -f "$backup_path/gnupg/gnupg.tar.gz" ]]; then
    log_info "   - Restoring GPG keys..."
    sudo -u "$username" tar -xzf "$backup_path/gnupg/gnupg.tar.gz" -C "$user_home/"
    chmod 700 "$user_home/.gnupg"
  fi

  # 3. Restore standalone home config files (.npmrc, .aicommits, ...)
  if [[ -d "$backup_path/configs" ]]; then
    log_info "   - Restoring standalone config files..."
    sudo -u "$username" rsync -a --exclude 'fstab.bak' "$backup_path/configs/" "$user_home/"
  fi
  if [[ -f "$backup_path/configs/fstab.bak" ]]; then
    log_warn "   - Old fstab kept at $backup_path/configs/fstab.bak, merge mounts into /etc/fstab manually."
  fi

  # 4. Restore Wakapi data (before install.sh starts wakapi.service)
  if [[ -n "$(ls -A "$backup_path/wakapi" 2>/dev/null)" ]]; then
    log_info "   - Restoring Wakapi data..."
    sudo -u "$username" mkdir -p "$user_home/.local/share/wakapi"
    sudo -u "$username" cp -rp "$backup_path/wakapi/." "$user_home/.local/share/wakapi/"
  fi

  # 5. Restore Flatpak app profiles
  local app_dir
  for app_dir in "$backup_path"/flatpak_data/*/; do
    [[ -d "$app_dir" ]] || continue
    log_info "   - Restoring Flatpak data for: $(basename "$app_dir")..."
    sudo -u "$username" mkdir -p "$user_home/.var/app"
    sudo -u "$username" cp -rp "${app_dir%/}" "$user_home/.var/app/"
  done

  # 6. Restore Dotfiles repo (only when it isn't already on disk)
  if [[ -d "$backup_path/dotfiles_backup/.dotfiles" ]]; then
    if [[ -d "$user_home/.dotfiles" ]]; then
      log_warn "   - $user_home/.dotfiles already exists, not restoring it from the backup."
    else
      log_info "   - Restoring .dotfiles folder..."
      sudo -u "$username" cp -rp "$backup_path/dotfiles_backup/.dotfiles" "$user_home/.dotfiles"
    fi
  fi
}

# --- 7. Configure System Services ---
configure_services() {
  local username="$1"
  log_info "Configuring system services..."

  systemctl daemon-reload
  systemctl enable --now docker

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
  install_manual_tools "$real_user"

  # Ask user for backup location to restore
  echo -e "\n============================================================="
  read -p "Would you like to restore data from a backup directory? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    read -p "Enter backup source path [/mnt/backup/fedora_migration_backup]: " backup_src
    backup_src="${backup_src:-/mnt/backup/fedora_migration_backup}"
    restore_backup "$real_user" "$backup_src" || true
  else
    log_info "Skipping data restore step."
  fi

  configure_services "$real_user"
  deploy_dotfiles "$real_user"

  echo -e "\n============================================================="
  log_info "System configuration completed!"
  log_warn "Please REBOOT your computer to apply all changes (including shell change & Nvidia drivers)."
  echo -e "============================================================="
}

main "$@"
