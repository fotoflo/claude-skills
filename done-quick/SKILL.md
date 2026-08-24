---
name: quick-done
description: Fast session wrap-up — verify only the files you touched, then commit. Use for "quick done", "qdone", "wrap this up", or when /done is more ceremony than the change deserves.
argument-hint: "[optional commit message]"
model: sonnet
---

Wrap up the session in under a minute: check what you changed, commit it, stop.

This is `/done` minus the ceremony. It keeps the two things that actually
prevent bad commits — **scoped verification** and **explicit-path staging** —
and drops the architecture docs, bug-fix write-up, file-size snapshot,
productivity table, ASCII art and five parallel subagents.

Use `/done` instead when the session changed how the system WORKS and the docs
need to say so. Use this when the change speaks for itself.

## 1. List the files YOU touched

From your own memory of this conversation — every file you edited, created, or
wrote. Then `git status --porcelain` to see the tree.

**These two lists will differ, and that is the point.** This checkout is often
shared by several concurrent sessions, so dirty files you do not recognize
belong to someone else. Never `git add -A`, never `git add .`, never `git
commit -a`. Stage by explicit path, only your own files.

Do NOT reconstruct the list from `HEAD~N` or a broad `git diff` — another
session may have committed in between, and you will sweep up their work.

## 2. Verify, scoped to those files

```
bash <skill-dir>/verify.sh <your files>
```

Runs ESLint on them, then `vitest related` — only the tests that actually import
what you changed. On deckcp that is ~4s, against 16s for a full lint and minutes
for the whole 367-file suite.

It refuses to run on a path that does not exist, because `vitest related` reports
"No test files found" and exits 0 for a bad path — a green that means nothing.

Fix what it reports before continuing. If it is clean, say so plainly.

**Not covered, and worth saying out loud when it matters:** `tsc` is
project-wide and slow, so this skips it. A type error in a file nothing imports
will not be caught here. Run `tsc --noEmit` yourself for a dependency bump, a
shared type change, or anything touching a widely-imported module.

Run checks one at a time. Concurrent heavy checks swap-spiral this machine and
produce phantom failures.

## 3. Commit

Conventional commit. First line is `$ARGUMENTS` if given, otherwise write one.

The body should say WHY, not restate the diff — the diff is already in the
commit. If a fix is non-obvious, name the failure it prevents.

```
git add <explicit paths>
git commit -m "..."
```

## 4. Report in two lines

What landed, and what you verified. If you skipped something (tsc, a flaky
test, a file you left dirty because it was not yours), say which and why. A
wrap-up that hides a gap is worse than no wrap-up.

## Rules

- NEVER `--no-verify`, `--amend`, or force push
- NEVER commit `.env`, secrets, or credentials
- NEVER stage another session's files
- Do NOT push unless the user asks
- If verification fails and you cannot fix it quickly, commit nothing and say so
