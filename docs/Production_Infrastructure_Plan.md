# Production Infrastructure Plan
### Dependency Management · Plugin Architecture · Backup · CI/CD · Crash Reporting

This is the "keeps it stable after launch" layer, sitting on top of the
Build Plan and Module Plan. Since you're running your own Ubuntu server,
every recommendation here favors self-hosted tools over cloud SaaS where
it's reasonably practical — fits your stated direction of owning your own
backend eventually.

---

## 1. Dependency Version Management

**The risk this addresses:** an untracked `flutter pub upgrade` silently
changes a package version, something subtly breaks (a Drift migration
behavior, a date-parsing edge case), and you can't tell which dependency
caused it three weeks later.

**Rules:**
1. **Commit `pubspec.lock` to git.** This is not optional. It pins the
   *exact* resolved version of every package (including transitive ones)
   so your homelab build is reproducible — the same lockfile always
   produces the same binary.
2. **Use caret ranges in `pubspec.yaml` (`^1.2.0`), never bare "any."**
   Caret allows patch/minor updates but blocks breaking major-version
   bumps from sneaking in silently.
3. **Upgrade on a schedule, not accidentally.** Once a month (or before
   starting a new Phase), run `flutter pub outdated`, review the changelog
   of anything with a major version bump, upgrade deliberately, run the
   full test suite, commit the new lockfile as its own commit (not mixed
   with feature work).
4. **Pin these packages carefully, they're structural:** `drift`,
   `drift_dev`, `flutter_riverpod`, `sqlite3_flutter_libs`. A major version
   bump in any of these can require migration work, not just "upgrade and
   go" — treat these upgrades as their own small project, tested in
   isolation on a branch.
5. **Avoid pre-release/beta package versions** in anything that touches
   money, stock, or storage. Stability > having the newest feature.
6. **Track a `DEPENDENCIES.md`** listing each core package, why it was
   chosen, and what it would take to replace it (relevant for Drift → a
   future server-side ORM, or if a package gets abandoned).

---

## 2. Plugin Architecture (Internal Modularity)

**Goal:** let you add a new feature (e.g. multi-branch support, loyalty
points, a second shop) later without touching or risking existing modules
— genuine plug-in behavior, not just "well-organized folders."

**Pattern: Feature Registry + Isolated Feature Packages**

Structure each module (Customers, Billing, Expenses, etc.) as if it could
one day be split into its own local package:

```
lib/
  features/
    customers/
      customers.dart        <- single export file (the module's public API)
      models/
      repositories/
      services/
      providers/
      screens/
    billing/
      billing.dart
      ...
  core/
    feature_registry.dart
```

**Rules that make this a real plugin architecture, not just folders:**
- **One export file per feature** (`customers.dart`) — anything outside
  the feature imports *only* this file, never reaches into
  `features/customers/services/...` directly. This is your enforced
  boundary; breaking it is how "modular" folder structures quietly become
  tangled anyway.
- **Cross-feature communication only through Services calling other
  Services' public interfaces** — e.g. Billing calls `PartService` and
  `CustomerService`, never a repository or model belonging to another
  feature directly.
- **A `FeatureRegistry`** (a simple list of enabled feature identifiers)
  that the Dashboard/navigation reads from, so a future feature (e.g.
  "Loyalty Program") can register its own dashboard card and menu entry
  without editing a giant `if/else` in the main navigation file.
- **Feature flags for anything experimental:** a simple
  `FeatureFlags` class (even just a `Map<String, bool>` backed by a
  settings table) so you can ship a half-finished feature disabled, and
  turn it on when it's tested — useful once this is a live, deployed app
  you can't just break for users.

This gets you real "plugin" behavior (features are addable/removable
units) without the overhead of actual Dart package/plugin publishing,
which would be overkill for a single-app project.

---

## 3. Automated Backup Scheduling to Google Drive

**Components:**
1. **What gets backed up:** either the raw SQLite file (simplest, exact
   copy) or a JSON export of all tables (more portable, human-readable,
   easier to partially restore). Recommendation: **both** — raw file as
   the primary restore path, JSON export as a secondary safety net and for
   future server-migration tooling to consume.
2. **Scheduling:** use the `workmanager` package to register a periodic
   background task (Android `WorkManager` under the hood — respects
   battery/Doze constraints properly instead of fighting Android, which
   is what causes battery drain complaints in badly-built apps).
   - Recommend daily backups, configurable in Settings.
   - `WorkManager` periodic tasks have a 15-minute minimum granularity and
     aren't exact-time — that's fine for a daily backup, don't fight it.
3. **Google Drive integration:** `google_sign_in` for auth + the
   `googleapis` package's Drive v3 client. Use a **dedicated app folder**
   scope (`drive.file` scope, not full Drive access) — this only lets your
   app see/manage files it created itself, which is both more secure and
   an easier Google API verification process than requesting broad Drive
   access.
4. **Versioning/retention:** keep the last N backups (e.g. 14 daily +
   4 weekly), named with timestamps
   (`inventory_backup_2026-07-26T0300.db`), delete older ones after a
   successful new upload — never delete the old one *before* confirming
   the new upload succeeded.
5. **Restore path:** a Settings screen action: list available backups
   from Drive, pick one, download, validate (check schema version /
   table integrity before swapping), then replace the local DB. Always
   back up the *current* local DB before overwriting it with a restored
   one, in case the restore itself was a mistake.
6. **Failure handling:** if a scheduled backup fails (no network, auth
   expired), log it locally and surface a non-intrusive "last backup: 3
   days ago" indicator in Settings — silent backup failure is worse than
   no backup feature, since you'll falsely believe you're covered.

---

## 4. CI/CD Pipeline (Self-Hosted, Given Your Ubuntu Server)

Since you already run a homelab server, self-hosting CI avoids depending
on GitHub Actions' free-tier limits and keeps everything under your
control — consistent with your "own the backend" direction.

**Recommended stack:** **Woodpecker CI** (lightweight, Docker-based, easy
to self-host, YAML pipelines near-identical to GitHub Actions/Drone syntax)
or **Gitea Actions** if you're already using Gitea for your git hosting.
Either works fine; Woodpecker is the simpler standalone choice if you're
not already committed to a git server.

**Pipeline stages (each a step in your `.woodpecker.yml` or equivalent):**

```
1. checkout
2. flutter pub get              # install deps from the locked pubspec.lock
3. flutter analyze              # static analysis — fail build on warnings
4. flutter test                 # full unit + integration test suite
5. flutter build apk --release  # only if stage 3-4 pass
6. sign the APK                 # using a keystore stored as a CI secret,
                                   never committed to git
7. version/tag                  # semantic version + build number,
                                   derived from git tag or commit count
8. publish artifact             # copy signed APK to your server's file
                                   share or an internal download page
```

**Branch strategy tie-in (from the earlier Git Workflow section):**
- `feature/*` branches → run steps 1–4 only (lint + test, no build) on
  every push. Fast feedback, catches breakage before merge.
- `develop` → runs full pipeline including build, produces an internal
  "staging" APK for you to install and manually verify.
- `main` → full pipeline + produces the release-tagged APK, this is what
  actually gets installed on the shop's device.

**Secrets handling:** keystore file and passwords, Google Drive API
credentials — store these as CI secrets (Woodpecker supports encrypted
secrets), never in the repo, never in plain text in your pipeline file.

**Practical minimum viable version:** if a full pipeline feels like too
much up front, start with just steps 1–4 (lint + test) running on every
push — that alone catches the majority of "I broke something and didn't
notice" problems, and you can add build/sign/deploy stages later without
restructuring anything.

---

## 5. Crash Reporting

Given the homelab-first approach, **self-hosted Sentry** is the natural
fit — same Sentry SDK/API as the cloud version, but data stays on your
server, which also matters here specifically because your crash reports
could otherwise contain customer names/mobile numbers/financial data if
you're not careful (see scrubbing note below).

**Setup:**
1. Self-host Sentry (Docker Compose install, official Sentry
   self-hosted repo) on your Ubuntu server.
2. Add `sentry_flutter` package to the app, initialize with your
   self-hosted DSN instead of a sentry.io one.
3. Wrap `runApp()` with Sentry's error-catching entrypoint so uncaught
   Flutter errors and Dart exceptions are captured automatically.
4. **Also capture non-fatal errors explicitly** from Services — e.g. if
   `billService()` catches an `InsufficientStockException`, that's normal
   user-facing behavior, don't report it as a crash. But if a *database
   write fails unexpectedly* inside that same method, that's a real bug —
   report it via `Sentry.captureException()` even though it didn't crash
   the whole app.

**Critical privacy rule, since this app handles real customer/financial
data:** configure Sentry's `beforeSend` hook to strip or redact any field
that could contain PII — customer names, mobile numbers, part prices,
invoice totals — before the event is sent, even to your own self-hosted
instance. Log identifiers (e.g. "failed while billing service `abc123`")
instead of the actual customer/financial payload. This matters even
self-hosted, since crash reports shouldn't casually contain a customer's
personal data sitting in a log table indefinitely.

**Tie-in to CI/CD:** tag every crash report with the exact app version +
build number your pipeline produced (stage 7 above) — this is what lets
you say "this crash only happens in build 47, introduced between build 46
and 47" instead of guessing.

---

## How These Five Fit Together

```
CI/CD pipeline (§4)
  → produces versioned, tested builds
  → those version tags flow into Crash Reporting (§5) for accurate bug attribution
  → dependency pinning (§1) is what CI/CD's "flutter pub get" step relies on
     for reproducible builds

Plugin Architecture (§2)
  → is what lets you add e.g. "backup scheduling" (§3) itself as a clean,
     self-contained feature module, using the same registry/export pattern
     as Customers/Billing/etc., rather than bolting it awkwardly onto
     Settings

Backup Scheduling (§3)
  → is your disaster-recovery layer, independent of CI/CD/crash reporting,
     but should itself be tested via the same CI pipeline (a scheduled
     integration test: "backup, wipe local DB, restore, verify data
     matches" should be part of your test suite, not just trusted blindly)
```

**Suggested build order for these five, relative to your Module Plan:**
add Dependency Management (§1) and basic CI lint/test (§4, minimal
version) starting from Module 0 — they cost little and protect everything
after. Add Plugin Architecture (§2) discipline starting Module 1 (it's a
coding convention, not new work). Add Crash Reporting (§5) once Module 4
(Billing) exists — that's the highest-value place to catch real bugs
early. Add Backup Scheduling (§3) once you have real data worth backing up
— realistically after Modules 1–6 are stable, before you consider this
"launched."
