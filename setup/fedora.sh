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
# - Restoring backed-up data (SSH keys, home configs, /mnt drive mounts, crontab) and ~/dev
# - System services (Docker, Tailscale, cron, key-only sshd, user lingering)
# - GNOME workspace shortcuts and extensions (setup/packages/gnome-extensions.txt)
#
# Everything dotfiles-related (dotter, deploy, starship, fish as login shell,
# systemd user services, yazi) is delegated to ../install.sh, run as the
# target user.
#
# Usage: sudo setup/fedora.sh
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/lib.sh"

# Check if run as root for system-wide changes
check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_err "This script or section needs to be run with sudo/root privileges."
    exit 1
  fi
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
  # Single quotes: dnf expands $releasever itself
  if ! rpm -q terra-release >/dev/null 2>&1; then
    dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
  fi

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
  origin="$(sudo -u "$username" git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)"
  if [[ "$origin" == https://github.com/* && -f "$user_home/.ssh/id_ed25519" ]]; then
    log_info "   - Switching the dotfiles remote to SSH..."
    sudo -u "$username" git -C "$DOTFILES_DIR" remote set-url origin "git@github.com:${origin#https://github.com/}"
  fi

  # 3. Drive mounts under /mnt (scripts/rsync.sh needs /mnt/media and /mnt/backup)
  if [[ -f "$backup_path/fstab.bak" ]]; then
    restore_mounts "$backup_path/fstab.bak"
  fi

  # 4. Crontab (runs scripts/rsync.sh), unless the user already has one
  if [[ -s "$backup_path/crontab.txt" ]] && ! crontab -u "$username" -l >/dev/null 2>&1; then
    log_info "   - Restoring crontab..."
    crontab -u "$username" "$backup_path/crontab.txt"
  fi

  if [[ -f "$backup_path/dconf.ini" ]]; then
    log_warn "   - Full GNOME settings saved at $backup_path/dconf.ini, load more with: dconf load / < dconf.ini"
  fi
}

# Appends the old fstab's /mnt/* entries whose disk is still attached. They are not
# mounted now, since the backup is usually being read from one of those drives
restore_mounts() {
  local old_fstab="$1"
  local device mountpoint rest dev_path added=0

  while read -r device mountpoint rest; do
    [[ "$device" == \#* || "$mountpoint" != /mnt/* ]] && continue
    grep -qE "^[^#]*[[:space:]]$mountpoint[[:space:]]" /etc/fstab && continue

    dev_path="$device"
    [[ "$device" == UUID=* ]] && dev_path="/dev/disk/by-uuid/${device#UUID=}"
    if [[ ! -e "$dev_path" ]]; then
      log_warn "   - $device for $mountpoint is not attached, skipping it."
      continue
    fi

    log_info "   - Adding $mountpoint to /etc/fstab..."
    mkdir -p "$mountpoint"
    printf '%s %s %s\n' "$device" "$mountpoint" "$rest" >>/etc/fstab
    added=1
  done <"$old_fstab"

  if [[ "$added" == 1 ]]; then
    systemctl daemon-reload
    log_warn "   - New mounts are active after the reboot."
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

# --- 7b. GNOME: workspace shortcuts and extensions (Non-root user context) ---
# Super+N switches to workspace N and Super+Shift+N moves the window there, instead
# of launching the Nth dock app. Extensions are downloaded for the running GNOME
# version, enabled at the next login, and get their settings back from dconf.ini
configure_gnome() {
  local username="$1"
  local backup_path="$2"

  if ! command -v gnome-shell >/dev/null; then
    log_warn "GNOME Shell not found, skipping GNOME settings."
    return
  fi
  log_info "Configuring GNOME workspace shortcuts..."
  local i
  for i in {1..9}; do
    run_as_user "$username" gsettings set org.gnome.shell.keybindings "switch-to-application-$i" '[]'
    run_as_user "$username" gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Super>$i']"
    run_as_user "$username" gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$i" "['<Super><Shift>$i']"
  done

  log_info "Installing GNOME extensions from packages/gnome-extensions.txt..."
  local shell_version uuid url zip
  shell_version="$(gnome-shell --version | grep -oE '[0-9]+' | head -1)"
  zip="$(mktemp --suffix=.zip)"
  chmod 644 "$zip"
  local -a extensions
  mapfile -t extensions < <(read_packages gnome-extensions)

  for uuid in "${extensions[@]}"; do
    [[ -d "/usr/share/gnome-shell/extensions/$uuid" ]] && continue
    url="$(curl -fsS "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell_version" |
      jq -r '.download_url // empty' 2>/dev/null || true)"
    if [[ -z "$url" ]]; then
      log_warn "   - $uuid has no release for GNOME $shell_version, skipping it."
      continue
    fi
    log_info "   - $uuid"
    if ! curl -fsSL "https://extensions.gnome.org$url" -o "$zip" ||
      ! run_as_user "$username" gnome-extensions install --force "$zip"; then
      log_warn "   - Failed to install $uuid."
    fi
  done
  rm -f "$zip"

  # Replaces enabled-extensions, which GNOME reads at the next login
  local list
  list="$(printf '%s\n' "${extensions[@]}" | jq -Rnc '[inputs]' | tr '"' "'")"
  run_as_user "$username" gsettings set org.gnome.shell enabled-extensions "$list"
  run_as_user "$username" gsettings set org.gnome.shell disable-user-extensions false

  if [[ -f "$backup_path/dconf.ini" ]]; then
    log_info "   - Restoring extension settings from dconf.ini..."
    awk '/^\[/ { keep = ($0 ~ /^\[org\/gnome\/shell\/extensions\//) } keep' "$backup_path/dconf.ini" |
      run_as_user "$username" dconf load /
  fi
}

# --- 8. Deploy dotfiles (Non-root user context) ---
# install.sh owns dotter, deploy, starship, fish as login shell, user services and setup/tools/
deploy_dotfiles() {
  local username="$1"
  log_info "Running $DOTFILES_DIR/install.sh as $username..."
  run_as_user "$username" "$DOTFILES_DIR/install.sh" --profile fedora
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

  # Ask user for backup location to restore. On a fresh install the drive is
  # automounted under /run/media/<user>/, not at its old /mnt/media fstab path
  local backup_src="" default_src
  default_src="$(compgen -G "/run/media/$real_user/*/fedora_migration_backup" | head -1 || true)"
  default_src="${default_src:-/mnt/media/fedora_migration_backup}"
  echo -e "\n============================================================="
  read -p "Would you like to restore data from a backup directory? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    read -p "Enter backup source path [$default_src]: " backup_src
    backup_src="${backup_src:-$default_src}"
    restore_backup "$real_user" "$backup_src" || true
    # rsync.sh keeps ~/dev next to the backup folder, at <drive>/dev
    restore_dev "$real_user" "$(dirname "$backup_src")/dev"
  else
    log_info "Skipping data restore step."
  fi

  configure_services "$real_user"
  configure_gnome "$real_user" "$backup_src"
  deploy_dotfiles "$real_user"

  echo -e "\n============================================================="
  log_info "System configuration completed!"
  log_warn "Log in to Tailscale with 'sudo tailscale up', then pair the phone (ssh/README.md)."
  log_warn "Log in to the GitHub CLI with 'gh auth login' (its token was in the old keyring)."
  log_warn "Please REBOOT your computer to apply all changes (including the shell change)."
  echo -e "============================================================="
}

main "$@"
