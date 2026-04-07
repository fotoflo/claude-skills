---
name: update-docs
description: Read recent code changes and create or update architecture documentation in docs/architecture/. Use when you want to document what changed after a coding session.
argument-hint: "[optional: feature area or filename to focus on]"
---

Update architecture documentation based on recent code changes.

## Steps

1. **Gather recent changes** — run these in parallel:
   - `git diff HEAD~5 --stat` to see which files changed recently
   - `git log --oneline -10` to understand recent commit messages
   - `ls docs/architecture/` to see existing architecture docs

2. **Identify affected areas** — based on the changed files, determine which feature areas were modified. If $ARGUMENTS is provided, focus only on that area.

3. **Read the changed code** — read the key files that were modified to understand the current state of the code (not just the diff).

4. **Check existing docs** — for each affected area, check if a doc already exists in `docs/architecture/`:
   - If yes, read it and update it to reflect the new state
   - If no, create a new doc following the pattern of existing ones

5. **Write/update the docs** — each architecture doc should include:
   - **Overview**: What this feature/area does
   - **Key files**: File paths and their roles
   - **Data flow**: How data moves through the system
   - **Important patterns**: Conventions, gotchas, or design decisions
   - Keep it concise and focused on what another developer needs to know

6. **Update CLAUDE.md** — if you created a new architecture doc, add it to the "Current architecture docs" list in CLAUDE.md.

## Rules

- Focus on documenting the CURRENT state, not the history of changes
- Keep docs concise — aim for quick reference, not exhaustive documentation
- Use relative file paths from the project root
- Don't document trivial changes (typo fixes, formatting, etc.)
- Match the style of existing docs in `docs/architecture/`
