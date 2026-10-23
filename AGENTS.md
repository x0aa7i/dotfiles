# Agent Guide - .dotfiles

This repository contains personal dotfiles managed with `dotter`. It includes configurations for Neovim, Fish shell, Tmux, WezTerm, Ghostty, Yazi, and more.

## Build, Lint, and Test Commands

### Deployment (Build)

On a fresh machine (Fedora or Termux), run the installer. It detects the environment, downloads
`dotter` into the repo root, writes `.dotter/local.toml` from the matching profile and deploys:

```bash
./install.sh                  # auto-detect (termux -> .dotter/termux.toml, fedora -> .dotter/fedora.toml)
./install.sh --profile fedora # force a profile
./install.sh --no-packages    # skip `pkg install` on Termux
```

`install.sh` is user-level and safe to re-run: dotter, deploy, starship, fish as login shell and the
systemd user units in `systemd/user/`. One-time Fedora provisioning (repos, RPMs, Flatpaks, drivers,
backup restore) lives in `setup/setup.sh`, which calls `install.sh` at the end. Package lists are in
`setup/packages/{fedora,flatpak,termux}.txt` (one per line, `#` comments).

SSH between the PC and the phone (Tailscale, shared `ssh/config.d/tailnet.conf`, `pair-phone`) and its manual steps
are documented in `ssh/README.md`. Never commit keys, `authorized_keys` or `known_hosts`.

To re-apply the dotfiles afterwards, use `dotter`:

```bash
# Deploy all dotfiles
./dotter deploy

# Deploy a specific section (e.g., nvim)
./dotter deploy --include nvim
```

_Note: `dotter` is downloaded using `utils/get_dotter`._

### Linting and Formatting

Strict adherence to formatting is required. Use the following tools:

- **Lua (Neovim/WezTerm/etc.)**:
  - Format: `stylua --config-path nvim/stylua.toml .`
  - Lint: Handled via Neovim LSP or manual check with `stylua --check`.
- **General (TS, JSON, MD, TOML, YAML)**:
  - Format: `dprint fmt --config nvim/rules/dprint.json`
  - Check: `dprint check --config nvim/rules/dprint.json`
- **JavaScript/TypeScript**:
  - Format/Check: `prettier --write .` or `prettier --check .` (Config: `nvim/rules/.prettierrc.json`)
- **Markdown**:
  - Lint: `markdownlint --config nvim/rules/.markdownlint.json`

---

## Code Style Guidelines

### General Principles

- **Indentation**: Use **2 spaces** for all file types unless otherwise specified by a local config.
- **Line Length**: Aim for **100-120 characters**.
- **Quotes**:
  - **JSON/JS/TS**: Use **double quotes**.
  - **Lua**: Use **double quotes** for strings unless the string contains double quotes.
  - **Shell**: Use **single quotes** for literal strings, **double quotes** for strings needing interpolation.

### Lua (Neovim & Plugins)

- **Style**: Follow `LazyVim` conventions and `stylua` rules.
- **Imports**: Use `local plugin = require("plugin_name")`. Avoid global variables.
- **Naming**:
  - Local variables/Functions: `snake_case`.
  - Plugin options/Modules: `snake_case` or `camelCase` depending on the plugin's schema.
- **File Structure**: Keep logic in `lua/` and use `init.lua` for entry points.
- **Error Handling**: Use `pcall` for risky operations (like requiring a plugin that might not exist).
  ```lua
  local ok, plugin = pcall(require, "plugin")
  if not ok then return end
  ```

### Fish Shell

- **Keywords**: Use `test` for conditionals (e.g., `if test -d $dir`).
- **Paths**: Use `fish_add_path` for adding directories to `$PATH`.
- **Variables**: Use `set -gx` for global exported variables.
- **Functions**: Define in `fish/functions/` with one function per file named `function_name.fish`.

### Shell Scripts (Bash)

- **Header**: Always include `#!/bin/bash` and `set -e` (exit on error).
- **Sourcing**: Use `source "$(dirname "$0")/utils.sh"` for shared utilities.
- **Filenames**: Use `snake_case` (e.g., `update_nvim.sh`).
- **Variables**: Use uppercase for globals (e.g., `DEST_DIR`), lowercase for locals.
- **Error Handling**: Explicitly check command success if `set -e` is insufficient.

### Configuration (YAML/TOML/JSON)

- **JSON**: Use 2-space indentation, no trailing commas.
- **TOML**: Used for `dotter` and `stylua`. Follow existing key-value alignment.
- **YAML**: Use 2-space indentation.

---

## Tools and Technologies

- **Neovim**: Custom config based on [LazyVim](https://www.lazyvim.org/). Core of the workflow.
- **Fish Shell**: Interactive shell with many custom functions and aliases.
- **Tmux**: Terminal multiplexer for session management.
- **Yazi**: Terminal file manager with custom Lua plugins.
- **Dotter**: Rust-based dotfile manager. Uses `.dotter/` for configuration.
- **WezTerm/Ghostty/Kitty**: Terminal emulators with specialized configs.
- **Starship**: Cross-shell prompt.

---

## Repository Structure

- `nvim/`: Extensive Neovim configuration.
  - `lua/config/`: Core settings, keymaps, autocmds.
  - `lua/plugins/`: Plugin-specific configurations.
  - `rules/`: Linting and formatting rules.
- `fish/`: Shell configs.
  - `functions/`: Autoloaded fish functions.
  - `conf.d/`: Initialization scripts.
- `wezterm/` / `ghostty/` / `kitty/`: Terminal configs.
- `opencode/`: OpenCode config and plugins.
- `scripts/`: Maintenance scripts (backups, updates).
- `yazi/`: Yazi config and plugins.
- `.dotter/`: Deployment definitions.

## Agent Instructions

1. **Always read existing configs**: Before modifying a tool's configuration, read the existing files to understand the specific DSL or configuration style used.
2. **Validate after edit**: After editing a config, run the associated lint/format command.
3. **Respect Dotter**: If adding new files, update `.dotter/global.toml` or `fedora.toml` to ensure the new files are tracked and symlinked correctly.
4. **Be cautious with Shell**: When writing shell scripts, favor readability and use the utility functions in `scripts/update/utils.sh`.
5. **Atomic Changes**: Keep changes focused and well-documented in commit messages.
6. **No Chitchat**: Be direct and professional in communication.
