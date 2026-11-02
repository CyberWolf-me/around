---
name: staging-shipper
description: Validates Supabase migrations, executes the RLS security test suite against staging/local DB, builds the release artifacts, and ships the verified build.
---

# Staging Shipper Skill

## Step 1: Pre-Flight Verification Gate
1. Confirm `git status --porcelain` is clean (or commit completed task changes).
2. Run full local verification:
   ```bash
   flutter analyze --fatal-infos --fatal-warnings
   flutter test --coverage
   npm run build
   ```

## Step 2: Database Migration & RLS Verification
1. If `SUPABASE_ACCESS_TOKEN` and `SUPABASE_DB_URL` are configured:
   ```bash
   npx supabase db push --dry-run
   npx supabase db push
   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_authorization_test.sql
   ```
2. If any RLS assertion fails, halt deployment immediately and trigger the `task-loop-executor` rework loop.

## Step 3: Build & Ship Release Artifacts
1. Build the Flutter release bundle using runtime environment variables:
   ```bash
   flutter build apk --release \
     --dart-define=SUPABASE_URL="$SUPABASE_URL" \
     --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
     --dart-define=APP_ENV=staging
   ```
2. Push the verified branch and tag the release to trigger `.github/workflows/ci.yml`.
