# STAGING READINESS & PLATFORM VERIFICATION REPORT

- **Audit & Remediation Date:** 2026-11-01
- **Target Archive:** `around-fixed.zip`
- **Canonical Stack:** Flutter (`lib/`, `pubspec.yaml`, `android/`, `ios/`) + Supabase PostgreSQL 15 / PostGIS (`supabase/`)
- **Overall Verdict:** **READY FOR LOCAL VERIFICATION & STAGING DEPLOYMENT** (All 5 critical SQL migration/seed mismatches `MIG-01`–`MIG-05`, security gaps `SEC-13`–`SEC-14`, and client-backend sync blockers `INT-01`–`INT-03` have been remediated in code)

## 1. Summary of Pre-Staging Blockers Found & Remediated

| ID | Original Finding | Remediation Verified in `around-fixed.zip` | Status |
|---|---|---|---|
| **MIG-01** | `00005`, `rls_authorization_test.sql`, and `profiles_repository.dart` referenced non-existent `requester_id` and `addressee_id` instead of `00001`'s `user_id` and `friend_id`. | Updated `00005_security_and_rls_remediation.sql`, `supabase/tests/rls_authorization_test.sql`, and `lib/data/repositories/profiles_repository.dart` to use `user_id` (initiator) and `friend_id` (recipient) consistently. | **REMEDIATED** |
| **MIG-02** | `00005` called `CREATE OR REPLACE FUNCTION get_friends_feed(INT, INT)` with an incompatible 18-column return signature without `DROP FUNCTION` first (`ERROR 42P13`) and referenced non-existent `pm.display_order`. | Added `DROP FUNCTION IF EXISTS public.get_friends_feed(INTEGER, INTEGER);` in `00005`, replaced `pm.display_order` with `pm.created_at ASC`, and aligned the 19-column return signature with `00003` and `PostsNotifier.syncRemoteFeed()`. | **REMEDIATED** |
| **MIG-03** | `00006` referenced `p.avg_rating` instead of `00001`'s `p.rating_avg` inside `get_recommended_places()` and granted `EXECUTE` to `anon` (which lacks permission on `are_friends`/`is_blocked`). | Updated `00006_platform_domains_and_discovery.sql` to select `p.rating_avg` and restricted `EXECUTE` on `get_recommended_places(INTEGER)` strictly to `authenticated`. | **REMEDIATED** |
| **MIG-04** | `supabase/seed.sql` referenced non-existent columns (`price_level`, `hours_text`, `avg_rating`, `review_count`, `saves_count`) and conflicting slugs under `ON CONFLICT (slug)`. | Rewrote `supabase/seed.sql` to use `00001`'s exact columns (`price_tier`, `hours`, `rating_avg`, `rating_count`), canonical slugs (`breadly-bakery-cafe`, etc.), and `ON CONFLICT (id) DO UPDATE`, and added `[db.seed]` to `supabase/config.toml`. | **REMEDIATED** |
| **SEC-13** | `post_reactions` and `post_comments` `INSERT` policies in `00006` did not check parent post visibility, allowing strangers who knew a `post_id` UUID to react/comment on private `friends`-only Drops. | Replaced with `post_reactions_insert_authorized` and `post_comments_insert_authorized` in `00006`, enforcing that the parent `post_id` is visible to `auth.uid()` under dual-layer privacy and not blocked. | **REMEDIATED** |
| **SEC-14** | `post-media` bucket had `public: true` and `post_media_storage_auth_read` allowed any authenticated user to read any file; `publishDrop` passed `uploadedUrl` instead of `storagePath` to `removeOrphanedMedia`. | Set `public = FALSE` on `post-media` in `00005`, added `post_media_storage_dual_layer_read` Storage RLS policy, and added `UploadedMediaResult` (`storagePath` + `createSignedUrl`) in `SupabaseService`. | **REMEDIATED** |
| **MIG-05** | Missing `INSERT`/`DELETE` RLS policies on `friend_plan_participants`, `collection_items`, `place_stories`, `post_comments`, and `moderation_audit_logs`; `rls_authorization_test.sql` lacked `SET LOCAL ROLE authenticated`. | Added all missing `INSERT`, `DELETE`, and `SELECT` RLS policies in `00006` and updated `supabase/tests/rls_authorization_test.sql` to execute under `SET LOCAL ROLE authenticated`. | **REMEDIATED** |
| **INT-01 / 02 / 03** | Flutter repositories did not hydrate remote `profiles`, `friendships`, `blocks`, `saved_places`, or venue `posts` on login, and `.github/workflows/ci.yml` lacked a Supabase CLI migration job. | Added `syncRemoteProfile()`, `syncRemoteFriendships()`, `syncRemoteBlocks()`, `syncRemoteSavedPlaces()`, `syncRemotePlaceDrops()`, `reactToPost()`, `addCommentToPost()`, `rsvpToPlan()`, and the `validate-database` CI job in `.github/workflows/ci.yml`. | **REMEDIATED** |

## 2. Distinction Between Static Verification and Local/Staging Execution

- **Verified via Static & Node Execution in Sandbox:**
  - TypeScript strict compilation (`tsc --noEmit`: 0 errors) and unit tests (`8/8` passing).
  - 100% SQL column/type/signature cross-check across `00001`–`00006`, `supabase/seed.sql`, and `supabase/tests/rls_authorization_test.sql`.
  - Dart model and repository contract alignment across `lib/data/`.
- **Requires Execution in Local / CI / Staging Environment (`STAGING_DEPLOYMENT_PLAN.md`):**
  - Running `supabase start && supabase db reset` and `psql -f supabase/tests/rls_authorization_test.sql` against a live PostgreSQL 15 + PostGIS instance.
  - Running `flutter pub get && flutter analyze && flutter test && flutter build apk --debug` with the Flutter SDK.
  - Executing dual-device multi-user integration tests against the linked staging project before onboarding the 20–30 person Tashkent pilot cohort.
