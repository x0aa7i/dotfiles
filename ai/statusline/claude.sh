#!/bin/bash
# Claude Code status line. Reads the status JSON on stdin; needs jq.
set -e
# shellcheck source=lib.sh
source "$(dirname "$(readlink -f "$0")")/lib.sh"

input=$(cat)
j() { printf '%s' "$input" | jq -r "$1 // empty"; }

used_to_left() { [ -n "$1" ] && printf '%s' $(( 100 - ${1%.*} )); return 0; }

add_part "$(seg_model "$(j '.model.display_name')")"
add_part "$(seg_loc "$(j '.workspace.current_dir')")"
add_part "$(seg_ctx "$(j '.context_window.used_percentage')" "" "$(j '.context_window.context_window_size')")"
add_part "$(seg_limit 5h "$(used_to_left "$(j '.rate_limits.five_hour.used_percentage')")" "$(secs_until "$(j '.rate_limits.five_hour.resets_at')")")"
add_part "$(seg_limit 7d "$(used_to_left "$(j '.rate_limits.seven_day.used_percentage')")" "$(secs_until "$(j '.rate_limits.seven_day.resets_at')")")"

print_parts
