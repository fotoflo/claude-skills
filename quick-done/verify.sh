#!/bin/bash
# verify.sh — scoped pre-commit verification for /quick-done.
#
# Checks ONLY the files you touched. On deckcp that is ~1s of ESLint instead of
# 16s, and seconds of Vitest instead of the full 367-file suite.
#
# Usage: verify.sh <file> [file ...]
#
# Exit codes: 0 = clean, 1 = lint failed, 2 = tests failed, 3 = bad input.

set -uo pipefail

if [ $# -eq 0 ]; then
  echo "usage: verify.sh <file> [file ...]" >&2
  exit 3
fi

# A path that does not exist makes `vitest related` print "No test files found"
# and exit 0 — a silent false green. Refuse to run on phantom paths instead.
MISSING=()
for f in "$@"; do [ -e "$f" ] || MISSING+=("$f"); done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "!! these paths do not exist, so verification would be meaningless:" >&2
  printf '   %s\n' "${MISSING[@]}" >&2
  echo "   (deleted? renamed? wrong cwd?) Fix the list and re-run." >&2
  exit 3
fi

# Lint only what ESLint can parse.
LINTABLE=()
for f in "$@"; do case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) LINTABLE+=("$f");; esac; done

RC=0

if [ ${#LINTABLE[@]} -gt 0 ]; then
  echo "=== lint (${#LINTABLE[@]} files) ==="
  if ! ./node_modules/.bin/eslint "${LINTABLE[@]}"; then RC=1; fi
else
  echo "=== lint: nothing lintable ==="
fi

# `vitest related` runs only the tests that actually import these files.
if [ ${#LINTABLE[@]} -gt 0 ]; then
  echo ""
  echo "=== tests related to your changes ==="
  if ! ./node_modules/.bin/vitest related --run --reporter=dot "${LINTABLE[@]}"; then
    [ $RC -eq 0 ] && RC=2
  fi
fi

echo ""
if [ $RC -eq 0 ]; then
  echo "=== clean — safe to commit ==="
else
  echo "=== NOT clean (rc=$RC) — fix before committing ==="
fi
exit $RC
