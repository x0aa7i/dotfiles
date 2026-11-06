#!/bin/bash
# Antigravity CLI status line: mode, model, dir, branch, context tokens, usage remaining, subagents, artifacts.
# Reads the session JSON on stdin; needs jq.
set -e

input=$(cat)
[ -z "$input" ] && exit 0

# shellcheck source=lib.sh
source "$(dirname "$(readlink -f "$0")")/lib.sh"

IFS=$'\x1f' read -r mode model effort dir subagents_count artifacts queued ctx_pct ctx_size ctx_used cost < <(
  printf '%s' "$input" | jq -r '[
    (.mode // ""),
    (.model.display_name // .model.id // ""),
    (.model.effort // ""),
    (.workspace.current_dir // .current_dir // .cwd // ""),
    ((.subagents_count // .total_subagent_count // ([.subagents[]? | select(.status == null or .status == "running")] | length)) | tostring),
    (if .artifact_count != null then (.artifact_count | tostring) elif (.artifacts | type) == "array" then (.artifacts | length | tostring) elif (.artifacts | type) == "number" then (.artifacts | tostring) else "" end),
    (if (.queued_messages | type) == "array" then (.queued_messages | length | tostring) elif (.queued_messages | type) == "number" then (.queued_messages | tostring) else "" end),
    (if .context_window.used_percentage != null then (.context_window.used_percentage | tostring) elif (.context_window.context_window_size != null and .context_window.context_window_size > 0 and (.context_window.current_usage != null or .context_window.total_input_tokens != null)) then (((.context_window.current_usage // .context_window.total_input_tokens) * 100 / .context_window.context_window_size) | round | tostring) else "" end),
    ((.context_window.context_window_size // .context_window.context_size // "") | tostring),
    ((.context_window.current_usage // .context_window.total_input_tokens // .context_window.input_tokens // "") | tostring),
    ((.cost.total_usd // .cost.total_cost_usd // .usage.cost // "") | tostring)
  ] | join("\u001f")' 2>/dev/null
)

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
              (if $b.remaining_fraction != null then (($b.remaining_fraction * 100) | round | tostring) elif $b.remaining_percentage != null then ($b.remaining_percentage | round | tostring) else "" end),
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
              (if $b.remaining_fraction != null then (($b.remaining_fraction * 100) | round | tostring) elif $b.remaining_percentage != null then ($b.remaining_percentage | round | tostring) else "" end),
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
              (if .value.remaining_fraction != null then ((.value.remaining_fraction * 100) | round | tostring) elif .value.remaining_percentage != null then (.value.remaining_percentage | round | tostring) else "" end),
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

[ -n "$subagents_count" ] && [ "$subagents_count" -gt 0 ] 2>/dev/null && add_part "${cyan}🤖 $subagents_count${rst}"
[ -n "$artifacts" ] && [ "$artifacts" -gt 0 ] 2>/dev/null && add_part "${dim}📄 $artifacts${rst}"
[ -n "$queued" ] && [ "$queued" -gt 0 ] 2>/dev/null && add_part "${yellow}✉️ $queued${rst}"

print_parts
