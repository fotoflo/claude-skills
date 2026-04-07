---
name: weekly
description: Summarize this week's commits on main — highlights, stats, and draft update email bullets. Use when the user says "weekly", "this week on main", or "weekly summary".
argument-hint: "[optional: number of days back, default 7]"
---

Generate a weekly summary of what shipped on the main branch.

## Steps

### Phase 1: Gather Data

Run these commands in parallel:

1. `git log --oneline --since="$(date -v-${DAYS:-7}d +%Y-%m-%d)" main` — list of commits
2. `git log --since="$(date -v-${DAYS:-7}d +%Y-%m-%d)" --shortstat main | grep -E "files? changed" | awk '{ins+=$4; del+=$6} END {printf "+%d / -%d (net %+d)\n", ins, del, ins-del}'` — lines added/deleted
3. `git log --since="$(date -v-${DAYS:-7}d +%Y-%m-%d)" --format="%H" main | wc -l | tr -d ' '` — commit count
4. `git log --since="$(date -v-${DAYS:-7}d +%Y-%m-%d)" --format="%ai" main | head -1` and `... | tail -1` — date range

If $ARGUMENTS is a number, use it as the number of days to look back instead of 7.

### Phase 2: Categorize Commits

Group commits into these categories (skip any that have zero commits):

- **Features** — new user-facing functionality (`feat:`)
- **Fixes** — bug fixes (`fix:`)
- **Infrastructure** — migrations, tooling, CI, deps (`chore:`, `refactor:`)
- **Docs & Tests** — documentation, test coverage (`docs:`, `test:`)
- **Style** — UI polish, CSS, branding (`style:`)

### Phase 3: Generate Summary

Output in this format:

```
This week on main
═══════════════════════════════════════════════
<start date> → <end date>  •  <N> commits  •  +<ins> / -<del> lines
═══════════════════════════════════════════════

## Highlights
- <top 5-8 most notable shipped items, written as short punchy bullets>
- <focus on what shipped, not implementation details>
- <group related commits into single bullets>

## Stats
───────────────────────────────────────
Commits:        <N>
Lines changed:  +<ins> / -<del> (net <+/- net>)
Features:       <N>
Fixes:          <N>
Infra/Refactor: <N>
Docs/Tests:     <N>
───────────────────────────────────────

## Draft Update Email Bullets
<Rewrite the highlights as casual, friendly email bullets in the
style of a founder update — first person, conversational tone.
Include a blank section "- [life stuff]" at the end as a reminder
to add personal items.>
```

## Rules

- Focus on WHAT shipped, not HOW it was implemented
- Group related commits into single bullets (e.g., 5 print-related commits → 1 bullet about the print system)
- Keep highlight bullets concise — one line each
- The draft email bullets should sound human, not robotic
- Don't include merge commits or trivial housekeeping in highlights
- If a feature had multiple commits (initial + fixes), count it once
