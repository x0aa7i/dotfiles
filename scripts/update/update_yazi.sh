#!/bin/bash

set -e

# Source utility functions
source "$(dirname "$0")/utils.sh"

local_file="$DEST_DIR/yazi"

VERSION=$(get_release "sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
echo "Yazi version found: ${VERSION}"

LOCAL_V="$($local_file --version | grep -oP 'Yazi \K[^\s]+')"
echo "Yazi local version: ${LOCAL_V}"

if [ "$VERSION" = "$LOCAL_V" ]; then
  echo ""
  echo "Yazi is up to date."
else
  echo "Updating..."
  curl -L https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip -o "$DEST_DIR/yazi.zip"

  backup_file "$DEST_DIR/ya"
  backup_file "$DEST_DIR/yazi"

  unzip "$DEST_DIR/yazi.zip" -d "$DEST_DIR"
  rm "$DEST_DIR/yazi.zip"

  mv "$DEST_DIR/yazi-x86_64-unknown-linux-gnu/ya" "$DEST_DIR/ya"
  mv "$DEST_DIR/yazi-x86_64-unknown-linux-gnu/yazi" "$DEST_DIR/yazi"

  chmod +x "$DEST_DIR/ya"
  chmod +x "$DEST_DIR/yazi"

  rm -rf "$DEST_DIR/yazi-x86_64-unknown-linux-gnu"

  echo "Yazi updated."
fi
