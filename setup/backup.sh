#!/bin/bash
# =============================================================================
# Fedora Pre-Format Backup Script
# =============================================================================
# Run this script BEFORE formatting your drive. It gathers and backs up:
# - System configuration (fstab, etc.)
# - SSH and GPG keys
# - Application databases (Wakapi, etc.)
# - Home config files (Wakatime, Modal, etc.)
# - User installed packages (RPM & Flatpak lists)
# - Flatpak application data (Zen Browser, Obsidian, Anki, etc.)
# - Dotfiles repository state
# =============================================================================

set -euo pipefail

# --- Color Codes for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Check Backup Destination ---
DEFAULT_DEST="/mnt/backup/fedora_migration_backup"
read -p "Enter backup destination directory [$DEFAULT_DEST]: " DEST
DEST="${DEST:-$DEFAULT_DEST}"

if [[ ! -d "$(dirname "$DEST")" ]]; then
  log_err "Parent directory of '$DEST' does not exist."
  log_warn "Please ensure your backup drive is mounted."
  exit 1
fi

log_info "Creating backup directory structure at: $DEST"
mkdir -p "$DEST/configs"
mkdir -p "$DEST/ssh"
mkdir -p "$DEST/gnupg"
mkdir -p "$DEST/wakapi"
mkdir -p "$DEST/flatpak_data"
mkdir -p "$DEST/dotfiles_backup"

# --- 1. Export Installed Package Lists ---
log_info "1. Exporting installed package lists..."
if command -v flatpak &>/dev/null; then
  flatpak list --app --columns=application >"$DEST/flatpaks.txt"
  log_info "   - Flatpak list saved to flatpaks.txt"
else
  log_warn "   - flatpak command not found. Skipping flatpak list."
fi

if command -v dnf &>/dev/null; then
  # Filter out common base packages to get user-installed/modified list
  dnf repoquery --userinstalled --queryformat "%{name}" >"$DEST/user_installed_packages.txt"
  log_info "   - User-installed DNF package list saved to user_installed_packages.txt"
else
  log_warn "   - dnf command not found. Skipping package list."
fi

# --- 2. Copy System Configurations ---
log_info "2. Backing up system configuration files..."
if [[ -f "/etc/fstab" ]]; then
  cp "/etc/fstab" "$DEST/configs/fstab.bak"
  log_info "   - /etc/fstab backed up (critical for mount point UUIDs!)"
else
  log_warn "   - /etc/fstab not found!"
fi

# --- 3. Copy SSH and GPG Keys ---
log_info "3. Backing up security keys..."
if [[ -d "$HOME/.ssh" ]]; then
  cp -rp "$HOME/.ssh" "$DEST/ssh/"
  log_info "   - SSH keys backed up"
else
  log_warn "   - ~/.ssh directory not found"
fi

if [[ -d "$HOME/.gnupg" ]]; then
  # Use tar to preserve GPG permission requirements
  tar -czf "$DEST/gnupg/gnupg.tar.gz" -C "$HOME" .gnupg
  log_info "   - GPG keys archived to gnupg.tar.gz"
else
  log_warn "   - ~/.gnupg directory not found"
fi

# --- 4. Copy Wakapi Data ---
log_info "4. Backing up Wakapi data..."
WAKAPI_SHARE="$HOME/.local/share/wakapi"
if [[ -d "$WAKAPI_SHARE" ]]; then
  cp -rp "$WAKAPI_SHARE"/* "$DEST/wakapi/"
  log_info "   - Wakapi database and configurations backed up"
else
  log_warn "   - Wakapi share directory not found at $WAKAPI_SHARE"
fi

# --- 5. Copy Home Config Files ---
log_info "5. Backing up standalone home configurations..."
declare -a HOME_FILES=(
  ".npmrc"
  ".aicommit2"
  ".aicommits"
)

for file in "${HOME_FILES[@]}"; do
  if [[ -f "$HOME/$file" ]]; then
    cp "$HOME/$file" "$DEST/configs/$file"
    log_info "   - $file backed up"
  fi
done

# --- 6. Back up .dotfiles Folder (Safety Net) ---
log_info "6. Backing up dotfiles repository..."
if [[ -d "$HOME/.dotfiles" ]]; then
  # Copy dotfiles directory, preserving git history
  cp -rp "$HOME/.dotfiles" "$DEST/dotfiles_backup/"
  log_info "   - ~/.dotfiles backed up (includes uncommitted changes!)"
else
  log_warn "   - ~/.dotfiles folder not found"
fi

# --- 7. Copy Flatpak Application Data ---
log_info "7. Backing up key Flatpak application profiles..."
# We backup Zen Browser and Obsidian profiles as they contain cookies/settings/plugins.
# Note: Obsidian vault is stored elsewhere (mount), but its configuration is in Flatpak data.
declare -a FLATPAK_APPS=(
  "app.zen_browser.zen"
  "md.obsidian.Obsidian"
  "net.ankiweb.Anki"
  "com.github.johnfactotum.Foliate"
  "org.telegram.desktop"
)

for app in "${FLATPAK_APPS[@]}"; do
  if [[ -d "$HOME/.var/app/$app" ]]; then
    log_info "   - Backing up Flatpak data for: $app..."
    mkdir -p "$DEST/flatpak_data/$app"
    # Syncing config & data
    cp -rp "$HOME/.var/app/$app" "$DEST/flatpak_data/"
  else
    log_warn "   - Flatpak data directory not found for: $app"
  fi
done

# --- Summary & Final Instructions ---
echo -e "\n============================================================="
log_info "Backup complete!"
echo -e "============================================================="
echo -e "Your backup is located at: ${BLUE}$DEST${NC}"
echo -e "\n${YELLOW}Please verify that the following files exist in the backup folder before formatting:${NC}"
echo -e "1. ${BLUE}$DEST/ssh/${NC} (Check your private/public key pairs)"
echo -e "2. ${BLUE}$DEST/gnupg/gnupg.tar.gz${NC} (Check GPG keys)"
echo -e "3. ${BLUE}$DEST/wakapi/wakapi_db.db${NC} (Check your Wakapi SQLite database)"
echo -e "4. ${BLUE}$DEST/flatpak_data/app.zen_browser.zen${NC} (Check Zen Browser profile)"
echo -e "5. ${BLUE}$DEST/configs/fstab.bak${NC} (Keep UUIDs of your SSD/HDDs safe)"
echo -e "============================================================="
