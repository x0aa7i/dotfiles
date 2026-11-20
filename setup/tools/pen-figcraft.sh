#!/bin/bash
# =============================================================================
# pen-figcraft: link the pen.dev <-> figcraft bridge into ~/.local/bin
# =============================================================================
# The bridge lives in its own repo (default ~/dev/tools/pen-figcraft, or
# $PEN_FIGCRAFT_DIR). Skips quietly when the repo isn't there, e.g. on Termux.
#
# Usage: setup/tools/pen-figcraft.sh
# =============================================================================

set -e

source "$(dirname "$0")/../lib.sh"

REPO_DIR="${PEN_FIGCRAFT_DIR:-$HOME/dev/tools/pen-figcraft}"
BIN_DIR="$HOME/.local/bin"

if [ ! -f "$REPO_DIR/pen-figcraft.mjs" ]; then
  log_info "pen-figcraft: no repo at $REPO_DIR, skipping."
  exit 0
fi

mkdir -p "$BIN_DIR"
ln -sfn "$REPO_DIR/pen-figcraft.mjs" "$BIN_DIR/pen-figcraft"
log_info "pen-figcraft: linked $BIN_DIR/pen-figcraft -> $REPO_DIR/pen-figcraft.mjs"
