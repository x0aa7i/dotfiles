#!/bin/bash
# Run by dotter after every deploy: sync ai/mcp/servers.json into Claude Code, Codex and agy.
# Dotter runs a copy from .dotter/cache, so the repo is found from the working directory (its root).
bash ai/mcp/sync.sh || echo "ai/mcp/sync.sh failed." >&2
