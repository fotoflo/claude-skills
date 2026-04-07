---
name: lint-fix
description: Run pnpm lint and fix violations following project conventions (layer architecture, hook extraction, alias imports). Use when cleaning up lint errors or enforcing project patterns.
argument-hint: "[optional file or area to focus on]"
---

Run lint and fix violations to follow project conventions.

## What This Skill Does

1. Run `pnpm lint` to find violations
2. Read the flagged files to understand context
3. Fix violations following the patterns below
4. Re-run `pnpm lint` to confirm clean output

If $ARGUMENTS is provided, focus only on those files/areas.

## ESLint Enforces These Rules

The project's ESLint config catches violations automatically. Don't scan manually — just run lint:

| Rule | What It Catches |
|------|----------------|
| `max-lines` | Files > 300 lines |
| `no-restricted-imports` (useState) | `useState` in TSX files — move state to hooks |
| `no-restricted-imports` (relative) | Relative parent imports — use `@/` aliases |
| `no-restricted-syntax` (useEffect) | `useEffect` updating state in TSX — move to hooks |
| `no-restricted-syntax` (helpers) | Helper functions in TSX — move to `.ts` files |
| `@typescript-eslint/no-unused-vars` | Dead code |
| `@typescript-eslint/no-explicit-any` | Untyped code |

## How to Fix Violations

### File too long (> 300 lines)
Split into layers: Service → Hook → Component.

### useState in TSX
Extract state + logic into a custom hook in `lib/hooks/`:
```
// Before: CalendarForm.tsx
const [data, setData] = useState(null);

// After: lib/hooks/useCalendarForm.ts
export function useCalendarForm() { ... }
```

### useEffect updating state in TSX
Move the effect into the hook. TSX effects should only do UI work (focus, scroll, measure, animate).

### Helper functions in TSX
Move to a `.ts` file (colocated or in `lib/`). TSX files should only export React components, hooks, or Next.js conventions.

### Relative parent imports
Replace `../../lib/foo` with `@lib/foo`. Aliases: `@lib`, `@hooks`, `@services`, `@components`, `@types`, `@constants`.

### Direct fetch in components
Route through: Service (`lib/services/`) → SWR Hook (`lib/hooks/`) → Component.

## Layer Architecture

```
Component (TSX) — pure rendering, < 150 lines
    ↓ uses
Hook (lib/hooks/) — state + side effects, < 100 lines
    ↓ calls
Service (lib/services/) — pure HTTP/CRUD, < 80 lines
```

- **Components**: Never call fetch/fetchJson directly. Use hooks only.
- **SWR hooks**: Use services as fetchers. SWR cache is source of truth.
- **Management hooks**: Combine SWR + service mutations + cache updates.
- **Services**: Pure HTTP functions with CRUD verbs. Handle errors consistently.

## Execution Rules

- Run `pnpm lint` first — don't guess at violations
- Fix only what lint flags (don't refactor working code that passes lint)
- Do NOT run a dev server or build
- Do NOT commit unless the user asks
- Before refactoring calendar components: check `docs/patterns.md`

## Output

Return a summary:
- Files touched
- Violations fixed (by category)
- New hooks/services created
- Remaining warnings (if any)
