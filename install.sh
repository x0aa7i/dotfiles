#!/bin/bash
# =============================================================================
# Dotfiles installer
# =============================================================================
# Detects the environment (Termux, Fedora, generic Linux, macOS), downloads
# dotter into the repo root, selects the matching .dotter/<profile>.toml and
# deploys the dotfiles. Then sets up what the dotfiles need at user level:
# starship, fish as the login shell, the shipped systemd user services, an SSH
# key plus the shared ~/.ssh/config.d include, and sshd autostart on Termux.
#
# Runs as the normal user (no sudo). System provisioning for a fresh Fedora
# install lives in setup/setup.sh, which calls this script at the end.
#
# Usage: ./install.sh [--profile NAME] [--no-packages] [--no-deploy] [--force]
# =============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTTER_BIN="$DOTFILES_DIR/dotter"
DOTTER_URL="https://github.com/SuperCuber/dotter/releases/latest/download"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Lilex.tar.xz"
# Mono variant: Termux uses a fixed cell grid, so icons must be single-width
NERD_FONT_FILE="LilexNerdFontMono-Medium.ttf"

PACKAGES_DIR="$DOTFILES_DIR/setup/packages"

# User services enabled when their unit exists (besides the ones in systemd/user/)
USER_SERVICES=(syncthing.service espanso.service)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

usage() {
  sed -n '/^# Usage:/s/^# //p' "$0"
  echo
  echo "  --profile NAME  Use .dotter/NAME.toml instead of the detected profile"
  echo "  --no-packages   Skip pkg install on Termux (packages: setup/packages/termux.txt)"
  echo "  --no-deploy     Only install dotter and the local config"
  echo "  --force         Re-download dotter and overwrite .dotter/local.toml"
}

# Prints the packages listed in setup/packages/<name>.txt, skipping comments
read_packages() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$PACKAGES_DIR/$1.txt" | grep -v '^$'
}

# Prints one of: termux, fedora, linux, macos
detect_env() {
  if [ -n "$TERMUX_VERSION" ] || [[ "$PREFIX" == *com.termux* ]]; then
    echo "termux"
  elif [ "$(uname -s)" = "Darwin" ]; then
    echo "macos"
  elif [ -f /etc/os-release ] && grep -q '^ID=fedora' /etc/os-release; then
    echo "fedora"
  else
    echo "linux"
  fi
}

# Prints the dotter release asset for this machine, or nothing if unsupported
dotter_asset() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os-$arch" in
    Linux-x86_64) echo "dotter-linux-x64-musl" ;;
    Linux-aarch64 | Linux-arm64) echo "dotter-linux-arm64-musl" ;;
    Darwin-arm64) echo "dotter-macos-arm64.arm" ;;
  esac
}

dotter_works() {
  "$DOTTER_BIN" --version >/dev/null 2>&1
}

build_dotter() {
  if ! command -v cargo >/dev/null; then
    if [ "$ENV" = "termux" ]; then
      log_info "Installing rust to build dotter..."
      pkg install -y rust
    else
      log_err "cargo is not installed, cannot build dotter."
      exit 1
    fi
  fi

  log_info "Building dotter with cargo (this takes a few minutes)..."
  cargo install dotter --locked --root "$DOTFILES_DIR/.dotter/cargo"
  rm -f "$DOTTER_BIN"
  ln -s "$DOTFILES_DIR/.dotter/cargo/bin/dotter" "$DOTTER_BIN"
}

install_dotter() {
  if dotter_works && [ "$FORCE" != "1" ]; then
    log_info "dotter already present: $("$DOTTER_BIN" --version)"
    return
  fi

  local asset
  asset="$(dotter_asset)"

  # Termux execs binaries through Android's linker, which rejects the static
  # (non-PIE) release builds, so dotter has to be built from source there.
  if [ -n "$asset" ] && [ "$ENV" != "termux" ]; then
    log_info "Downloading $asset..."
    curl -fL --progress-bar "$DOTTER_URL/$asset" -o "$DOTTER_BIN"
    chmod +x "$DOTTER_BIN"
  fi

  if ! dotter_works; then
    build_dotter
  fi

  if ! dotter_works; then
    log_err "dotter is not runnable: $DOTTER_BIN"
    exit 1
  fi

  log_info "Installed $("$DOTTER_BIN" --version)"
}

install_termux_packages() {
  log_info "Installing Termux packages..."
  local -a packages
  mapfile -t packages < <(read_packages termux)
  pkg update -y
  pkg install -y "${packages[@]}"

  # Allow access to shared storage (~/storage)
  if [ ! -d "$HOME/storage" ] && command -v termux-setup-storage >/dev/null; then
    termux-setup-storage || log_warn "Storage permission not granted."
  fi
}

# Termux (and Termux:Styling) create these files themselves, which makes dotter skip them
backup_termux_defaults() {
  local file
  for file in "$HOME/.termux/termux.properties" "$HOME/.termux/colors.properties"; do
    if [ -f "$file" ] && [ ! -L "$file" ]; then
      log_warn "Moving existing $file to $file.bak"
      mv "$file" "$file.bak"
    fi
  done
}

install_termux_font() {
  local font="$HOME/.termux/font.ttf"
  local marker="$HOME/.termux/font.name"
  if [ -f "$font" ] && [ "$(cat "$marker" 2>/dev/null)" = "$NERD_FONT_FILE" ] && [ "$FORCE" != "1" ]; then
    return
  fi

  log_info "Installing $NERD_FONT_FILE..."
  local tmp
  tmp="$(mktemp -d)"
  if curl -fsSL "$NERD_FONT_URL" | tar -xJ -C "$tmp"; then
    mkdir -p "$HOME/.termux"
    cp "$tmp/$NERD_FONT_FILE" "$font"
    echo "$NERD_FONT_FILE" >"$marker"
  else
    log_warn "Font download failed, keeping the current font."
  fi
  rm -rf "$tmp"
}

install_starship() {
  if command -v starship >/dev/null; then
    return
  fi

  log_info "Installing starship to ~/.local/bin..."
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
}

set_default_shell() {
  local fish_path current
  fish_path="$(command -v fish || true)"
  if [ -z "$fish_path" ]; then
    log_warn "fish is not installed, keeping the current login shell."
    return
  fi

  # No getent on Termux/macOS, $SHELL reflects the login shell there
  if [ "$ENV" = "termux" ] || [ "$ENV" = "macos" ]; then
    current="$SHELL"
  else
    current="$(getent passwd "$(id -un)" | cut -d: -f7)"
  fi

  if [[ "$current" != *fish ]]; then
    log_info "Setting fish as the default shell..."
    chsh -s "$fish_path" || log_warn "chsh failed, run: chsh -s $fish_path"
  fi
}

# Enables the units shipped in systemd/user/ plus USER_SERVICES that are installed
enable_user_services() {
  if ! command -v systemctl >/dev/null || ! systemctl --user show-environment >/dev/null 2>&1; then
    log_warn "No systemd user session, skipping user services."
    return
  fi

  if command -v espanso >/dev/null && ! systemctl --user cat espanso.service >/dev/null 2>&1; then
    espanso service register || log_warn "espanso service register failed."
  fi

  local -a units=()
  local unit
  for unit in "$DOTFILES_DIR"/systemd/user/*.service; do
    [ -f "$unit" ] && units+=("$(basename "$unit")")
  done
  systemctl --user daemon-reload
  for unit in "${USER_SERVICES[@]}"; do
    systemctl --user cat "$unit" >/dev/null 2>&1 && units+=("$unit")
  done

  for unit in "${units[@]}"; do
    log_info "Enabling user service $unit..."
    systemctl --user enable --now "$unit" || log_warn "Failed to start $unit"
  done
}

# ~/.ssh must exist with strict permissions before dotter links into it
prepare_ssh_dirs() {
  mkdir -p "$HOME/.ssh/config.d" "$HOME/.ssh/sockets"
  chmod 700 "$HOME/.ssh" "$HOME/.ssh/sockets"
}

# Keeps ~/.ssh/config local (machine-specific, may be edited by tools like herdr)
# and makes it include the shared configs deployed to ~/.ssh/config.d/
setup_ssh_config() {
  local config="$HOME/.ssh/config"
  local include="Include config.d/*.conf"

  if [ -f "$config" ] && grep -qxF "$include" "$config"; then
    return
  fi

  log_info "Adding '$include' to ~/.ssh/config..."
  local tmp
  tmp="$(mktemp)"
  {
    echo "$include"
    [ -f "$config" ] && echo && cat "$config"
  } >"$tmp"
  mv "$tmp" "$config"
  chmod 600 "$config"
}

setup_ssh_key() {
  local key="$HOME/.ssh/id_ed25519"
  if [ -f "$key" ]; then
    return
  fi

  log_info "Generating SSH key $key..."
  if [ -t 0 ]; then
    ssh-keygen -t ed25519 -C "$(id -un)@$(uname -n)" -f "$key"
  else
    ssh-keygen -q -t ed25519 -N "" -C "$(id -un)@$(uname -n)" -f "$key"
  fi
  log_warn "New SSH key: authorize it on your other machines (see ssh/README.md)."
}

# Starts sshd now and on every Termux launch (termux-services)
enable_termux_sshd() {
  if ! command -v sshd >/dev/null; then
    log_warn "openssh is not installed, skipping sshd."
    return
  fi

  # Removes the service's "down" file; `sv up` itself fails until runsvdir runs
  # after the next Termux restart, which is fine
  if command -v sv-enable >/dev/null; then
    sv-enable sshd >/dev/null 2>&1 || true
  fi

  if ! pgrep -x sshd >/dev/null; then
    log_info "Starting sshd on port 8022..."
    sshd
  fi
}

# Writes .dotter/local.toml from the selected profile. A generated file is
# regenerated on every run so profile changes reach already-installed machines;
# a hand-written local.toml (no marker) is kept unless --force is passed
setup_local_config() {
  local profile="$1"
  local profile_file="$DOTFILES_DIR/.dotter/$profile.toml"
  local local_file="$DOTFILES_DIR/.dotter/local.toml"
  local marker="# Generated by install.sh from .dotter/$profile.toml, edit that file instead"

  if [ ! -f "$profile_file" ]; then
    log_err "Profile not found: .dotter/$profile.toml (use --profile)"
    exit 1
  fi

  if [ -f "$local_file" ] && [ "$FORCE" != "1" ] &&
    ! head -n1 "$local_file" | grep -q '^# Generated by install.sh' &&
    ! cmp -s "$local_file" "$profile_file"; then
    log_warn ".dotter/local.toml was not generated by install.sh, keeping it."
    log_warn "Delete it (or use --force) to follow .dotter/$profile.toml again."
    return
  fi

  {
    echo "$marker"
    cat "$profile_file"
  } >"$local_file"
  log_info "Using profile .dotter/$profile.toml"
}

main() {
  local profile=""
  local install_packages=1
  local deploy=1
  FORCE=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --profile)
        profile="$2"
        shift
        ;;
      --no-packages) install_packages=0 ;;
      --no-deploy) deploy=0 ;;
      --force) FORCE=1 ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        log_err "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done

  ENV="$(detect_env)"
  log_info "Detected environment: $ENV ($(uname -m))"

  if [ -z "$profile" ]; then
    case "$ENV" in
      termux | fedora) profile="$ENV" ;;
      *)
        log_err "No default profile for '$ENV'. Pass one with --profile."
        exit 1
        ;;
    esac
  fi

  if [ "$ENV" = "termux" ] && [ "$install_packages" = "1" ]; then
    install_termux_packages
  elif [ "$ENV" = "fedora" ]; then
    log_info "For system packages on Fedora, see setup/setup.sh"
  fi

  install_dotter
  setup_local_config "$profile"

  if [ "$deploy" = "1" ]; then
    [ "$ENV" = "termux" ] && backup_termux_defaults
    prepare_ssh_dirs
    log_info "Deploying dotfiles..."
    (cd "$DOTFILES_DIR" && "$DOTTER_BIN" deploy)
    setup_ssh_config
  fi

  if command -v ssh-keygen >/dev/null; then
    setup_ssh_key
  fi

  if [ "$ENV" = "termux" ]; then
    install_termux_font
    command -v termux-reload-settings >/dev/null && termux-reload-settings
    enable_termux_sshd
  else
    install_starship
    if [ "$ENV" != "macos" ] && [ "$deploy" = "1" ]; then
      enable_user_services
    fi
  fi

  set_default_shell

  log_info "Done."
}

main "$@"
