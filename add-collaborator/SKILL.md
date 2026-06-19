---
name: add-collaborator
description: Add a GitHub collaborator and wire CI-token deploys to Vercel so their pushes deploy without a paid Vercel seat. Use when the user says "add collaborator", "invite to repo", "let someone deploy", or onboards a training participant.
argument-hint: "<github_username> [allowed_directory]"
---

Add a collaborator to the current repo with push access, and make sure their pushes **actually deploy to Vercel** — even though they don't have (and shouldn't need) a paid Vercel team seat.

## The problem this solves

Vercel's Git integration authorizes each deployment by the **GitHub identity of the commit author**. When a commit is pushed by someone who isn't a member of your Vercel team, Vercel creates the deployment but **refuses to build it** ("the commit author is not a member of the team"). Adding them to the Vercel team costs a per-seat fee.

**The fix:** stop deploying off the Git author. Deploy from a GitHub Action using the *owner's* `VERCEL_TOKEN`. Vercel then attributes the deploy to that token, so anyone can push and it deploys — no seat required. The CI build step (`build`) also becomes a gate: a broken push fails CI and never reaches production.

This is the canonical pattern for AimHuge trainings, where participants push to a shared repo.

## Arguments

- `github_username` (required) — their GitHub username
- `allowed_directory` (optional) — restrict their PRs to this directory (e.g. `src/app/(decks)/`)

## Detect the repo and package manager first

Do not hardcode a repo name. Resolve it from the working tree:

```bash
gh repo view --json nameWithOwner -q .nameWithOwner   # e.g. fotoflo/aimhuge
```

Detect the package manager from the committed lockfile: `pnpm-lock.yaml` → pnpm, `package-lock.json` → npm, `yarn.lock` → yarn. The template below assumes **pnpm**; swap the install/build steps if the repo uses something else. If both `pnpm-lock.yaml` and `package-lock.json` exist, that ambiguity itself breaks Vercel builds — delete the stale one and `.gitignore` it.

## Steps

### 1. Invite to GitHub

```bash
gh api repos/<owner>/<repo>/collaborators/<username> -X PUT -f permission=push
```

Confirm the invitation was created.

### 2. Wire CI-token deploy (the core fix)

This only needs to be done **once per repo**. If `.github/workflows/deploy.yml` already exists and deploys via `VERCEL_TOKEN`, skip to step 3 — every future collaborator is covered automatically.

**a. Disable Vercel's Git auto-deploy** so you don't get double deploys or the author-authorization rejection. Either toggle it off in the Vercel dashboard (Project → Settings → Git → "Connected Git Repository" → disable production/preview deploys), or commit it as config in `vercel.json`:

```json
{ "git": { "deploymentEnabled": false } }
```

**b. Add the three repo secrets.** Get the IDs from `.vercel/project.json` (run `vercel link` first if it's missing):

```bash
node -e "const j=require('./.vercel/project.json');console.log('ORG_ID =',j.orgId);console.log('PROJECT_ID =',j.projectId)"
```

Tell the user to create a token at https://vercel.com/account/tokens (scoped to the right team), then add all three at `https://github.com/<owner>/<repo>/settings/secrets/actions`:

- `VERCEL_TOKEN` — the token (owner's; this is what bypasses per-seat auth)
- `VERCEL_ORG_ID` — from `.vercel/project.json`
- `VERCEL_PROJECT_ID` — from `.vercel/project.json`

You can set them via CLI if the user is signed into `gh`:

```bash
gh secret set VERCEL_ORG_ID -b "<orgId>" -R <owner>/<repo>
gh secret set VERCEL_PROJECT_ID -b "<projectId>" -R <owner>/<repo>
# VERCEL_TOKEN must be pasted by the user — never echo a token into shell history:
gh secret set VERCEL_TOKEN -R <owner>/<repo>   # prompts for the value
```

**c. Create `.github/workflows/deploy.yml`** (pnpm variant):

```yaml
name: Deploy to Vercel
on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, reopened]

concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
      VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
      PROD: ${{ github.ref == 'refs/heads/main' }}
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 24
          cache: pnpm

      - run: pnpm install --frozen-lockfile

      - name: Install Vercel CLI
        run: pnpm add -g vercel@latest

      - name: Pull Vercel env
        run: vercel pull --yes --environment=${{ env.PROD == 'true' && 'production' || 'preview' }} --token=${{ secrets.VERCEL_TOKEN }}

      - name: Build
        run: vercel build ${{ env.PROD == 'true' && '--prod' || '' }} --token=${{ secrets.VERCEL_TOKEN }}

      - name: Deploy
        id: deploy
        run: |
          URL=$(vercel deploy --prebuilt ${{ env.PROD == 'true' && '--prod' || '' }} --token=${{ secrets.VERCEL_TOKEN }})
          echo "url=$URL" >> "$GITHUB_OUTPUT"

      - name: Comment preview URL on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `Preview deployed: ${{ steps.deploy.outputs.url }}`,
            });
```

The `build` step is the gate — if it fails, no deploy happens. (For npm: `npm ci` + drop the pnpm steps and use `setup-node` with `cache: npm`.)

### 3. (Optional) Restrict the collaborator to a directory

If `allowed_directory` is provided, create `.github/workflows/restrict-<username>.yml`:

```yaml
name: Restrict <username> to <allowed_directory>
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  check-file-scope:
    if: github.event.pull_request.user.login == '<username>'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const files = await github.paginate(github.rest.pulls.listFiles, {
              owner: context.repo.owner, repo: context.repo.repo,
              pull_number: context.payload.pull_request.number,
            });
            const bad = files.map(f => f.filename).filter(f => !f.startsWith('<allowed_directory>'));
            if (bad.length) core.setFailed(`<username> can only modify <allowed_directory>.\n` + bad.map(f => '  - ' + f).join('\n'));
            else core.info('All changed files within allowed directory.');
```

Directory restriction only works if the collaborator goes through **PRs** (not direct pushes to main).

### 4. Commit and push

```
feat: add <username> as collaborator + CI-token Vercel deploy
```

## Checklist

- [ ] Repo + package manager detected (not hardcoded)
- [ ] GitHub invitation sent
- [ ] Vercel Git auto-deploy disabled (dashboard or vercel.json)
- [ ] `VERCEL_TOKEN` / `VERCEL_ORG_ID` / `VERCEL_PROJECT_ID` set as repo secrets
- [ ] `.github/workflows/deploy.yml` present and deploys via `VERCEL_TOKEN`
- [ ] Directory restriction workflow created (if requested)
- [ ] Committed and pushed; confirmed a test push deploys green
