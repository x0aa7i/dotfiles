#!/bin/bash

set -e

# Source utility functions
source "$(dirname "$0")/utils.sh"

local_file="$DEST_DIR/nvim"
temp_file="$DEST_DIR/neovim"

CHANNEL="nightly"

usage() {
  echo "Usage: $(basename "$0") [options]"
  echo ""
  echo "Options:"
  echo "  -n, --nightly         Install or update to nightly release (default)"
  echo "  -s, --stable          Install or update to stable release"
  echo "  -c, --channel CHANNEL Specify channel directly ('nightly' or 'stable')"
  echo "  -h, --help            Show this help message"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--nightly|nightly)
      CHANNEL="nightly"
      shift
      ;;
    -s|--stable|stable)
      CHANNEL="stable"
      shift
      ;;
    -c|--channel)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --channel requires an argument (stable or nightly)." >&2
        usage
        exit 1
      fi
      CHANNEL="$2"
      shift 2
      ;;
    --channel=*)
      CHANNEL="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$CHANNEL" != "stable" && "$CHANNEL" != "nightly" ]]; then
  echo "Error: Invalid channel '$CHANNEL'. Must be 'stable' or 'nightly'." >&2
  exit 1
fi

echo "Neovim channel: ${CHANNEL}"

VERSION=$(get_release "neovim/neovim/releases/tags/${CHANNEL}" | jq .body -r | grep -oP 'NVIM \K[^\s]+')
if [ -z "$VERSION" ]; then
  echo "Error: Failed to fetch Neovim version for channel '${CHANNEL}'." >&2
  exit 1
fi
echo "Neovim version found: ${VERSION}"

LOCAL_V=""
if [ -x "$local_file" ]; then
  LOCAL_V=$($local_file --version | grep -oP 'NVIM \K[^\s]+')
fi
echo "Neovim local version: ${LOCAL_V:-not found}"

if [ "$VERSION" = "$LOCAL_V" ]; then
  echo ""
  echo "Neovim is up to date."
else
  echo "Updating..."
  curl -L "https://github.com/neovim/neovim/releases/download/${CHANNEL}/nvim-linux-x86_64.appimage" -o "$temp_file"

  backup_file "$local_file"
  mv "$temp_file" "$local_file"
  chmod +x "$local_file"

  echo "Neovim updated (${CHANNEL})."
fi
