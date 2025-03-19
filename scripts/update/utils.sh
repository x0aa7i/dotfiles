#!/bin/bash

GITHUB_API="https://api.github.com/repos"
DEST_DIR="$HOME/.local/bin"

# Backup existing file
backup_file() {
  local file="$1"
  mkdir -p backups
  if [ -f "$file" ]; then
    mv "$file" "$file.bak"
  else
    echo "File $file does not exist, backup skipped."
  fi
}

# Fetch release info from GitHub API
get_release() {
  local path="$1"
  if [ -z "$path" ]; then
    echo "Error: repo path is required."
    return 1
  fi

  curl -L --silent \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$GITHUB_API/$path"
}
