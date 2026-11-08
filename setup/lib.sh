#!/bin/bash
# =============================================================================
# Shared helpers for install.sh and the scripts in setup/
# =============================================================================
# Source it, don't run it:
#   source "$DOTFILES_DIR/setup/lib.sh"
#
# Sets DOTFILES_DIR (the repo root, wherever it is cloned) and PACKAGES_DIR.
# =============================================================================

# Variables are used by the scripts that source this file
# shellcheck disable=SC2034

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$DOTFILES_DIR/setup/packages"
LOCAL_BIN="$HOME/.local/bin"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Prints the packages listed in setup/packages/<name>.txt, skipping comments
read_packages() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$PACKAGES_DIR/$1.txt" | grep -v '^$'
}

# Prints one of: termux, fedora, linux, macos
detect_env() {
  if [ -n "$TERMUX_VERSION" ] || [[ "$PREFIX" == *com.termux* ]]; then
    echo "termux"
  elif [ "$(uname -s)" = "Darwin" ]; then
    echo "macos"
  elif [ -f /etc/os-release ] && grep -q '^ID=fedora' /etc/os-release; then
    echo "fedora"
  else
    echo "linux"
  fi
}

# Prints the latest release tag of a GitHub repo (owner/name), e.g. v26.9.1
gh_latest_tag() {
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$1/releases/latest" |
    grep -Po '"tag_name":\s*"\K[^"]+'
}

# Moves a file aside as <file>.bak, so a broken update can be rolled back by hand
backup_file() {
  if [ -e "$1" ]; then
    mv -f "$1" "$1.bak"
  fi
}

# Runs a command as the target user with access to their systemd user session
run_as_user() {
  local username="$1"
  shift
  if [[ $EUID -eq 0 ]]; then
    local uid
    uid="$(id -u "$username")"
    sudo -u "$username" -H env \
      XDG_RUNTIME_DIR="/run/user/$uid" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
      "$@"
  else
    "$@"
  fi
}

# Finds a migration backup directory across /run/media and /mnt mounts
find_default_backup() {
  local user="$1"
  local candidate

  for candidate in /run/media/"$user"/*/fedora_migration_backup; do
    if [[ -d "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  if [[ -d /mnt/backup/fedora_migration_backup ]]; then
    echo "/mnt/backup/fedora_migration_backup"
    return 0
  fi

  if [[ -d /mnt/media/fedora_migration_backup ]]; then
    echo "/mnt/media/fedora_migration_backup"
    return 0
  fi

  return 1
}
