function lg --wraps=lazygit --description "Launch ziggity if terminal >= 50x15, otherwise lazygit"
    set -l cols $COLUMNS
    set -l lines $LINES

    test -n "$cols"; or set cols (tput cols 2>/dev/null; or echo 0)
    test -n "$lines"; or set lines (tput lines 2>/dev/null; or echo 0)

    if command -q ziggity; and test "$cols" -ge 50 -a "$lines" -ge 15
        ziggity $argv
    else if command -q lazygit
        lazygit $argv
    else
        echo "Neither ziggity nor lazygit found" >&2
        return 1
    end
end
