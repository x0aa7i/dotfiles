#!/bin/bash
# Shared helpers for the agent status lines (claude.sh, antigravity.sh).
# Source it; it only defines colours and functions. Every segment function prints nothing when
# its input is empty, so callers can append unconditionally with `add_part`.

dim=$'\e[2m'; rst=$'\e[0m'; bold=$'\e[1m'
blue=$'\e[34m'; green=$'\e[32m'; yellow=$'\e[33m'; red=$'\e[31m'; cyan=$'\e[36m'; magenta=$'\e[35m'

parts=()
add_part() { [ -n "$1" ] && parts+=("$1"); return 0; }

# 76000 -> 76k, 1250000 -> 1.2M
fmt_tok() {
  local n=${1%.*}
  [ -n "$n" ] && [ "$n" -gt 0 ] 2>/dev/null || return 0
  if [ "$n" -ge 1000000 ]; then
    printf '%d.%dM' $(( n / 1000000 )) $(( n % 1000000 / 100000 ))
  elif [ "$n" -ge 1000 ]; then
    printf '%dk' $(( n / 1000 ))
  else
    printf '%d' "$n"
  fi
}

# Seconds -> 3d 11h, 2h 30m, 45m
fmt_dur() {
  local s=${1%.*}
  [ -n "$s" ] && [ "$s" -gt 0 ] 2>/dev/null || return 0
  if [ "$s" -ge 86400 ]; then
    printf '%dd %dh' $(( s / 86400 )) $(( s % 86400 / 3600 ))
  elif [ "$s" -ge 3600 ]; then
    printf '%dh %dm' $(( s / 3600 )) $(( s % 3600 / 60 ))
  else
    printf '%dm' $(( s / 60 ))
  fi
}

# Epoch -> seconds left (empty when past or unset)
secs_until() {
  [ -n "$1" ] || return 0
  local left=$(( ${1%.*} - $(date +%s) ))
  [ "$left" -gt 0 ] && printf '%s' "$left"
  return 0
}

seg_model() { # name [effort]
  [ -n "$1" ] || return 0
  local out="${bold}${blue}$1${rst}"
  if [ -n "$2" ] && [[ "${1,,}" != *"$2"* ]]; then out="$out ${dim}($2)${rst}"; fi
  printf '%s' "$out"
}

seg_loc() { # dir
  [ -n "$1" ] || return 0
  local loc=${1##*/} branch
  [ "$1" = "$HOME" ] && loc="~"
  [ -z "$loc" ] && loc="/"
  branch=$(git -C "$1" branch --show-current 2>/dev/null || true)
  [ -n "$branch" ] && loc="$loc ${dim}${branch}${rst}"
  printf '%s' "$loc"
}

# Context fills up, so colour by used %: green < 60, yellow < 85, red above.
seg_ctx() { # used_pct [tokens] [window_size]
  [ -n "$1" ] || return 0
  local value=${1%.*} color=$green tokens=$2
  [ "$value" -ge 60 ] && color=$yellow
  [ "$value" -ge 85 ] && color=$red
  if [ -z "$tokens" ] && [ -n "$3" ]; then tokens=$(( value * ${3%.*} / 100 )); fi
  local tok; tok=$(fmt_tok "$tokens")
  printf '%sctx %s%%%s' "$color" "$value" "$rst"
  [ -n "$tok" ] && printf ' %s(%s)%s' "$dim" "$tok" "$rst"
  return 0
}

# Limits drain, so show what is left and colour by remaining %: green > 40, yellow > 15, red below.
seg_limit() { # label remaining_pct [seconds_until_reset]
  [ -n "$2" ] || return 0
  local value=${2%.*} color=$green dur
  [ "$value" -le 40 ] && color=$yellow
  [ "$value" -le 15 ] && color=$red
  printf '%s%s %s%%%s' "$color" "$1" "$value" "$rst"
  dur=$(fmt_dur "$3")
  [ -n "$dur" ] && printf ' %s%s%s' "$dim" "$dur" "$rst"
  return 0
}

seg_cost() { # usd
  [ -n "$1" ] || return 0
  printf '%s$%s%s' "$dim" "$(awk -v c="$1" 'BEGIN { printf "%.2f", c }')" "$rst"
}

seg_dim() { [ -n "$1" ] && printf '%s%s%s' "$dim" "$1" "$rst"; return 0; }

print_parts() {
  local sep=" ${dim}·${rst} " out="" p
  for p in "${parts[@]}"; do out="${out:+$out$sep}$p"; done
  printf '%s\n' "$out"
}
