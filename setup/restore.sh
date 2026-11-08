#!/bin/bash
# =============================================================================
# Fedora Migration Restore Script
# =============================================================================
# Restores data exported by setup/backup.sh:
# - home.tar.gz: SSH keys, Syncthing identity, configs, fonts, history
# - Crontab and /etc/fstab drive mounts (/mnt/backup, /mnt/media)
# - ~/dev from the drive copy with permissions and git executable bits fixed
#
# Can be run standalone or called by setup/fedora.sh:
#   ./setup/restore.sh                  # Interactive / auto-detect
#   ./setup/restore.sh /path/to/backup  # Explicit backup directory
#   sudo ./setup/restore.sh <user>      # As root targeting <user>
# =============================================================================

set -e

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SETUP_DIR")"
# shellcheck source=setup/lib.sh
source "$SETUP_DIR/lib.sh"

# Restores home files from home.tar.gz (SSH, Syncthing, fonts, configs)
restore_home_files() {
  local username="$1"
  local backup_path="$2"
  local user_home="$3"
  local tarball="$backup_path/home.tar.gz"

  if [[ ! -f "$tarball" ]]; then
    log_warn "   - $tarball not found, skipping home files."
    return 0
  fi

  log_info "   - Restoring home files from home.tar.gz..."

  # Stop syncthing if running so extracting configs doesn't conflict with memory state
  local syncthing_was_active=0
  if run_as_user "$username" systemctl --user is-active --quiet syncthing.service 2>/dev/null; then
    syncthing_was_active=1
    log_info "   - Temporarily stopping syncthing.service..."
    run_as_user "$username" systemctl --user stop syncthing.service 2>/dev/null || true
  fi

  if [[ $EUID -eq 0 ]]; then
    sudo -u "$username" tar -xzpf "$tarball" -C "$user_home"
  else
    tar -xzpf "$tarball" -C "$user_home"
  fi

  if [[ -d "$user_home/.ssh" ]]; then
    chmod 700 "$user_home/.ssh"
  fi

  if [[ $syncthing_was_active -eq 1 ]]; then
    log_info "   - Restarting syncthing.service..."
    run_as_user "$username" systemctl --user start syncthing.service 2>/dev/null || true
  fi

  run_as_user "$username" fc-cache -f >/dev/null 2>&1 || true
}

# Switches dotfiles git remote from https to ssh if ssh key is available
restore_dotfiles_remote() {
  local username="$1"
  local user_home="$2"
  local origin

  origin="$(run_as_user "$username" git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)"
  if [[ "$origin" == https://github.com/* && -f "$user_home/.ssh/id_ed25519" ]]; then
    log_info "   - Switching dotfiles remote to SSH..."
    run_as_user "$username" git -C "$DOTFILES_DIR" remote set-url origin "git@github.com:${origin#https://github.com/}"
  fi
}

# Appends old fstab /mnt/* entries whose disk UUID is attached
restore_mounts() {
  local old_fstab="$1"
  local device mountpoint rest dev_path added=0

  if [[ ! -f "$old_fstab" ]]; then
    return 0
  fi

  log_info "   - Checking drive mounts in fstab.bak..."
  while read -r device mountpoint rest; do
    [[ "$device" == \#* || "$mountpoint" != /mnt/* ]] && continue
    grep -qE "^[^#]*[[:space:]]$mountpoint[[:space:]]" /etc/fstab && continue

    dev_path="$device"
    [[ "$device" == UUID=* ]] && dev_path="/dev/disk/by-uuid/${device#UUID=}"
    if [[ ! -e "$dev_path" ]]; then
      log_warn "   - $device for $mountpoint is not attached, skipping."
      continue
    fi

    log_info "   - Adding $mountpoint to /etc/fstab..."
    if [[ $EUID -eq 0 ]]; then
      mkdir -p "$mountpoint"
      printf '%s %s %s\n' "$device" "$mountpoint" "$rest" >>/etc/fstab
    else
      sudo mkdir -p "$mountpoint"
      printf '%s %s %s\n' "$device" "$mountpoint" "$rest" | sudo tee -a /etc/fstab >/dev/null
    fi
    added=1
  done <"$old_fstab"

  if [[ "$added" == 1 ]]; then
    if [[ $EUID -eq 0 ]]; then
      systemctl daemon-reload
    else
      sudo systemctl daemon-reload
    fi
    log_warn "   - New mounts will be active on next mount or reboot."
  fi
}

# Restores user crontab if none exists
restore_crontab() {
  local username="$1"
  local crontab_file="$2"

  if [[ ! -s "$crontab_file" ]]; then
    return 0
  fi

  local has_crontab=0
  if [[ $EUID -eq 0 ]]; then
    crontab -u "$username" -l >/dev/null 2>&1 && has_crontab=1
  else
    crontab -l >/dev/null 2>&1 && has_crontab=1
  fi

  if [[ $has_crontab -eq 1 ]]; then
    log_info "   - User already has a crontab, skipping."
    return 0
  fi

  log_info "   - Restoring crontab..."
  if [[ $EUID -eq 0 ]]; then
    crontab -u "$username" "$crontab_file"
  else
    crontab "$crontab_file"
  fi
}

# Restores ~/dev from drive copy with permissions and executable bits from git index
restore_dev() {
  local username="$1"
  local src="$2"
  local user_home="$3"
  local dest="$user_home/dev"

  if [[ ! -d "$src" ]]; then
    log_warn "   - No ~/dev copy at $src, skipping."
    return 0
  fi

  if [[ -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
    log_warn "   - $dest is not empty, skipping ~/dev restore."
    return 0
  fi

  log_info "   - Restoring $dest from $src..."
  run_as_user "$username" rsync -rtp --chmod=D755,F644 "$src/" "$dest/"

  local git_dir repo entry
  while IFS= read -r -d '' git_dir; do
    repo="$(dirname "$git_dir")"
    run_as_user "$username" git -C "$repo" config core.filemode true
    while IFS= read -r -d '' entry; do
      if [[ "$entry" == 100755* ]]; then
        chmod +x "$repo/${entry#*$'\t'}" 2>/dev/null || true
      fi
    done < <(run_as_user "$username" git -C "$repo" ls-files -s -z)
    find "$git_dir/hooks" -type f ! -name '*.sample' -exec chmod +x {} + 2>/dev/null || true
  done < <(find "$dest" -name node_modules -prune -o -name .git -type d -print0 -prune)
}

main() {
  local target_user=""
  local backup_path=""

  # Determine target user and backup path from args
  if [[ $# -ge 1 ]] && id "$1" >/dev/null 2>&1; then
    target_user="$1"
    backup_path="${2:-}"
  elif [[ $# -ge 1 ]] && [[ -d "$1" ]]; then
    backup_path="$1"
    target_user="${SUDO_USER:-$(id -un)}"
  else
    target_user="${SUDO_USER:-$(id -un)}"
    backup_path="${1:-}"
  fi

  local user_home
  user_home="$(getent passwd "$target_user" | cut -d: -f6)"
  if [[ -z "$user_home" || ! -d "$user_home" ]]; then
    log_err "User home directory for '$target_user' not found."
    exit 1
  fi

  log_info "============================================================="
  log_info "Fedora Migration Restore"
  log_info "Target User: $target_user ($user_home)"
  log_info "============================================================="

  if [[ -z "$backup_path" ]]; then
    local detected
    detected="$(find_default_backup "$target_user" || true)"
    if [[ -t 0 ]]; then
      read -r -p "Enter backup directory path [${detected:-none}]: " input_path
      backup_path="${input_path:-$detected}"
    else
      backup_path="$detected"
    fi
  fi

  if [[ -z "$backup_path" || ! -d "$backup_path" ]]; then
    log_err "Backup directory '$backup_path' does not exist."
    log_warn "Please ensure your backup drive is mounted, or pass the path as an argument:"
    log_warn "  ./setup/restore.sh /path/to/fedora_migration_backup"
    exit 1
  fi

  log_info "Using backup at: $backup_path"

  restore_home_files "$target_user" "$backup_path" "$user_home"
  restore_dotfiles_remote "$target_user" "$user_home"
  restore_mounts "$backup_path/fstab.bak"
  restore_crontab "$target_user" "$backup_path/crontab.txt"
  restore_dev "$target_user" "$(dirname "$backup_path")/dev" "$user_home"

  if [[ -f "$backup_path/dconf.ini" ]]; then
    log_warn "   - Full GNOME settings saved at $backup_path/dconf.ini. Load more with: dconf load / < dconf.ini"
  fi

  log_info "============================================================="
  log_info "Restore completed successfully!"
  log_info "============================================================="
}

main "$@"
