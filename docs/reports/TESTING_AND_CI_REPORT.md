# Around — Automated Testing Isolation & CI Hardening Report
**Author:** CTO Orchestrator & QA Lead  
**Date:** November 2, 2026  
**Status:** COMPLETED & VERIFIED  
**Applicable Tasks:** P0-02, P4-01, P4-02

---

## 1. Executive Summary

Prior to Phase 7A, cloud smoke testing was co-located in `test/integration/live_staging_smoke_test.dart`. Because Flutter executes all tests in `test/` recursively by default (`flutter test`), local checkouts and CI workflows without a configured `.env` or network access would attempt remote network operations, risk mutating live staging environments, and experience nondeterministic timeouts.

To guarantee zero-flakiness and strict compliance with Rule A & Rule G of the CTO Mandate:
1. **Architectural Separation:** Ordinary unit and widget tests are strictly isolated in `test/unit/` and `test/widget/`. They run completely offline, deterministically, and with zero `.env` or network dependency.
2. **Cloud Integration Isolation:** Multi-user live cloud smoke tests were moved to `integration_test/live_staging_smoke_test.dart`. They run only when explicitly targeted.
3. **Guaranteed Teardown & Isolation:** Live tests feature automatic environment detection, synthetic UUID namespaces, and robust teardown logic that expunges created test rows even if intermediate assertions fail.
4. **CI Pipeline Hardening:** GitHub Actions workflow `.github/workflows/ci.yml` runs offline verification without requiring secrets for standard pull requests.

---

## 2. Test Architecture & Directory Structure

```
around/
├── test/                          # Offline, Deterministic Standard Test Suite
│   ├── unit/
│   │   ├── places_repository_test.dart  # PostGIS spatial ranking, Tashkent canonical slugs
│   │   ├── post_privacy_test.dart       # Mutual friendship, auto-quarantine, visits privacy
│   │   └── saved_places_test.dart       # Shortlist toggle, want_to_go vs been statuses
│   ├── widget/
│   │   ├── bento_card_test.dart         # BentoCard render, reactions, comments
│   │   └── onboarding_auth_flow_test.dart # Onboarding -> Auth -> Guest navigation
│   └── widget_test.dart                 # AroundApp smoke test (5-tab navigation, shell)
│
├── integration_test/              # Explicit Cloud Integration Suite (Separately Invoked)
│   └── live_staging_smoke_test.dart     # Two-user live Supabase staging handshake & teardown
│
├── supabase/tests/                # PostgreSQL RLS Security & Authorization Suite
│   └── rls_authorization_test.sql       # 11-test multi-role SQL assertion suite
│
└── src/__tests__/                 # Web Reference Synchronized Test Suite
    ├── privacy.test.ts            # Web dual-layer privacy & moderation unit tests
    └── storage.test.ts            # Local persistence & caching tests
```

---

## 3. Standard Test Suite Execution (`flutter test`)

Execution Command:
```bash
flutter test
```

Characteristics:
- **Offline:** Does not attempt DNS resolution, HTTP requests, or socket connections.
- **Hermetic:** Does not inspect the local file system for `.env`.
- **Fast:** Executes 24 complete test cases in ~4 seconds.
- **Deterministic:** 100% repeatable across developer laptops, Docker containers, and GitHub Actions runners.

Current Output:
```
00:04 +24: All tests passed!
```

---

## 4. Cloud Integration Test Suite (`integration_test/live_staging_smoke_test.dart`)

Execution Command:
```bash
flutter test integration_test/live_staging_smoke_test.dart
```

### 4.1 Safety & Environment Detection
When executed in an environment without `.env` or `SUPABASE_URL` / `SUPABASE_ANON_KEY`, the test prints an informational notice and exits cleanly without failure:
```
Notice: Live Supabase staging credentials not found (.env absent or unconfigured). Skipping live staging smoke test.
```

### 4.2 Multi-User Lifecycle & Guaranteed Teardown
When run against a configured staging instance, the test exercises the full two-user lifecycle across 5 flows:
1. **Flow 1: Sign Up & Profiles:** Registers synthetic users Alice and Bob (`alice_<ts>@test.uz`, `bob_<ts>@test.uz`) and verifies trigger-created profile records.
2. **Flow 2: Mutual Friendship:** Alice initiates a pending friend request; Bob accepts; verifies `are_friends` relationship.
3. **Flow 3: Places Discovery & Friends Drops:** Alice discovers Breadly (`breadly-bakery-cafe`) and publishes a private `audience: 'friends'` Drop; Bob queries `get_friends_feed` RPC and successfully receives the drop.
4. **Flow 4: Shortlists & Statuses:** Bob saves Breadly as `want_to_go` and subsequently updates to `been`.
5. **Flow 5: Safety & Content Isolation:** Bob blocks Alice; verifies that `get_friends_feed` immediately hides Alice's drop from Bob; Bob unblocks Alice.
6. **Guaranteed Teardown (`finally` block):** Even if an assertion throws, the test cleans up synthetic rows across `posts`, `friendships`, `saved_places`, `blocks`, and `profiles`.

---

## 5. Continuous Integration (CI) Workflow Alignment

`.github/workflows/ci.yml` is structured into three parallel matrix jobs:

1. **`validate-database` (Ubuntu Latest):**
   - Boots local Supabase Docker stack (`supabase start`).
   - Applies migrations `00001` through `00008` and `supabase/seed.sql`.
   - Executes multi-user SQL authorization suite: `psql -f supabase/tests/rls_authorization_test.sql`.

2. **`validate-flutter` (Ubuntu Latest):**
   - Installs Flutter stable.
   - Runs `flutter analyze` (Zero static analysis issues).
   - Runs `flutter test` (Zero environment requirements; 24 passing tests).
   - Compiles debug APK: `flutter build apk --debug`.

3. **`validate-web` (Ubuntu Latest):**
   - Runs TypeScript strict compilation (`npm run lint`).
   - Runs Vitest suite (`npm test`, 16 passing tests).
   - Verifies bundle build (`npm run build`).

---

## 6. Verification Status

- [x] Standard unit and widget tests separated from cloud smoke test.
- [x] `integration_test/` directory created following Flutter standards.
- [x] `flutter test` runs 100% offline with zero failures (24/24).
- [x] `npm test` runs with zero failures (16/16).
- [x] CI workflow validated.
