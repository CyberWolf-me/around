# STAGING DEPLOYMENT & VERIFICATION PLAN

- **Audit & Remediation Date:** 2026-11-01
- **Current Gate Status:** **READY FOR LOCAL VERIFICATION & STAGING DEPLOYMENT** (All pre-deployment blockers `STG-01` through `STG-06` have been remediated in code)

## 1. Pre-Deployment Configuration Status (Section 8)

| Configuration File | Remediation & Verification Status | Staging Safety Status |
|---|---|---|
| `supabase/config.toml` | Configured for PostgreSQL 15 (`port = 54322`), Storage (`5MiB` limit), Auth (`enable_anonymous_sign_ins = false`), and `[db.seed]` (`sql_paths = ["./seed.sql"]`). | **READY** |
| `supabase/migrations/00001`–`00006` | `00005` (`user_id`/`friend_id` & `DROP FUNCTION get_friends_feed`) and `00006` (`places.rating_avg`, `SEC-13` reaction/comment parent-post RLS, and `INSERT`/`DELETE` policies) are 100% aligned with `00001`–`00004`. | **READY** |
| `supabase/seed.sql` | Uses `00001`'s exact columns (`price_tier`, `hours`, `rating_avg`, `rating_count`), canonical Tashkent slugs (`breadly-bakery-cafe`, etc.), and `ON CONFLICT (id) DO UPDATE`. | **READY** |
| `.env.example` | Documents `APP_ENV`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `MAP_TILE_URL` with explicit `service_role` prohibition. | **SAFE** |
| `.github/workflows/ci.yml` | Runs `validate-database` (`supabase start`, `supabase db reset`, `psql -f supabase/tests/rls_authorization_test.sql`), `validate-flutter` (`flutter analyze`, `flutter test`, `flutter build apk --debug`), and `validate-web`. | **READY** |
| **Map Provider Config** | Defaults to OpenStreetMap tiles for local/staging testing; supports injecting a licensed commercial `MAP_TILE_URL` via `--dart-define` for production. | **READY** |

## 2. Completed Pre-Staging Remediations (`STG-01` – `STG-06`)

1. **`STG-01` (Completed):** Aligned `00005_security_and_rls_remediation.sql`, `supabase/tests/rls_authorization_test.sql`, and `lib/data/repositories/profiles_repository.dart` on `user_id` and `friend_id`.
2. **`STG-02` (Completed):** Added `DROP FUNCTION IF EXISTS public.get_friends_feed(INTEGER, INTEGER);` in `00005`, removed `pm.display_order`, and aligned the 19-column return signature with `00003` and `PostsNotifier.syncRemoteFeed()`.
3. **`STG-03` (Completed):** Updated `00006_platform_domains_and_discovery.sql` to use `p.rating_avg`, revoked `anon` execute on `get_recommended_places(INTEGER)`, and aligned `supabase/seed.sql` with `00001` (`ON CONFLICT (id) DO UPDATE`).
4. **`STG-04` (Completed):** Enforced parent-post visibility on `post_reactions` and `post_comments` `INSERT` policies (`SEC-13`), enforced private `post-media` Storage RLS (`SEC-14`), added missing `INSERT`/`DELETE` policies in `00006`, and scoped `supabase/tests/rls_authorization_test.sql` under `SET LOCAL ROLE authenticated`.
5. **`STG-05` (Completed):** Added remote hydration (`syncRemoteProfile`, `syncRemoteFriendships`, `syncRemoteBlocks`, `syncRemoteSavedPlaces`, `syncRemotePlaceDrops`) across all Flutter repositories.
6. **`STG-06` (Completed):** Added the `validate-database` Supabase CLI job and `flutter build apk --debug` to `.github/workflows/ci.yml`.

## 3. Safe Step-by-Step Staging Execution Sequence

### Step 1 — Local Database & Mobile Verification
Run on a developer workstation or CI runner with Docker, Supabase CLI, and Flutter SDK installed:
```bash
# 1. Start local Supabase stack and reconstruct database from 00001..00006 + seed.sql
supabase start
supabase db reset

# 2. Execute multi-user RLS authorization test suite under ROLE authenticated
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
  -v ON_ERROR_STOP=1 \
  -f supabase/tests/rls_authorization_test.sql

# 3. Verify Flutter static analysis, unit/widget tests, and debug APK compilation
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
**Gate 1 Exit Criteria:** `supabase db reset` and `rls_authorization_test.sql` exit `0` with zero SQL errors; `flutter analyze`, `flutter test`, and `flutter build apk --debug` exit `0`.

### Step 2 — Non-Destructive Staging Database Deployment
> **CRITICAL SAFETY RULE:**
> - `supabase db reset` resets the **local** Docker database by default.
> - `supabase db push` applies pending migrations non-destructively to the **linked remote staging project**.
> - **NEVER** run `supabase db reset --linked` on a persistent staging or production environment without an explicitly approved destructive reset procedure.

```bash
# 1. Authenticate and link to the isolated staging project
supabase login
supabase link --project-ref <STAGING_PROJECT_REF>

# 2. Inspect migration history alignment between local and remote staging
supabase migration list

# 3. Preview pending migrations without modifying the remote database
supabase db push --dry-run

# 4. After reviewing dry-run output, apply migrations and synthetic Tashkent venue seeds
supabase db push --include-seed
```

### Step 3 — Multi-User Staging Authorization Verification
Using three isolated synthetic staging accounts (`alice.staging@around.uz`, `bob.staging@around.uz`, `charlie.staging@around.uz` — never real user PII), verify:
1. Alice publishes a `friends`-only Drop -> Bob (accepted friend) sees it in `get_friends_feed`; Charlie (stranger) receives `0` rows.
2. Charlie sends Alice a friend request (`status = 'pending'`) -> Charlie still cannot read Alice's `friends`-only Drop and cannot self-accept the request (`UPDATE friendships SET status = 'accepted'` rejected by RLS).
3. Alice blocks Bob -> Bob immediately loses visibility into Alice's profile, drops, collections, stories, and plans.
4. Alice creates a collaborative collection (`is_collaborative = true`) -> only accepted friends can insert items; strangers are rejected.
5. Charlie attempts to insert a comment or reaction on Alice's `friends`-only Drop -> rejected by RLS (`SEC-13`).

### Step 4 — Dual-Device Mobile Integration Testing
Launch the Flutter app on two physical or simulated devices (iOS Simulator + Android Emulator/Device) using:
```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=SUPABASE_URL=https://<STAGING_PROJECT_REF>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<STAGING_PUBLIC_ANON_KEY> \
  --dart-define=MAP_TILE_URL=<STAGING_MAP_TILE_URL>
```
Verify Journeys A through H end-to-end across both devices, including app restarts, camera/gallery upload to `post-media`, GPS permission denial fallback, and `Delete Account` (`delete_own_account()` RPC).

### Step 5 — Controlled Tashkent Cohort Rollout
Only after Steps 1–4 pass with zero open Critical or High findings:
1. **Wave 1:** Internal engineering & product team (3–5 users in Tashkent).
2. **Wave 2:** Trusted external alpha group (5–10 users).
3. **Wave 3:** Controlled 20–30 person Tashkent cohort via TestFlight and Google Play Internal Testing.
