---
name: commit
description: Stage and commit changes using conventional commits. Use when the user asks to commit, create a commit, or says "commit".
argument-hint: "[optional message override]"
---

Create a git commit for the current changes in /Users/fotoflo/dev/habitcal.

## Steps

1. Run `git status` and `git diff` in parallel to understand what changed
2. Run `git log --oneline -5` to match the repo's commit message style
3. Stage only relevant changed files by name (never `git add -A` or `git add .`)
   - Skip `.claude/settings.local.json` and other non-code config unless explicitly changed as part of the task
4. Draft a commit message:
   - Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `style:`, `chore:`
   - One line summary focused on the *why*, not the *what*
   - If $ARGUMENTS is provided, use it as the commit message instead
5. Commit using a HEREDOC to preserve formatting:
   ```
   git commit -m "$(cat <<'EOF'
   <type>: <summary>

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```
6. Run `git status` to confirm success

## Rules

- NEVER use `--no-verify` or skip hooks
- NEVER amend — always create a new commit
- NEVER commit `.env`, secrets, or credential files
- NEVER force push
- Do NOT push unless the user explicitly asks
