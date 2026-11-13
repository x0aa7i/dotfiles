# AI agents

Config for the coding agents (Claude Code, Codex, Antigravity/agy, OpenCode). Deploy targets did not change when this
was grouped, only the sources moved.

| Path                 | Deployed to                                              | Dotter package     |
| -------------------- | -------------------------------------------------------- | ------------------ |
| `agents/`            | `~/.agents`, skills also in `~/.claude` and `~/.gemini`  | `ai`               |
| `claude/settings.json` | `~/.claude/settings.json`                              | `claude`           |
| `statusline/`        | `~/.claude/statusline.sh`, `~/.gemini/antigravity-cli/`  | `agent-statusline` |
| `mcp/`               | not deployed, synced into each agent by `mcp/sync.sh`   | (post-deploy hook) |

## MCP servers

`mcp/servers.json` maps a server name to `{command, args, env}`. `mcp/sync.sh` adds missing servers to Claude Code,
Codex and agy, and removes the ones deleted from the file (only those it added, tracked in
`~/.local/state/dotfiles/mcp-managed`). `.dotter/post_deploy.sh` runs it after every `./dotter deploy`. Changing the
args of an existing server is not applied: delete it, sync, then add it back.
