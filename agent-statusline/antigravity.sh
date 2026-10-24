#!/bin/bash
# Antigravity CLI status line: state, mode, model, dir, branch, context tokens, usage remaining, session info, subagents, artifacts.
# Reads the session JSON on stdin; needs jq.
set -e

input=$(cat)
[ -z "$input" ] && exit 0

# shellcheck source=lib.sh
source "$(dirname "$(readlink -f "$0")")/lib.sh"

IFS=$'\x1f' read -r state mode model effort dir conv_title subagents_count artifacts queued ctx_pct ctx_size ctx_used cost < <(
  printf '%s' "$input" | jq -r '[
    (.agent_state // "idle"),
    (.mode // ""),
    (.model.display_name // .model.id // ""),
    (.model.effort // ""),
    (.workspace.current_dir // .cwd // ""),
    (.conversation_title // .conversation_name // ""),
    ([.subagents[]? | select(.status == "running")] | length | tostring),
    ((.artifacts // "") | tostring),
    ((.queued_messages // "") | tostring),
    ((.context_window.used_percentage // "") | tostring),
    ((.context_window.context_window_size // "") | tostring),
    ((.context_window.current_usage // .context_window.total_input_tokens // "") | tostring),
    ((.cost.total_cost_usd // .usage.cost // "") | tostring)
  ] | join("\u001f")' 2>/dev/null
)

# State and mode first: they change most often
case "$state" in
  idle)      add_part "${green}● idle${rst}" ;;
  working)   add_part "${yellow}● working${rst}" ;;
  thinking)  add_part "${magenta}● thinking${rst}" ;;
  tool_use)  add_part "${cyan}● tool_use${rst}" ;;
  reviewing) add_part "${blue}● reviewing${rst}" ;;
  error)     add_part "${red}● error${rst}" ;;
  *)         add_part "$(seg_dim "$state")" ;;
esac
[ -n "$mode" ] && add_part "${bold}${yellow}[$mode]${rst}"

add_part "$(seg_model "$model" "$effort")"
add_part "$(seg_loc "$dir")"

# Context: prefer the reported used tokens, fall back to percentage x window size
add_part "$(seg_ctx "$ctx_pct" "$ctx_used" "$ctx_size")"
[ -z "$ctx_pct" ] && [ -n "$ctx_used" ] && add_part "$(seg_dim "ctx $(fmt_tok "$ctx_used")")"

# Usage remaining / Quota limits: 5h and 7d (matched to active model family)
while IFS=$'\x1f' read -r key pct amt reset_sec; do
  [ -z "$key" ] && continue
  lbl="$key"
  [ "$lbl" = "default" ] && lbl="rem"
  if [ -n "$pct" ]; then
    add_part "$(seg_limit "$lbl" "$pct" "$reset_sec")"
  elif [ -n "$amt" ]; then
    add_part "${green}${lbl} ${amt}${rst}"
  fi
done < <(
  printf '%s' "$input" | jq -r '
    (if ((.model.display_name // .model.id // "") | ascii_downcase | test("claude|gpt|o1|o3|sonnet|haiku|opus")) then "3p" else "gemini" end) as $pref |

    if .quota and (.quota | length > 0) then
      [
        (
          (.quota[$pref + "-5h"] // .quota["5h"] // .quota["five_hour"] // (if .quota | keys | any(startswith($pref)) | not then (.quota["3p-5h"] // .quota["gemini-5h"]) else null end)) as $b |
          if $b != null then
            [
              "5h",
              (if $b.remaining_fraction != null then (($b.remaining_fraction * 100) | round | tostring) else "" end),
              ($b.remaining_amount // "" | tostring),
              ($b.reset_in_seconds // "" | tostring)
            ]
          else empty end
        ),
        (
          (.quota[$pref + "-weekly"] // .quota["7d"] // .quota["seven_day"] // .quota["weekly"] // (if .quota | keys | any(startswith($pref)) | not then (.quota["3p-weekly"] // .quota["gemini-weekly"]) else null end)) as $b |
          if $b != null then
            [
              "7d",
              (if $b.remaining_fraction != null then (($b.remaining_fraction * 100) | round | tostring) else "" end),
              ($b.remaining_amount // "" | tostring),
              ($b.reset_in_seconds // "" | tostring)
            ]
          else empty end
        ),
        (
          if (.quota[$pref + "-5h"] == null and .quota["5h"] == null and .quota[$pref + "-weekly"] == null and .quota["7d"] == null and .quota["weekly"] == null) then
            .quota | to_entries[0] |
            [
              "rem",
              (if .value.remaining_fraction != null then ((.value.remaining_fraction * 100) | round | tostring) else "" end),
              (.value.remaining_amount // "" | tostring),
              (.value.reset_in_seconds // "" | tostring)
            ]
          else empty end
        )
      ][] | join("\u001f")
    elif .rate_limits and (.rate_limits | length > 0) then
      [
        (if .rate_limits.five_hour then ["5h", (100 - .rate_limits.five_hour.used_percentage | round | tostring), "", (if .rate_limits.five_hour.resets_at then (.rate_limits.five_hour.resets_at - (now | round) | tostring) else "" end)] else empty end),
        (if .rate_limits.seven_day then ["7d", (100 - .rate_limits.seven_day.used_percentage | round | tostring), "", (if .rate_limits.seven_day.resets_at then (.rate_limits.seven_day.resets_at - (now | round) | tostring) else "" end)] else empty end)
      ][] | join("\u001f")
    elif .remaining_credits != null then
      ["credits", "", (.remaining_credits | tostring), ""] | join("\u001f")
    else
      empty
    end
  ' 2>/dev/null
)

add_part "$(seg_cost "$cost")"

# Session title (omitted when empty, no fallback ID)
if [ -n "$conv_title" ]; then
  title="$conv_title"
  [ ${#title} -gt 35 ] && title="${title:0:33}…"
  add_part "${dim}session:${rst} ${title}"
fi

[ -n "$subagents_count" ] && [ "$subagents_count" -gt 0 ] && add_part "${cyan}🤖 $subagents_count${rst}"
[ -n "$artifacts" ] && [ "$artifacts" -gt 0 ] && add_part "${dim}📄 $artifacts${rst}"
[ -n "$queued" ] && [ "$queued" -gt 0 ] && add_part "${yellow}✉️ $queued${rst}"

print_parts
