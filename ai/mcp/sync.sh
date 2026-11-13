#!/bin/bash
# =============================================================================
# MCP servers for Claude Code, Codex and Antigravity (agy)
# =============================================================================
# Registers the servers in ai/mcp/servers.json in every agent CLI that is installed. Safe to
# re-run: a server that already exists is left alone.
#
#   Claude Code  claude mcp add --scope user  (~/.claude.json)
#   Codex        codex mcp add                (~/.codex/config.toml)
#   agy          jq merge into ~/.gemini/config/mcp_config.json
#
# ai/mcp/servers.json maps a server name to {command, args, env}. Add a server there and re-run
# (also run by .dotter/post_deploy.sh). A server deleted from the file is removed from the agents too, but
# only if this script added it: the names it synced last time are kept in $STATE_FILE.
#
# Currently: awwwards (https://github.com/INSANE0777/Awwwards-mcp, needs Node >= 22.13; Playwright
# is optional, the capture/analyze tools need it).
#
# Usage: ai/mcp/sync.sh
# =============================================================================

set -e

source "$(dirname "$0")/../../setup/lib.sh"

AGY_MCP_CONFIG="$HOME/.gemini/config/mcp_config.json"
SERVERS_FILE="$DOTFILES_DIR/ai/mcp/servers.json"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/mcp-managed"

# add_server <name> <command> <args json array> <env json object>
add_server() {
  local name="$1" command="$2" args_json="$3" env_json="$4"
  local args=() env_flags=() line
  while IFS= read -r line; do args+=("$line"); done < <(jq -r '.[]' <<<"$args_json")
  while IFS= read -r line; do env_flags+=("$line"); done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' <<<"$env_json")

  if command -v claude >/dev/null 2>&1; then
    if claude mcp get "$name" >/dev/null 2>&1; then
      log_info "claude: $name already configured."
    else
      local claude_env=()
      for line in "${env_flags[@]}"; do claude_env+=(-e "$line"); done
      claude mcp add --scope user "$name" "${claude_env[@]}" -- "$command" "${args[@]}" >/dev/null &&
        log_info "claude: added $name."
    fi
  fi

  if command -v codex >/dev/null 2>&1; then
    if codex mcp get "$name" >/dev/null 2>&1; then
      log_info "codex: $name already configured."
    else
      local codex_env=()
      for line in "${env_flags[@]}"; do codex_env+=(--env "$line"); done
      codex mcp add "${codex_env[@]}" "$name" -- "$command" "${args[@]}" >/dev/null &&
        log_info "codex: added $name."
    fi
  fi

  if command -v agy >/dev/null 2>&1; then
    if [ -f "$AGY_MCP_CONFIG" ] && jq -e --arg n "$name" '.mcpServers[$n]' "$AGY_MCP_CONFIG" >/dev/null 2>&1; then
      log_info "agy: $name already configured."
    else
      mkdir -p "$(dirname "$AGY_MCP_CONFIG")"
      [ -f "$AGY_MCP_CONFIG" ] || echo '{}' >"$AGY_MCP_CONFIG"
      local tmp
      tmp="$(mktemp)"
      jq --arg n "$name" --arg c "$command" --argjson a "$args_json" --argjson e "$env_json" \
        '.mcpServers[$n] = ({command: $c, args: $a, disabled: false} + (if ($e | length) > 0 then {env: $e} else {} end))' \
        "$AGY_MCP_CONFIG" >"$tmp"
      mv "$tmp" "$AGY_MCP_CONFIG"
      log_info "agy: added $name."
    fi
  fi
}

# remove_server <name>
remove_server() {
  local name="$1"

  if command -v claude >/dev/null 2>&1 && claude mcp get "$name" >/dev/null 2>&1; then
    claude mcp remove --scope user "$name" >/dev/null && log_info "claude: removed $name."
  fi

  if command -v codex >/dev/null 2>&1 && codex mcp get "$name" >/dev/null 2>&1; then
    codex mcp remove "$name" >/dev/null && log_info "codex: removed $name."
  fi

  if command -v agy >/dev/null 2>&1 && [ -f "$AGY_MCP_CONFIG" ] &&
    jq -e --arg n "$name" '.mcpServers[$n]' "$AGY_MCP_CONFIG" >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp)"
    jq --arg n "$name" 'del(.mcpServers[$n])' "$AGY_MCP_CONFIG" >"$tmp"
    mv "$tmp" "$AGY_MCP_CONFIG"
    log_info "agy: removed $name."
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  log_err "jq is required to read $SERVERS_FILE."
  exit 1
fi

while IFS=$'\t' read -r name command args_json env_json; do
  add_server "$name" "$command" "$args_json" "$env_json"
done < <(jq -r 'to_entries[] | [.key, .value.command, (.value.args // [] | tojson), (.value.env // {} | tojson)] | @tsv' "$SERVERS_FILE")

# Servers synced last time that are no longer in the file
if [ -f "$STATE_FILE" ]; then
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    jq -e --arg n "$name" 'has($n)' "$SERVERS_FILE" >/dev/null || remove_server "$name"
  done <"$STATE_FILE"
fi

mkdir -p "$(dirname "$STATE_FILE")"
jq -r 'keys[]' "$SERVERS_FILE" >"$STATE_FILE"
