#!/bin/bash
# =============================================================================
# Eget: install or update, then sync all configured GitHub tools
# =============================================================================
# Downloads the latest eget release into ~/.local/bin when it is newer
# than the installed one (the old binary is kept as .bak), then runs
# `eget -D` to install or upgrade all tools defined in ~/.config/eget/eget.toml.
# Also runs `ya pkg install` if yazi/package.toml exists.
#
# Usage: setup/tools/eget.sh [--no-sync]
# =============================================================================

set -e

source "$(dirname "$0")/../lib.sh"

REPO="zyedidia/eget"

# Prints the release target for this machine, or nothing if unsupported
eget_target() {
  local os arch
  case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    FreeBSD) os="freebsd" ;;
    OpenBSD) os="openbsd" ;;
    *) return ;;
  esac

  case "$(uname -m)" in
    x86_64 | amd64) arch="amd64" ;;
    aarch64 | arm64) arch="arm64" ;;
    armv7* | armv6* | arm) arch="arm" ;;
    i386 | i686) arch="386" ;;
    *) return ;;
  esac

  echo "${os}_${arch}"
}

# Prints the version of ~/.local/bin/eget, or nothing
eget_version() {
  [ -x "$LOCAL_BIN/eget" ] || return 0
  "$LOCAL_BIN/eget" --version | grep -oP 'eget version \K[0-9.]+' | head -1
}

install_eget() {
  local target tag latest current tmp
  target="$(eget_target)"
  if [ -z "$target" ]; then
    log_warn "No eget release for $(uname -s)-$(uname -m), skipping."
    return
  fi

  tag="$(gh_latest_tag "$REPO" || true)"
  if [ -z "$tag" ]; then
    log_warn "Could not fetch the latest eget release, keeping current one."
    return
  fi
  latest="${tag#v}"

  current="$(eget_version)"
  if [ "$current" = "$latest" ]; then
    log_info "eget $current is up to date."
    return
  fi

  log_info "Installing eget $latest (installed: ${current:-none})..."
  tmp="$(mktemp -d)"
  local asset="eget-${latest}-${target}.tar.gz"
  curl -fL --progress-bar "https://github.com/$REPO/releases/download/$tag/$asset" -o "$tmp/$asset"
  tar -xzf "$tmp/$asset" -C "$tmp"

  mkdir -p "$LOCAL_BIN"
  backup_file "$LOCAL_BIN/eget"
  install -m 755 "$tmp/eget-${latest}-${target}/eget" "$LOCAL_BIN/eget"
  rm -rf "$tmp"
  log_info "Installed eget $(eget_version)"
}

sync_tools() {
  if [ ! -x "$LOCAL_BIN/eget" ]; then
    log_warn "eget is not installed, skipping tool sync."
    return
  fi

  local config="$HOME/.config/eget/eget.toml"
  if [ ! -f "$config" ]; then
    log_warn "$config is missing (deploy dotfiles first), skipping eget download-all."
    return
  fi

  # Use GitHub token from gh CLI if available to avoid rate limiting
  if command -v gh >/dev/null 2>&1; then
    local token
    token="$(gh auth token 2>/dev/null || true)"
    if [ -n "$token" ]; then
      export EGET_GITHUB_TOKEN="$token"
    fi
  fi

  log_info "Syncing tools with eget (eget -D)..."
  "$LOCAL_BIN/eget" -D || log_warn "eget -D reported errors."

  # Install/update yazi plugins if yazi package.toml exists
  if command -v ya >/dev/null 2>&1 && [ -f "$HOME/.config/yazi/package.toml" ]; then
    log_info "Syncing yazi plugins (ya pkg install)..."
    ya pkg install >/dev/null 2>&1 || log_warn "ya pkg install failed."
  fi
}

main() {
  local sync=1
  case "${1:-}" in
    --no-sync) sync=0 ;;
    -h | --help)
      sed -n '/^# Usage:/s/^# //p' "$0"
      exit 0
      ;;
  esac

  install_eget
  if [ "$sync" = "1" ]; then
    sync_tools
  fi
}

main "$@"
