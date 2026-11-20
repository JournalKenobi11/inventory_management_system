# Regression Testing Suite & Checklist

Before any fix is accepted into the codebase, the following test suites must be executed and confirmed passing:

## 1. Automated CI & Test Suites

### Automated CI Pipeline (GitHub Actions & Woodpecker)
- Configuration: `.github/workflows/ci.yml` and `.woodpecker.yml`
- Triggers: Push & Pull Request on `main`, `billing-export`, and feature branches.
- Automated Stages:
  1. **Architecture Enforcement:** Executes `scripts/check_architecture.sh` to mechanically verify layering rules from `AGENTS.md`.
  2. **Static Code Analysis:** Executes `flutter analyze --fatal-warnings`.
  3. **Test Suite & Coverage:** Executes `flutter test --coverage` (165 tests) and uploads coverage artifact.
  4. **Build Verification:** Executes `flutter build apk --debug` to verify successful compilation.

### Local Pre-Commit Hook Setup
To ensure no broken commits reach the repository, install the local git hook:
- **Windows:** Run `scripts\setup_git_hooks.bat`
- **Linux/macOS:** Run `bash scripts/setup_git_hooks.sh`

### Complete Manual Test Command
```bash
flutter test
flutter analyze
```

### Critical Component Tests
1. **Database & Migrations:**
   - `test/database/app_database_test.dart`
   - `test/database/personal_finance_migration_test.dart`
2. **Billing & Invoicing:**
   - `test/features/billing/billing_service_test.dart`
   - `test/features/billing/customer_billing_history_test.dart`
3. **Inventory & Purchases:**
   - `test/features/parts/part_service_test.dart`
   - `test/features/parts/part_repository_test.dart`
   - `test/features/purchases/purchase_service_test.dart`
   - `test/features/purchases/purchase_repository_test.dart`
   - `test/features/purchases/purchase_entry_screen_test.dart`
4. **Customers & Customer Details:**
   - `test/features/customers/customer_repository_test.dart`
   - `test/features/customers/customer_detail_screen_test.dart`
5. **Dashboard & Accounting:**
   - `test/features/dashboard/dashboard_service_test.dart`
   - `test/features/reports/report_service_test.dart`
5. **Staff, Attendance & Salaries:**
   - `test/salaries/salary_service_test.dart`
   - `test/salaries/attendance_service_test.dart`
   - `test/salaries/employee_repository_test.dart`
6. **Export, Backup & PDF:**
   - `test/features/export/backup_service_test.dart`
   - `test/features/export/fake_data_stress_test.dart`
   - `test/features/export/pdf_service_test.dart`
   - `test/features/export/whatsapp_share_test.dart`
7. **Responsive & Stress Layouts:**
   - `test/responsive_layout_test.dart`
   - `test/features/export/extreme_ui_layout_test.dart`
   - `test/widget_test.dart`

---

## 2. Manual Verification Scenarios

1. **Backup Roundtrip:** Export JSON -> Restore JSON -> Check that attendances and service reports remain intact.
2. **Bill Editing:** Open completed bill -> Edit parts -> Increase quantity -> Ensure warehouse stock is properly checked and adjusted.
3. **Restocking Dropdown:** Open Purchase Entry -> Select part -> Verify no dropdown assertion error occurs even when stock updates.
4. **Delete Customer:** Tap 3-dots on customer -> Tap Delete -> Verify confirmation dialog appears before deletion occurs.
5. **Customer Detail Edit:** Open customer details -> Tap Edit in AppBar -> Edit mobile -> Save -> Verify customer details and list update immediately.
