#!/bin/bash

set -e

# Define variables
DEST_DIR="$HOME/.local/bin"

backup_file() {
  local file="$1"
  local backup="$file.bak"
  if [ -f "$file" ]; then
    mv "$file" "$backup"
  fi
}

download_file() {
  local url="$1"
  local dest_file="$2"
  echo "Downloading ${url}..."
  curl -L -o "$dest_file" "$url"
}

extract_file() {
  local file="$1"
  local dest_dir="$2"
  echo "Extracting ${file} to ${dest_dir}..."
  unzip "$file" -d "$dest_dir"
  rm "$file" # Optionally remove the zip file after extraction
}

make_executable() {
  local file="$1"
  echo "Making ${file} executable..."
  chmod +x "$file"
}

# Download Neovim
nvim_url="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage"
nvim_file="$DEST_DIR/nvim"

backup_file "$nvim_file"
download_file "$nvim_url" "$nvim_file"
make_executable "$nvim_file"

# Download yazi
yazi_url="https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
yazi_file="$DEST_DIR/yazi-x86_64-unknown-linux-gnu.zip"
yazi_dest="$DEST_DIR"
yazi_extracted_dir="$DEST_DIR/yazi-x86_64-unknown-linux-gnu"

download_file "$yazi_url" "$yazi_file"
extract_file "$yazi_file" "$yazi_dest"

backup_file "$DEST_DIR/ya"
backup_file "$DEST_DIR/yazi"

# Move 'ya' and 'yazi' to DIST_DIR and make them executable
mv "$yazi_extracted_dir/ya" "$DEST_DIR/ya"
mv "$yazi_extracted_dir/yazi" "$DEST_DIR/yazi"
make_executable "$DEST_DIR/ya"
make_executable "$DEST_DIR/yazi"

# Clean up the extracted directory
rm -rf "$yazi_extracted_dir"
