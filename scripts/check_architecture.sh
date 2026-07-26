#!/usr/bin/env bash
# scripts/check_architecture.sh
#
# Enforces the layering rules from AGENTS.md mechanically, so they hold
# regardless of which tool or person wrote the code. Run in CI on every
# push — a violation here fails the build.

set -euo pipefail

FAIL=0

echo "== Checking architecture rules from AGENTS.md =="

# Rule: Screens/Widgets never import database/ or repositories/sqlite/ directly
if grep -rlE "import '.*database/|import '.*repositories/sqlite/" lib/screens lib/widgets 2>/dev/null; then
  echo "FAIL: found a Screen/Widget importing database/ or repositories/sqlite/ directly."
  echo "      UI must go through providers/ and services/ only."
  FAIL=1
fi

# Rule: Screens/Widgets never import Drift-generated classes directly
if grep -rlE "import '.*\.drift\.dart'|import 'package:drift" lib/screens lib/widgets 2>/dev/null; then
  echo "FAIL: found a Screen/Widget importing Drift directly."
  FAIL=1
fi

# Rule: Repository interfaces must not import Drift
if grep -rlE "import 'package:drift" lib/repositories/interfaces 2>/dev/null; then
  echo "FAIL: a repository interface imports Drift — interfaces must be storage-agnostic."
  FAIL=1
fi

# Rule: Services never contain raw SQL or Drift query builders
if grep -rlE "\.select\(|\.into\(|CustomTable|Value\(" lib/services 2>/dev/null; then
  echo "FAIL: a Service appears to contain a Drift query builder call directly."
  echo "      Query logic belongs in repositories/sqlite/, exposed via a named interface method."
  FAIL=1
fi

# Rule: no cross-feature reach into another feature's internals
# (only checks the common offenders: services/, repositories/, models/ subfolders
#  of a *different* feature than the importing file lives in)
for dir in lib/features/*/; do
  feature=$(basename "$dir")
  # find imports of other features' internal folders (not their single export file)
  if grep -rlP "import '.*features/(?!$feature/)[^/]+/(services|repositories|models)/" "$dir" 2>/dev/null; then
    echo "FAIL: a file in feature '$feature' reaches into another feature's internals."
    echo "      Cross-feature calls must go through the other feature's public export file."
    FAIL=1
  fi
done

if [ "$FAIL" -eq 1 ]; then
  echo ""
  echo "Architecture check failed. See AGENTS.md for the rules being enforced."
  exit 1
fi

echo "All architecture checks passed."
exit 0
