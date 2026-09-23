---
name: pa-onboard
description: PA onboarding — first-run setup for personal assistant capabilities. Captures schedule and preferences, then configures the daily routine that runs them. Use when the user says "set up my assistant", "interview me about my schedule", "onboard my PA", or their daily brief doesn't know enough about their life.
allowed-tools: AskUserQuestion, RemoteTrigger, Read, Write
---

# PA Onboarding

First-time setup for personal assistant capabilities, so the daily routine works
from day one.

*Adapted from [`pa-onboard`](https://github.com/yoda-digital/waywiser/tree/main/skills/pa-onboard)
in yoda-digital/waywiser. That version drives waywiser's own `memory`, `cronjob`
and `kanban` tools; this one drives Claude cloud routines and the memory directory.*

## Setup checklist

Run through this sequentially. Ask the user each question, then configure. Say
where you are ("2/7"). If they skip a question, use the sensible default and move
on — never press.

**Check what already exists before you create anything.** Run
`RemoteTrigger {action: "list"}` first. If a routine already covers a step, amend
it rather than adding a second one. Spent one-shots
(`ended_reason: "run_once_fired"`) are noise — count them, don't list them.

### 1. Working hours & timezone

Ask: "What timezone are you in, what are your working hours, and which days?"
Default: system timezone, Mon–Fri 09:00–18:00.

Actions:
- Save to the memory directory as a `user` memory: working hours, timezone, working days.
- Every routine cron is **UTC**. Convert and echo both back: "06:30 Asia/Bangkok =
  23:30 UTC, so `30 23 * * 0-4`."

### 2. Daily brief

Ask: "Want a brief each morning? What time?"
Default: yes, 08:00 on working days.

Actions:
- If a daily routine already exists, say so with its current time and skip to step 3.
- Otherwise create one with the `schedule` skill / `RemoteTrigger`. Minimum
  interval is one hour; the prompt must be wholly self-contained, because each run
  starts with zero context.

### 3. Weekly review

Ask: "Want a weekly review? Which day and time?"
Default: yes, Friday 16:00.

Actions: same as step 2, on a weekly cron.

### 4. Calendar source

Ask: "Which calendars should I read, and which one should I write to?"
Default: primary calendar for both.

Actions:
- Resolve ids with `list_calendars` and save them to memory.
- **Write to exactly one.** Reading many and writing one is the safe shape.
- Note the display timezone if it differs from the user's real one — a bare wall
  clock from the API will be off by the difference.

### 5. Recurring commitments

Ask: "What happens at the same time every week? School run, gym, classes, standing
calls — and how far away is each one?"
Default: none.

Actions:
- Distance is the question that matters: it turns one stated time into a correct
  block. 7 minutes away and a 15:40 pick-up is 15:33–15:50.
- Anything needing time either side — a drive, a shower, a changeover — is **part of
  the block**, not a separate event.
- Write these into the daily routine's instructions as explicit rules with times,
  days and offsets. Don't create the events by hand here; let the routine own them.

### 6. What does NOT go on the calendar

Ask: "Should the assistant put focus time, admin and breaks on your calendar, or
only real commitments?"
Default: **only real commitments.**

Actions: write the answer into the routine prompt as a negative rule **with its
reason attached**. A bare prohibition reads like an oversight and gets helpfully
reinvented; one with the failure attached reads like a decision:

> A previous version filled 07:00–21:00 with work blocks and breaks; the user hated
> it and deleted them all. Never create a block for focused work, admin, inbox,
> reading, breaks, buffers, meals or "planning".

### 7. Mark onboarding complete

Actions: write a `pa-onboarded` memory recording the date, the routines configured
with their times, the calendar ids, and the answer to step 6.

## Rules

- Never invite anyone to an event.
- Never modify or delete an existing event — only create.
- Never rewrite a routine prompt from scratch; amend the lines this interview
  earned. `job_config` is replaced wholesale on update, so send the full object you
  got from `get` with only the prompt text changed.
- You cannot delete routines. Send the user to https://claude.ai/code/routines.

## Example interaction

> **Claude:** I'm setting up your PA. Seven questions — skip any and I'll use a
> sensible default.
>
> **Claude:** 1/7 What timezone, working hours and days? (default: Mon–Fri 09:00–18:00)
> **User:** Bangkok, 8–6, Mon–Fri
>
> **Claude:** 2/7 Want a morning brief? You already have one — "Daily brief + real
> commitments", weekdays 06:30. Keep it as is?
> **User:** yes
>
> **Claude:** 5/7 What happens at the same time every week, and how far away?
> **User:** school run — drop 07:50, Lisl out 15:40, Dion 17:30 Tue/Thu, 7 min away
>
> **Claude:** So 🚗 Drop off 07:43–08:00, Pick up Lisl 15:33–15:50, Pick up Dion
> 17:23–17:40 Tue/Thu. Adding those to the routine's rules. Right?

## Step → tool

| Step | Tool | Action |
|---|---|---|
| 1–6 | `AskUserQuestion` | one question per step, with a default |
| 1, 7 | `Write` | memory files |
| 2, 3 | `RemoteTrigger` | `list` / `get` / `create` / `update` |
| 4 | calendar | `list_calendars` |
| 5, 6 | `RemoteTrigger` | `update` the routine prompt |

## Thinking level

`low` — this is a setup wizard, not complex analysis.
