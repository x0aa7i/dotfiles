#!/bin/bash
# =============================================================================
# Yazi: install or update, then install its plugins
# =============================================================================
# Downloads the latest yazi and ya release into ~/.local/bin when it is newer
# than the installed one (the old binaries are kept as .bak), then runs
# `ya pkg install` so the plugins and flavors in yazi/package.toml exist.
# Without them yazi fails at startup, since yazi/init.lua requires them.
#
# On Termux yazi comes from `pkg` (setup/packages/termux.txt), so only the
# plugins are installed there.
#
# Usage: setup/tools/yazi.sh [--no-plugins]
# =============================================================================

set -e

source "$(dirname "$0")/../lib.sh"

REPO="sxyazi/yazi"

# Prints the release asset name for this machine, or nothing if unsupported
yazi_target() {
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64) echo "yazi-x86_64-unknown-linux-gnu" ;;
    Linux-aarch64 | Linux-arm64) echo "yazi-aarch64-unknown-linux-gnu" ;;
    Darwin-arm64) echo "yazi-aarch64-apple-darwin" ;;
    Darwin-x86_64) echo "yazi-x86_64-apple-darwin" ;;
  esac
}

# Prints the version of ~/.local/bin/yazi, or nothing. Older releases print
# "Yazi 25.5.31 (...)", newer ones "Yazi" followed by a "Version: 26.9.1" line
yazi_version() {
  [ -x "$LOCAL_BIN/yazi" ] || return 0
  "$LOCAL_BIN/yazi" --version | grep -oP '^(Yazi|\s*Version:)\s+\K[0-9][^\s]*' | head -1
}

install_yazi() {
  local target latest current tmp
  target="$(yazi_target)"
  if [ -z "$target" ]; then
    log_warn "No yazi release for $(uname -s)-$(uname -m), skipping."
    return
  fi

  latest="$(gh_latest_tag "$REPO" || true)"
  if [ -z "$latest" ]; then
    log_warn "Could not fetch the latest yazi release, keeping the current one."
    return
  fi
  # Release tags are v-prefixed, `yazi --version` is not
  latest="${latest#v}"

  current="$(yazi_version)"
  if [ "$current" = "$latest" ]; then
    log_info "yazi $current is up to date."
    return
  fi

  log_info "Installing yazi $latest (installed: ${current:-none})..."
  tmp="$(mktemp -d)"
  curl -fL --progress-bar "https://github.com/$REPO/releases/download/v$latest/$target.zip" -o "$tmp/yazi.zip"
  unzip -q "$tmp/yazi.zip" -d "$tmp"

  mkdir -p "$LOCAL_BIN"
  local bin
  for bin in yazi ya; do
    backup_file "$LOCAL_BIN/$bin"
    install -m 755 "$tmp/$target/$bin" "$LOCAL_BIN/$bin"
  done
  rm -rf "$tmp"
  log_info "Installed yazi $(yazi_version)"
}

install_plugins() {
  if ! command -v ya >/dev/null; then
    log_warn "ya is not installed, skipping yazi plugins."
    return
  fi
  if [ ! -f "$HOME/.config/yazi/package.toml" ]; then
    log_warn "$HOME/.config/yazi/package.toml is missing (deploy the dotfiles first), skipping yazi plugins."
    return
  fi

  log_info "Installing yazi plugins and flavors (ya pkg install)..."
  ya pkg install >/dev/null || log_warn "ya pkg install failed."
}

main() {
  local plugins=1
  case "${1:-}" in
    --no-plugins) plugins=0 ;;
    -h | --help)
      sed -n '/^# Usage:/s/^# //p' "$0"
      exit 0
      ;;
  esac

  if [ "$(detect_env)" != "termux" ]; then
    install_yazi
  fi
  if [ "$plugins" = "1" ]; then
    install_plugins
  fi
}

main "$@"
