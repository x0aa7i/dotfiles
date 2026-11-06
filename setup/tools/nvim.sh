#!/bin/bash
# =============================================================================
# Neovim AppImage: install or update
# =============================================================================
# Downloads the Neovim AppImage for a channel into ~/.local/bin/nvim when its
# version differs from the installed one (the old binary is kept as .bak).
# Not run by install.sh: Neovim normally comes from dnf/pkg, use this to get a
# nightly or newer build in front of it on $PATH.
#
# Usage: setup/tools/nvim.sh [-n|--nightly] [-s|--stable] [-c|--channel CHANNEL]
# =============================================================================

set -e

source "$(dirname "$0")/../lib.sh"

usage() {
  sed -n '/^# Usage:/s/^# //p' "$0"
  echo
  echo "  -n, --nightly          Install or update to the nightly release (default)"
  echo "  -s, --stable           Install or update to the stable release"
  echo "  -c, --channel CHANNEL  Specify the channel directly ('nightly' or 'stable')"
  echo "  -h, --help             Show this help message"
}

main() {
  local channel="nightly"

  while [ $# -gt 0 ]; do
    case "$1" in
      -n | --nightly | nightly) channel="nightly" ;;
      -s | --stable | stable) channel="stable" ;;
      -c | --channel)
        if [ -z "${2:-}" ]; then
          log_err "--channel requires an argument (stable or nightly)."
          exit 1
        fi
        channel="$2"
        shift
        ;;
      --channel=*) channel="${1#*=}" ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        log_err "Unknown option '$1'"
        usage
        exit 1
        ;;
    esac
    shift
  done

  if [ "$channel" != "stable" ] && [ "$channel" != "nightly" ]; then
    log_err "Invalid channel '$channel'. Must be 'stable' or 'nightly'."
    exit 1
  fi

  local arch
  case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      log_err "No Neovim AppImage for $(uname -m)."
      exit 1
      ;;
  esac

  local nvim="$LOCAL_BIN/nvim" latest current
  latest="$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/tags/$channel" |
    jq -r .body | grep -oP 'NVIM \K[^\s]+' | head -1)"
  if [ -z "$latest" ]; then
    log_err "Failed to fetch the Neovim version for channel '$channel'."
    exit 1
  fi
  if [ -x "$nvim" ]; then
    current="$("$nvim" --version | grep -oP 'NVIM \K[^\s]+' || true)"
  fi

  if [ "$current" = "$latest" ]; then
    log_info "Neovim $current ($channel) is up to date."
    return
  fi

  log_info "Installing Neovim $latest ($channel, installed: ${current:-none})..."
  local tmp
  tmp="$(mktemp)"
  curl -fL --progress-bar \
    "https://github.com/neovim/neovim/releases/download/$channel/nvim-linux-$arch.appimage" -o "$tmp"

  mkdir -p "$LOCAL_BIN"
  backup_file "$nvim"
  install -m 755 "$tmp" "$nvim"
  rm -f "$tmp"
  log_info "Installed Neovim $latest ($channel)."
}

main "$@"
