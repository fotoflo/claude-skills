Create or update an architecture doc in `docs/architecture/`.

## Input

The user will specify a topic (e.g. "cdn", "frontend", "api") or ask you to document a specific part of the codebase.

## Steps

1. **Check existing docs** — read `docs/architecture/` to see what already exists. Avoid duplicating content across docs.

2. **Read the relevant code** — thoroughly read the source files related to the topic. Don't guess or rely on memory. Document what the code actually does.

3. **Write or update the doc** — create `docs/architecture/{topic}.md` with:
   - A clear title and one-line overview
   - How it works (data flow, key functions, important patterns)
   - Configuration or env vars if relevant
   - Tables for structured data (endpoints, schemas, etc.)
   - Keep it concise — document architecture, not every line of code

4. **Update the CLAUDE.md index** — add or update the entry in the "Architecture Docs" section of `CLAUDE.md`:
   ```
   - [Topic](docs/architecture/topic.md) — one-line description
   ```

## Style

- Write for a developer who just joined the project
- Lead with "what" and "why", not "how to read the code"
- Use tables for structured data (endpoints, schemas, env vars)
- Keep each doc under 150 lines — split into separate docs if larger
- Don't repeat information that's in other architecture docs
