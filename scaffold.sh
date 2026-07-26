#!/usr/bin/env bash
# scripts/scaffold.sh
# Run once, from the repo root, right after `flutter create .`
# Creates the full folder skeleton so every tool/session works within the
# same structure from day one. Creates empty .gitkeep files so empty
# folders are still tracked by git.

set -euo pipefail

dirs=(
  "lib/core/errors"
  "lib/core/utils"
  "lib/core/di"
  "lib/database"
  "lib/models"
  "lib/features/customers/models"
  "lib/features/customers/repositories/interfaces"
  "lib/features/customers/repositories/sqlite"
  "lib/features/customers/services"
  "lib/features/customers/providers"
  "lib/features/customers/screens"
  "lib/features/parts/models"
  "lib/features/parts/repositories/interfaces"
  "lib/features/parts/repositories/sqlite"
  "lib/features/parts/services"
  "lib/features/parts/providers"
  "lib/features/parts/screens"
  "lib/features/purchases/models"
  "lib/features/purchases/repositories/interfaces"
  "lib/features/purchases/repositories/sqlite"
  "lib/features/purchases/services"
  "lib/features/purchases/providers"
  "lib/features/purchases/screens"
  "lib/features/billing/models"
  "lib/features/billing/repositories/interfaces"
  "lib/features/billing/repositories/sqlite"
  "lib/features/billing/services"
  "lib/features/billing/providers"
  "lib/features/billing/screens"
  "lib/features/expenses/models"
  "lib/features/expenses/repositories/interfaces"
  "lib/features/expenses/repositories/sqlite"
  "lib/features/expenses/services"
  "lib/features/expenses/providers"
  "lib/features/expenses/screens"
  "lib/features/salaries/models"
  "lib/features/salaries/repositories/interfaces"
  "lib/features/salaries/repositories/sqlite"
  "lib/features/salaries/services"
  "lib/features/salaries/providers"
  "lib/features/salaries/screens"
  "lib/features/dashboard/services"
  "lib/features/dashboard/providers"
  "lib/features/dashboard/screens"
  "lib/features/reports/services"
  "lib/features/reports/screens"
  "lib/features/export/services"
  "lib/features/export/screens"
  "test/services"
  "test/repositories"
  "docs"
  "scripts"
)

for d in "${dirs[@]}"; do
  mkdir -p "$d"
  touch "$d/.gitkeep"
done

echo "Scaffold created. Next steps:"
echo "  1. Move AGENTS.md to the repo root."
echo "  2. Move build_plan.md, module_plan.md, design_doc.md, schema.sql into docs/"
echo "  3. Move check_architecture.sh into scripts/ and chmod +x it"
echo "  4. Add the architecture-check step to .woodpecker.yml"
echo "  5. Create one export file per feature, e.g. lib/features/customers/customers.dart"
