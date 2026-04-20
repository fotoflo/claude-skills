---
name: statusline-setup
description: "Install or update the Claude Code two-row statusline. Use when the user says \"setup statusline\", \"install statusline\", or \"update statusline\"."
argument-hint: "[install | update | uninstall]"
---

Install a two-row Claude Code statusline that shows project context and session stats.

## What it displays

```
Row 1: ~/dir (branch) [model] session-name
Row 2: ctx:39%  tok:75.9k  +2106/-144  │  5hr:17% reset 6am  7d:32% reset fri 2pm
Row 3: (CLI's built-in hint row appears automatically)
```

### Row 1 — Project context
- **Directory** (green) — shortened with ~ for home
- **Git branch** (cyan) — current branch or short SHA, with a red `●` when the tree is dirty
- **Model** (yellow) — opus, sonnet, haiku, etc.
- **Session name** (white) — if set via /rename

### Row 2 — Session stats, grouped by concern
- **Left group — session usage:**
  - `ctx:N%` — context window remaining (magenta)
  - `tok:Nk` — total tokens used, human-readable (cyan)
  - `+N/-N` — lines added/removed (green/red)
- **Right group — rate limits** (separated by dim │):
  - `5hr:N% reset Xam` — 5-hour window usage + reset time
  - `7d:N% reset day Xpm` — 7-day window usage + reset time

## Steps

### Install
1. Write the statusline script to `~/.claude/statusline-command.sh`
2. Update `~/.claude/settings.json` to set:
   ```json
   "statusLine": {
     "type": "command",
     "command": "sh ~/.claude/statusline-command.sh"
   }
   ```
3. Verify the script runs: `echo '{}' | sh ~/.claude/statusline-command.sh`

### Update
1. Overwrite `~/.claude/statusline-command.sh` with the latest version below
2. Verify: `echo '{}' | sh ~/.claude/statusline-command.sh`

### Uninstall
1. Remove the `statusLine` key from `~/.claude/settings.json`
2. Delete `~/.claude/statusline-command.sh`

## The script

Write this exact content to `~/.claude/statusline-command.sh`:

```sh
#!/bin/sh
# Claude Code status line
# Row 1: ~/dir (branch) [model] session-name
# Row 2: ctx:N% tok:Nk +N/-N  ║  5hr:N% reset Xam · 7d:N% reset day Xpm

input=$(cat)

# --- Helpers ---
col() { printf '\033[%sm%s\033[0m' "$1" "$2"; }
grn() { col 32 "$1"; }
cyn() { col 36 "$1"; }
ylw() { col 33 "$1"; }
wht() { col 97 "$1"; }
mag() { col 35 "$1"; }
red() { col 31 "$1"; }
dim() { col 90 "$1"; }

jv() { echo "$input" | jq -r "$1"; }

# Join parts with double-space separator
row=""
add() { row="${row:+$row  }$1"; }

# Format token count as human-readable
fmt_tok() {
  if [ "$1" -ge 1000000 ]; then
    awk "BEGIN{printf \"%.1fM\",$1/1000000}"
  elif [ "$1" -ge 1000 ]; then
    awk "BEGIN{printf \"%.1fk\",$1/1000}"
  else
    echo "$1"
  fi
}

# Color a percentage by remaining budget: high=green, low=red
pct_color() {
  _remaining=$(printf '%.0f' "$1")
  if [ "$_remaining" -ge 60 ]; then
    col 32 "$2"   # green
  elif [ "$_remaining" -ge 30 ]; then
    col 33 "$2"   # yellow
  else
    col 31 "$2"   # red
  fi
}

# Format rate limit: "LABEL:N% reset TIME" — shows REMAINING, colored
fmt_limit() {
  _label="$1" _used="$2" _at="$3" _datefmt="$4"
  [ -z "$_used" ] && return
  _remaining=$(printf '%.0f' "$(awk "BEGIN{print 100-$_used}")")
  _reset=""
  [ -n "$_at" ] && _reset=$(date -r "$_at" "+$_datefmt" 2>/dev/null | tr '[:upper:]' '[:lower:]')
  _colored_pct=$(pct_color "$_remaining" "${_remaining}%")
  if [ -n "$_reset" ]; then
    printf '%s:%b %s' "$_label" "$_colored_pct" "$(dim "reset $_reset")"
  else
    printf '%s:%b' "$_label" "$_colored_pct"
  fi
}

# --- Extract ---
raw_dir=$(jv '.workspace.current_dir // .cwd // empty')
short_dir=$(echo "$raw_dir" | sed "s|^$HOME|~|")

branch=""
dirty=""
if [ -n "$raw_dir" ] && git -C "$raw_dir" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$raw_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$raw_dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$(git -C "$raw_dir" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
    dirty=" $(red "●")"
  fi
fi

model_id=$(jv '.model.id // empty')
case "$model_id" in
  *opus*)   model="opus" ;;
  *sonnet*) model="sonnet" ;;
  *haiku*)  model="haiku" ;;
  *)        model=$(jv '.model.display_name // empty' | sed 's/Claude //' | tr '[:upper:]' '[:lower:]') ;;
esac

session=$(jv '.session_name // empty')
ctx=$(jv '.context_window.remaining_percentage // empty')
total_tok=$(( $(jv '.context_window.total_input_tokens // 0') + $(jv '.context_window.total_output_tokens // 0') ))
la=$(jv '.cost.total_lines_added // 0')
lr=$(jv '.cost.total_lines_removed // 0')

# --- Row 1: project context ---
row1="$(grn "$short_dir")"
[ -n "$branch" ]  && row1="$row1 $(cyn "(")$(cyn "$branch")$dirty$(cyn ")")"
[ -n "$model" ]   && row1="$row1 $(ylw "[$model]")"
[ -n "$session" ] && row1="$row1 $(wht "$session")"

# --- Row 2: session usage  ║  rate limits ---

# Group 1: session usage
[ -n "$ctx" ]                            && add "ctx:$(pct_color "$ctx" "${ctx}%")"
[ "$total_tok" -gt 0 ]                   && add "$(cyn "tok:$(fmt_tok $total_tok)")"
[ "$la" != "0" ] || [ "$lr" != "0" ]     && add "$(grn "+$la")/$(red "-$lr")"

# Separator between groups
usage="$row"
row=""

# Group 2: rate limits (same pattern, different time windows)
# Both show REMAINING — burning down from 100% to 0%
five=$(fmt_limit "5hr" "$(jv '.rate_limits.five_hour.used_percentage // empty')" \
  "$(jv '.rate_limits.five_hour.resets_at // empty')" "%-I%p")
seven=$(fmt_limit "7d" "$(jv '.rate_limits.seven_day.used_percentage // empty')" \
  "$(jv '.rate_limits.seven_day.resets_at // empty')" "%a %-I%p")

[ -n "$five" ]  && add "$five"
[ -n "$seven" ] && add "$seven"
limits="$row"

# Combine with visual separator
row2=""
if [ -n "$usage" ] && [ -n "$limits" ]; then
  row2="$usage  $(dim "│")  $limits"
elif [ -n "$usage" ]; then
  row2="$usage"
elif [ -n "$limits" ]; then
  row2="$limits"
fi

# --- Output ---
if [ -n "$row2" ]; then
  printf '%b\n%b\n' "$row1" "$row2"
else
  printf '%b\n' "$row1"
fi
```

## Requirements
- `jq` must be installed (used to parse the JSON input from Claude Code)
- `git` for branch detection
- POSIX sh compatible (works on macOS and Linux)

## Rules
- NEVER modify `settings.local.json` — only `settings.json`
- Preserve any existing settings when adding the statusLine key
- The script must be fast — it runs on every prompt render
