#!/bin/bash

set -e

# Source utility functions
source "$(dirname "$0")/utils.sh"

local_file="$DEST_DIR/nvim"
temp_file="$DEST_DIR/neovim"

# neovim/neovim/releases/latest
VERSION=$(get_release "neovim/neovim/releases/tags/stable" | jq .body -r | grep -oP 'NVIM \K[^\s]+')
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
  curl -L https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage -o "$temp_file"

  backup_file "$local_file"
  mv "$temp_file" "$local_file"
  chmod +x "$local_file"

  echo "Neovim updated."
fi
