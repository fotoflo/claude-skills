# claude-skills

Reusable skills for [Claude Code](https://claude.ai/code). Drop these into `~/.claude/skills/` (or symlink them) and invoke with `/skill-name` in any project.

## Setup

```bash
git clone https://github.com/fotoflo/claude-skills.git ~/dev/claude-skills

# Symlink all skills into Claude Code's skill directory
for skill in ~/dev/claude-skills/*/; do
  name=$(basename "$skill")
  ln -sf "$skill" ~/.claude/skills/"$name"
done

# Install shared dependencies (whisper-cpp, ffmpeg)
brew bundle --file=~/dev/claude-skills/Brewfile
```

## Skills

| Skill | Description | Usage |
|-------|-------------|-------|
| **architecture** | Create or update architecture docs in `docs/architecture/` | `/architecture [topic]` |
| **build** | Build the app on a local M2 Mac Mini via SSH | `/build [platform] [profile]` |
| **commit** | Stage and commit with conventional commit messages | `/commit [message]` |
| **done** | Wrap up a session — update docs, lint, test, commit | `/done [message]` |
| **frontend-design** | Guide creation of distinctive, production-grade UIs | `/frontend-design` |
| **lint-fix** | Run lint and fix violations following project conventions | `/lint-fix [file or area]` |
| **transcribe** | Transcribe audio files to text using local whisper-cpp | `/transcribe <path> \| dl` |
| **update-docs** | Update architecture docs based on recent code changes | `/update-docs [area]` |
| **weekly** | Summarize the week's commits with highlights and stats | `/weekly [days]` |

## Skill details

### architecture
Reads relevant source code and generates architecture documentation with overview, data flow, key files, and design patterns. Keeps docs under 150 lines.

### build
SSHes to an M2 Mac Mini and runs EAS builds for Android/iOS. Polls for artifacts and reports timing, version, and build numbers.

### commit
Analyzes staged and unstaged changes, drafts a conventional commit message (feat/fix/chore), stages relevant files, and commits. Never amends or force-pushes.

### done
Multi-phase session wrap-up. Launches parallel agents for architecture docs, lint fixes, and tests, then commits everything with a productivity summary and ASCII art celebration.

### frontend-design
Guides creation of memorable, intentional interfaces with bold aesthetic direction — typography, color, motion, and spatial composition. Avoids generic AI-generated design patterns.

### lint-fix
Runs `pnpm lint`, identifies violations (file size, hook extraction, relative imports, unused code), fixes them following layer architecture conventions, and re-runs to confirm.

### transcribe
Converts audio files (opus, ogg, mp3, wav, m4a) to text using local whisper-cpp. Auto-detects language, sorts messages chronologically, and copies output to clipboard via `pbcopy`. Use `dl` to scan `~/Downloads/` for recent audio files. Run `transcribe/setup.sh` to install dependencies and download a whisper model.

### update-docs
Gathers recent git changes, identifies affected feature areas, reads modified code, and creates or updates architecture docs with overviews, key files, data flow, and patterns.

### weekly
Generates a weekly summary: commit count, line changes, highlights grouped by category (features, fixes, infra, docs), and draft email update bullets.

## Shared dependencies

The `Brewfile` installs CLI tools used across skills:

```
brew "whisper-cpp"   # transcribe
brew "ffmpeg"        # transcribe (audio conversion)
```

## License

MIT
