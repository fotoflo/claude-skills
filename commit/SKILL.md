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
7. **Deploy preview to Vercel (regardless of branch)** — if the project is linked to Vercel (`.vercel/project.json` exists):
   - Run `vercel --yes` to trigger a preview deploy
   - Extract the deployment URL from output (line containing `.vercel.app`)
   - Check if a `preview.<apex>` domain is attached to the project:
     ```bash
     VERCEL_TOKEN=$(python3 -c "import json,os; print(json.load(open(os.path.expanduser('~/Library/Application Support/com.vercel.cli/auth.json'))).get('token',''))")
     PROJECT_ID=$(python3 -c "import json; print(json.load(open('.vercel/project.json')).get('projectId',''))")
     TEAM_ID=$(python3 -c "import json; print(json.load(open('.vercel/project.json')).get('orgId',''))")
     curl -s "https://api.vercel.com/v9/projects/${PROJECT_ID}/domains?teamId=${TEAM_ID}" \
       -H "Authorization: Bearer $VERCEL_TOKEN" | python3 -c "import sys,json; [print(d['name']) for d in json.load(sys.stdin)['domains'] if d['name'].startswith('preview.')]"
     ```
   - If a `preview.*` domain exists, alias the deploy to it via API:
     ```bash
     curl -s -X POST "https://api.vercel.com/v2/deployments/<DEPLOYMENT_ID>/aliases?teamId=${TEAM_ID}" \
       -H "Authorization: Bearer $VERCEL_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"alias":"<preview-domain>"}'
     ```
   - Report the final preview URL to the user
   - Do this for ALL branches (not just main) — every commit should push to preview
   - If deploy fails, report the error but don't block — the commit already succeeded

## Rules

- NEVER use `--no-verify` or skip hooks
- NEVER amend — always create a new commit
- NEVER commit `.env`, secrets, or credential files
- NEVER force push
- Do NOT push unless the user explicitly asks
