---
name: git-productivity
description: Deep-dive productivity analysis of one or more git repos — contributors, hourly heatmaps, monthly activity, commit type breakdown, day-of-week patterns, and coding habit insights rendered as ASCII charts. Use when the user asks about git history, contributor stats, productivity, coding habits, or "who wrote what and when".
argument-hint: "[optional: path/to/repo or 'path1 path2' for multiple repos, defaults to current directory]"
---

Analyze the git history of one or more repositories and render the findings as ASCII charts with written insights.

## Setup

If $ARGUMENTS is provided, treat each space-separated value as a repo path. Otherwise use `.` (current directory).

For each repo path, verify it's a git repo:
```bash
git -C <path> rev-parse --git-dir 2>/dev/null || echo "NOT_A_REPO"
```

Skip any path that returns `NOT_A_REPO` and warn the user.

## Phase 1: Gather Raw Data (run all in parallel per repo)

For each repo, run these simultaneously:

**1. Contributors + commit counts:**
```bash
git -C <path> shortlog -sne --all
```

**2. Hourly distribution (all contributors combined):**
```bash
git -C <path> log --format="%ad" --date=format:"%H" | sort | uniq -c | sort -k2 -n
```

**3. Hourly distribution per top contributor (run for each):**
```bash
git -C <path> log --format="%an|%ad" --date=format:"%H" | grep "^<name>" | awk -F'|' '{print $2}' | sort | uniq -c | sort -k2 -n
```

**4. Monthly activity:**
```bash
git -C <path> log --format="%ad" --date=format:"%Y-%m" | sort | uniq -c | sort -k2
```

**5. Day-of-week distribution:**
```bash
git -C <path> log --format="%ad" --date=format:"%A" | sort | uniq -c | sort -rn
```

**6. Commit type breakdown** (conventional commits prefix):
```bash
git -C <path> log --format="%s" | grep -oE '^(feat|fix|refactor|chore|test|docs|style|Merge|merge|perf|build|ci|revert)' | sort | uniq -c | sort -rn
```

**7. First and last commit date per contributor:**
```bash
git -C <path> log --format="%an|%ad" --date=format:"%Y-%m-%d" | awk -F'|' '!seen[$1]++{last[$1]=$2} {first[$1]=$2} END{for(k in first) print k, "first:", first[k], "last:", last[k]}'
```

## Phase 2: Render ASCII Charts

For each repo, render all of the following charts. Scale bar lengths so the maximum value fills ~52 characters. Use `·` for zero values.

---

### Chart 1 — Commits by Contributor

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  <REPO NAME> — COMMITS BY CONTRIBUTOR                                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

  <Name>   <bar>  <N>
  ...
             0        <max>
```

---

### Chart 2 — Commits by Hour (24-hour, all contributors)

Show all 24 hours (00–23), using `·` for hours with zero commits. Add a one-line annotation below the chart describing the peak hour, dead zone, and any notable patterns.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  <REPO NAME> — COMMITS BY HOUR                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

  00  <bar>  <N>
  01  <bar>  <N>
  ...
  23  <bar>  <N>
      └────────────────────────────────────────────────┘
      <one-line pattern note>
```

---

### Chart 3 — Per-Contributor Hourly Comparison (top 2–3 contributors side by side)

Show the same 24-hour grid with each contributor's bars side by side. Scale each contributor independently so their individual peak fills ~20 chars. Add a one-line note about how their schedules differ.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  <REPO NAME> — HOURLY HEATMAP PER CONTRIBUTOR                               ║
╚══════════════════════════════════════════════════════════════════════════════╝

  Hr   <Contributor A>              <Contributor B>
  ──────────────────────────────────────────────────
  00   <bar>  <N>                   <bar>  <N>
  ...
  ──────────────────────────────────────────────────
  <insight line>
```

Skip this chart if the repo has only one contributor.

---

### Chart 4 — Monthly Activity Timeline

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  <REPO NAME> — MONTHLY ACTIVITY                                             ║
╚══════════════════════════════════════════════════════════════════════════════╝

  MMM 'YY  <bar>  <N>  [← annotation for notable months]
  ...
```

Annotate: first month ("project start"), biggest month ("🚀 peak"), any zero months ("paused"), most recent month ("ongoing").

---

### Chart 5 — Commits by Day of Week

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  <REPO NAME> — COMMITS BY DAY OF WEEK                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝

  Monday     <bar>  <N>
  Tuesday    <bar>  <N>
  ...
  Sunday     <bar>  <N>
```

---

### Chart 6 — Commit Type Breakdown

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  <REPO NAME> — COMMIT TYPE BREAKDOWN                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

  feat      <bar>  <N>
  fix       <bar>  <N>
  refactor  <bar>  <N>
  ...
             0        <max>
```

---

## Phase 3: Written Insights

After the charts for each repo, write a concise **Insights** section covering:

- **Peak coding window** — what hours are most productive, and what this suggests about the contributor's schedule
- **Night owl / early bird / 9-to-5** — classify each contributor's pattern with evidence
- **Busiest month** — what shipped and why it might have spiked (if inferable from commit messages)
- **Commit discipline** — are messages descriptive and conventional, or vague? Did quality improve over time?
- **Team dynamics** (multi-contributor repos) — who does what, how schedules overlap or diverge, any coverage gaps
- **Commit cadence** — burst coder vs. steady daily committer
- **Gaps / pauses** — any months with near-zero activity and what followed

Keep each bullet to 1–2 sentences. Be specific — cite actual numbers and hours.

---

## Phase 4: Cross-Repo Comparison (only if multiple repos provided)

If analyzing more than one repo, add a final section comparing them:

- Same contributor(s) across repos — do habits differ by project type?
- Which repo gets weekend attention vs. weekday focus?
- Commit message quality differences between repos
- Any hours that are active in one repo but dead in another

---

## Rules

- Always show all 24 hours in hourly charts — never group into blocks
- Scale bars so the max value fills exactly 52 `█` characters; everything else proportional
- Use `·` (not a space or dash) for zero-count hours/months
- Annotate charts with brief inline notes for notable data points
- Never fabricate data — if a command returns nothing for a contributor, skip them
- If only one contributor exists, skip the side-by-side comparison chart
- Keep written insights tight — no padding, no repetition of what the charts already show
