if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Disable the startup message
set fish_greeting

starship init fish | source
zoxide init fish | source
fish_config theme choose tokyonight

fish_add_path ~/.local/bin

set -gx EDITOR nvim
set -gx fish_prompt_pwd_dir_length 0 # show the full path instead of the first letter of the directory
# nvm use v20.11.1 --silent

# pnpm
set -gx PNPM_HOME "/home/abdo/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# Aliases
# alias nvim="~/.local/bin/nvim"

if command -v exa >/dev/null
    alias ls="exa --all --icons --group-directories-first --color=always"
    alias ll="exa --long --no-user --all --icons --group-directories-first --color=always"
    alias tree="exa --tree --all --icons --group-directories-first --color=always"
end

alias v="$EDITOR"
alias y="yazi"

alias pnpx="pnpm dlx"
alias dev="pnpm run dev"

alias c="clear"
alias lg="lazygit"

#overrides
alias mkdir="mkdir -p"
alias cp="cp -r"
alias rm="safe-rm"

alias yanki="pnpm dlx yanki sync"

#abbreviations
abbr -a d sudo docker
abbr -a db sudo docker build
abbr -a dr sudo docker run
abbr -a dp sudo docker ps
abbr -a ds sudo docker stop

abbr -a dc sudo docker compose
abbr -a dcu sudo docker compose up
abbr -a dcr sudo docker compose restart
abbr -a dcd sudo docker compose down
abbr -a dcs sudo docker compose stop

# source env variables
if test -e ~/.config/.env
    envsource ~/.config/.env
end

# fzf settings
source ~/.config/fish/themes/tokyonight-fzf.sh

# fzf bindings - fzf_configure_bindings --help
fzf_configure_bindings --directory=\cf --variables=\e\cv

set -x FZF_COMPLETE 1
set -x FZF_LEGACY_KEYBINDINGS 0
set -x FZF_ENABLE_OPEN_PREVIEW 1
set -x FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS
  --cycle
  --layout=reverse
  --height 70%
  --color=bg:-1
  --preview-window=right:50%
  --bind=ctrl-u:half-page-up,ctrl-d:half-page-down,ctrl-x:jump
  --bind=ctrl-f:preview-page-down,ctrl-b:preview-page-up
  --bind=ctrl-a:beginning-of-line,ctrl-e:end-of-line
  --bind=ctrl-j:down,ctrl-k:up
"

# Shell wrapper that provides the ability to change the current working directory when exiting Yazi.
function yy
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# dprint
set -x DPRINT_INSTALL "/home/abdo/.dprint"
fish_add_path $DPRINT_INSTALL/bin
