#!/bin/bash
# =============================================================================
# Fedora Pre-Format Backup Script
# =============================================================================
# Run this script BEFORE formatting. It writes the same backup to every drive in
# MOUNTS (both must be mounted):
# - ~/dev and ~/.dotfiles, .env files included (scripts/rsync.sh)
# - home.tar.gz: SSH keys, gh config, Syncthing identity, fonts, fish history,
#   zoxide database and standalone home configs (.npmrc, .modal.toml, ...)
# - crontab, GNOME settings (dconf dump) and /etc/fstab
# - Package and tool inventories, to reinstall what setup.sh doesn't cover
#
# setup.sh restores it from <drive>/fedora_migration_backup and <drive>/dev.
# =============================================================================

set -euo pipefail

SETUP_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$SETUP_DIR")"
BACKUP_NAME="fedora_migration_backup"
MOUNTS=(/mnt/backup /mnt/media)

# Paths relative to $HOME, archived into home.tar.gz when they exist
HOME_PATHS=(
  .ssh
  .config/gh
  .local/state/syncthing
  .local/share/fonts
  .fonts
  .local/share/fish/fish_history
  .local/share/zoxide
  .npmrc
  .aicommit2
  .aicommits
  .modal.toml
  .opencommit
)

# Recreated automatically or deployed by dotter
HOME_EXCLUDES=(
  .ssh/sockets
  .ssh/config.d
  '.local/state/syncthing/index-*'
  .local/state/syncthing/syncthing.lock
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; }

# Runs a command into $INVENTORY/<file> when the command is installed
inventory() {
  local file="$1"
  shift
  command -v "$1" >/dev/null || return 0
  "$@" >"$INVENTORY/$file" 2>/dev/null || log_warn "   - '$*' failed"
}

check_mounts() {
  local mount
  for mount in "${MOUNTS[@]}"; do
    if ! mountpoint -q "$mount"; then
      log_err "$mount is not mounted. Mount every drive in MOUNTS, then run again."
      exit 1
    fi
  done
}

# ~/dev and ~/.dotfiles go straight to <drive>/dev and <drive>/dotfiles
sync_dev() {
  log_info "1. Syncing ~/dev and ~/.dotfiles (scripts/rsync.sh)..."
  "$DOTFILES_DIR/scripts/rsync.sh"
}

backup_home_files() {
  log_info "2. Archiving home files..."
  local -a paths=() excludes=()
  local path
  for path in "${HOME_PATHS[@]}"; do
    if [[ -e "$HOME/$path" ]]; then
      paths+=("$path")
    else
      log_warn "   - ~/$path not found"
    fi
  done
  for path in "${HOME_EXCLUDES[@]}"; do
    excludes+=(--exclude="$path")
  done

  # tar keeps the strict SSH permissions that NTFS/exFAT drives can't store
  tar -czf "$STAGE/home.tar.gz" -C "$HOME" "${excludes[@]}" "${paths[@]}"

  # Process substitution: with pipefail, grep -q exiting early would fail the pipe
  if ! grep -qx '.ssh/id_ed25519' < <(tar -tzf "$STAGE/home.tar.gz"); then
    log_err "~/.ssh/id_ed25519 is missing from home.tar.gz, aborting."
    exit 1
  fi
  log_info "   - home.tar.gz written ($(du -h "$STAGE/home.tar.gz" | cut -f1))"
}

backup_system_state() {
  log_info "3. Saving crontab, GNOME settings and fstab..."
  crontab -l >"$STAGE/crontab.txt" 2>/dev/null || log_warn "   - No crontab"
  if command -v dconf >/dev/null; then
    dconf dump / >"$STAGE/dconf.ini"
  fi
  cp /etc/fstab "$STAGE/fstab.bak"
}

backup_inventory() {
  log_info "4. Writing package and tool inventories..."
  INVENTORY="$STAGE/inventory"
  mkdir -p "$INVENTORY"
  inventory dnf.txt dnf repoquery --userinstalled --queryformat '%{name}\n'
  inventory flatpak.txt flatpak list --app --columns=application
  inventory local-bin.txt ls -l "$HOME/.local/bin"
  inventory cargo.txt cargo install --list
  inventory uv.txt uv tool list
  inventory npm.txt npm ls -g --depth=0
  inventory bun.txt bun pm ls -g
  inventory gnome-extensions.txt gnome-extensions list --enabled
}

# Writes the staged backup to every drive, replacing an older one
copy_to_drives() {
  log_info "5. Copying the backup to the drives..."
  local mount dest
  for mount in "${MOUNTS[@]}"; do
    dest="$mount/$BACKUP_NAME"
    rm -rf "$dest"
    mkdir -p "$dest"
    cp -r "$STAGE/." "$dest/"
    log_info "   - $dest"
  done
}

main() {
  check_mounts

  STAGE="$(mktemp -d)"
  trap 'rm -rf "$STAGE"' EXIT

  sync_dev
  backup_home_files
  backup_system_state
  backup_inventory
  copy_to_drives

  echo -e "\n============================================================="
  log_info "Backup complete!"
  echo -e "============================================================="
  local mount
  for mount in "${MOUNTS[@]}"; do
    echo -e "  ${BLUE}$mount/$BACKUP_NAME${NC}, ${BLUE}$mount/dev${NC}, ${BLUE}$mount/dotfiles${NC}"
  done
  echo -e "\n${YELLOW}Before formatting:${NC}"
  echo -e "  - Push or commit anything you want in git (repos without a remote only live in <drive>/dev)"
  echo -e "  - Keep /mnt/backup's partition (sdb4) out of the installer's partitioning: reformat / only"
  echo -e "============================================================="
}

main "$@"
