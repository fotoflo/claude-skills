---
name: done-quick
description: Fast session wrap-up — write up what changed, verify only the files you touched, commit, and sign off with ASCII art. Use for "done quick", "quick done", "qdone", "wrap this up", or when /done's stats tables and subagent fan-out are more than the change deserves.
argument-hint: "[optional commit message]"
model: sonnet
---

Wrap up the session: record what changed and why, check what you touched,
commit it.

This is `/done` with the same written output and none of the theatre. It keeps
the architecture docs and the bug-fix write-up — those are the durable part,
the only artifacts anyone reads in three months. It drops the timing table, the
productivity stats, the file-size snapshot, the ASCII art, the goodbye banner,
and the five-subagent fan-out.

**Write the docs yourself, inline.** `/done` dispatches a subagent to work out
what changed by reading the diff. You already know — you made the change, and
you know the why, which is the half a fresh agent cannot recover and usually
replaces with generic prose. Writing it directly is faster AND better.

## 1. List the files YOU touched

From your own memory of this conversation — every file you edited, created, or
wrote. Then `git status --porcelain` to see the tree.

**These two lists will differ, and that is the point.** This checkout is often
shared by several concurrent sessions, so dirty files you do not recognize
belong to someone else. Never `git add -A`, never `git add .`, never `git
commit -a`. Stage by explicit path, only your own files.

Do NOT reconstruct the list from `HEAD~N` or a broad `git diff` — another
session may have committed in between, and you will sweep up their work.

## 2. Architecture docs — if behaviour changed

Skip this for a pure refactor, a typo, a rename, a version bump: `docs/` should
describe how the system behaves, and none of those change it.

Otherwise, for each area whose behaviour, contract or invariant moved:

1. `ls docs/architecture/` — is there already a doc for this area?
2. If yes, edit it so it describes the system as it is NOW. Delete what is no
   longer true; do not append a changelog entry.
3. If no, write one matching the shape of its neighbours: what the area does,
   the key files and their roles, how data moves, and the gotchas — the things
   that would bite the next person.
4. If the repo indexes its docs (deckcp lists every one in `CLAUDE.md` with a
   one-line hook), add or update that line too. An unindexed doc is unfindable.

Write the WHY. The code already shows the what.

## 3. Bug-fix write-up — if you fixed a bug

Skip for new features. Write one for anything that was broken and now is not,
especially anything that took real debugging.

`ls docs/bug-fixes/` for the next number, then
`docs/bug-fixes/NNN-short-slug.md`:

- **Date** and **Severity** (Critical / High / Medium / Low)
- **Symptom** — what the user actually saw, in their words if you have them
- **Root cause** — the real mechanism, with the offending snippet
- **Why it was hard to find** — only if it was; a wrong hypothesis you chased
  is worth more to the next reader than the right answer alone
- **The fix** — before/after, and why this fix rather than the other one
- **Key rule** — one line that prevents the whole class
- **Files involved**

If the same class has now bitten more than twice, say so and consider whether a
lint rule or a shared component should end it instead of a third write-up.

## 4. Verify, scoped to your files

```
bash <skill-dir>/verify.sh <your files>
```

ESLint on them, then `vitest related` — only the tests that actually import what
you changed. On deckcp that is ~4s, against 16s for a full lint and minutes for
the whole 367-file suite.

It refuses to run on a path that does not exist, because `vitest related` reports
"No test files found" and exits 0 for a bad path — a green that means nothing.

**Not covered:** `tsc` is project-wide and slow, so this skips it. A type error
in a file nothing imports will not be caught. Run `tsc --noEmit` yourself for a
dependency bump, a shared type change, or anything widely imported.

Run checks one at a time. Concurrent heavy checks swap-spiral this machine and
produce phantom failures.

## 5. Commit

Conventional commit, staging the docs alongside the code. First line is
`$ARGUMENTS` if given, otherwise write one.

The body says WHY, not what — the diff already carries the what. If a fix is
non-obvious, name the failure it prevents.

```
git add <explicit paths>
git commit -m "..."
```

## 6. Report — and confirm every metric with the user

What landed, what you wrote up, what you verified. If you skipped something —
tsc, a flaky test, a doc you judged unnecessary, a dirty file that was not
yours — say which and why. A wrap-up that hides a gap is worse than none.

**Every number you report must be one you actually measured this run, and you
must say what produced it.** Not "all tests pass" — "4,583 passed, 0 failed
(`vitest run`)". Not "lint is clean" — "0 errors, 12 pre-existing warnings
(`eslint` on the 27 changed files)". A number with no command behind it is a
guess wearing a uniform.

Three rules, in order of how badly they bite:

1. **Never state a metric you did not run.** If you did not run `tsc`, the
   report says "typecheck: not run", never "types are fine". An unmeasured
   claim that happens to be true still teaches the reader to trust the next
   one, which will not be.
2. **Never report a metric as proof of something it does not measure.** A green
   test run proves the tests passed, not that the feature works. A clean
   validator proves what the validator checks — read what that actually is
   before citing it. (Real case: a quality rulebook claimed its rules were
   "checked by check_slide"; the slide with seven bullets, banned filler
   vocabulary and three fabricated metrics scored 100/100. The claim was
   inherited, never tested.)
3. **Ask the user to confirm the metrics only they can see.** You cannot
   observe their screen, their session, or their intent. End the report with
   the short list of things you are ASSERTING but cannot verify, and ask
   directly:
   - "Does the page actually look right to you?" — you saw HTML, not pixels
   - "Did that fix the bug you hit?" — you saw a test pass, not their symptom
   - "Is this the whole session's work?" — you have your file list, not theirs
   - Session duration, prompt counts, whether a doc reads correctly to them

   Do not present those as findings. Present them as questions, and wait.

When a metric turns out wrong after the user corrects you, fix the claim in
one sentence and move on — but fix the SOURCE too, so the next run does not
repeat it.

## 7. Sign off with ASCII art

End with a small piece of ASCII art. This is the point of the step: it is an
unmistakable "this is finished" marker you can spot from across the room while
scrolling back, without reading a word.

Draw the thing the session was about — the screen you changed, the pipeline you
fixed, the shape of the bug — with a DONE banner. Six to twelve lines. Make it
recognisable rather than decorative; a generic banner tells the reader nothing
about which session they are looking at.

**Plain ASCII only** — `+ - | = * # / \`, letters, digits. No Unicode
box-drawing, block elements, braille or arrows: they misalign in the terminal
and the art collapses into noise.

```
  +--------------------------+
  |  BILLING   [Pro] [Team]  |
  |  card ok / hydration ok  |
  +--------------------------+
     ==  D O N E  ==
```

No goodbye banner, no celebration block, no markers. The art IS the sign-off.

## Rules

- NEVER `--no-verify`, `--amend`, or force push
- NEVER commit `.env`, secrets, or credentials
- NEVER stage another session's files
- Do NOT push unless the user asks
- If verification fails and you cannot fix it quickly, commit nothing and say so
- NEVER report a number you did not measure this run; name the command behind it
- ALWAYS ask the user to confirm what only they can see — the screen, the
  symptom, the intent. Assert nothing on their behalf
