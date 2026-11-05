#!/bin/bash
# Registers the status line scripts with the agents that use them. dotter only deploys the
# scripts (see [agent-statusline.files] in .dotter/global.toml); the agents also need their
# settings to point at them. Those settings files are rewritten by the agents themselves, so
# they stay local and only the status line key is merged in.
#
# Safe to re-run. Called by the repo's install.sh after `dotter deploy`.
set -e

YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Sets .statusLine in a JSON settings file unless it is already set
# $1 agent name, $2 deployed script, $3 settings file, $4 command to store
set_json_statusline() {
  local agent="$1" script="$2" settings="$3" command="$4"

  # agent-statusline section not in this dotter profile
  if [ ! -e "$script" ]; then
    return
  fi

  if [ ! -s "$settings" ]; then
    echo '{}' >"$settings"
  fi

  local current
  if ! current="$(jq -r '.statusLine.command // empty' "$settings")"; then
    log_warn "$settings is not valid JSON, skipping the $agent status line."
    return
  fi

  if [ "$current" = "$command" ]; then
    return
  elif [ -n "$current" ]; then
    log_warn "$agent already uses a custom status line ($current), keeping it."
    return
  fi

  log_info "Setting the $agent status line..."
  local tmp
  tmp="$(mktemp "$settings.XXXXXX")"
  jq --arg cmd "$command" '.statusLine = {"type": "command", "command": $cmd}' "$settings" >"$tmp"
  chmod --reference="$settings" "$tmp" 2>/dev/null || true
  mv "$tmp" "$settings"
}

main() {
  if ! command -v jq >/dev/null; then
    log_warn "jq is not installed, skipping the agent status lines."
    return
  fi

  # shellcheck disable=SC2088 # the tilde is stored literally, Claude Code expands it
  set_json_statusline 'Claude Code' "$HOME/.claude/statusline.sh" "$HOME/.claude/settings.json" \
    '~/.claude/statusline.sh'
}

main "$@"
