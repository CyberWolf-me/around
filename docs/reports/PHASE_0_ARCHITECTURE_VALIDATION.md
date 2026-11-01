# Phase 0 — Architecture Validation & Technical Spike Report

- **Task IDs:** `ARCH-01`, `ARCH-02`, `ARCH-03`, `ARCH-04`, `ARCH-05`
- **Date:** 2026-10-30
- **Status:** COMPLETE (Decision Gate Passed — Flutter Selected as Canonical Mobile Stack)

## 1. Executive Summary (`ARCH-01`)

We evaluated both frontend codebases in the repository against Around's mobile-first Tashkent MVP requirements:
1. **Flutter Application (`lib/`)**: Native iOS/Android client using Riverpod, `go_router`, `flutter_map`, `image_picker`, and `supabase_flutter`.
2. **React/Vite Web Prototype (`src/`)**: Browser-based UI mockup with a simulated phone bezel (`MobileFrame.tsx`) and static SVG map (`CityMap.tsx`).

**Conclusion:** Flutter (`lib/`) is selected as the **sole canonical mobile application** (`docs/adr/003-frontend-stack-decision.md`). It already provides native iOS/Android runners, real geographic mapping (`flutter_map` + `latlong2`), a modular repository layer (`lib/data/repositories/`), and direct integration with `supabase_flutter`.

## 2. Technical Spike Verification Matrix (`ARCH-02`)

| Spike Capability | Flutter (`lib/`) Verification | React (`src/`) Comparison |
|---|---|---|
| **App Startup & Config** | Verified in `lib/main.dart` + `SupabaseService.initialize()` using `--dart-define` build variables with offline fallback. | Browser-only `localStorage` initialization in `AppContext.tsx`. |
| **Navigation & Deep Links** | Verified `GoRouter` (`lib/core/routing/app_router.dart`) with `StatefulShellRoute.indexedStack` and parameterized routes (`/places/:id`, `/users/:id`, `/auth`). | In-memory array `stack: StackScreen[]` without URL routing or native back-gesture handling. |
| **Native Camera & Gallery** | Verified `image_picker` in `lib/features/create_post/screens/create_drop_sheet.dart` with iOS `Info.plist`/`PrivacyInfo.xcprivacy` and Android permissions configured. | HTML `<input type="file">` with canvas resize. |
| **Location & Map Rendering** | Verified `flutter_map` in `lib/features/explore/screens/explore_screen.dart` with real Tashkent WGS84 coordinates (`41.3111, 69.2797`) and Haversine distance fallback. | Static SVG illustration (`CityMap.tsx`) with hardcoded `{x, y}` percentages. |
| **Backend & Storage API** | Verified `supabase_flutter` calls to `get_friends_feed`, `get_nearby_places`, `get_user_visible_drops`, `delete_own_account`, and `post-media` Storage uploads. | No `@supabase/supabase-js` client installed. |
| **Automated Tests** | Verified unit tests (`test/unit/places_repository_test.dart`, `post_privacy_test.dart`, `saved_places_test.dart`) and widget tests (`test/widget_test.dart`). | Verified 8/8 unit tests in `src/__tests__/privacy.test.ts` and `storage.test.ts`. |

## 3. Build, Testing & Deployment Feasibility (`ARCH-03`, `ARCH-04`)

- **Mobile Release Pipeline (`.github/workflows/ci.yml` & `mobile-release.yml`):**
  - Runs `flutter pub get`, `dart format --output=none --set-exit-if-changed lib/ test/`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, and macOS `flutter build ios --no-codesign`.
- **Database Migration & Security Gate:**
  - Validates `supabase/migrations/00001` through `00005`, `supabase/seed.sql`, and `supabase/tests/rls_authorization_test.sql`.
- **Web Reference Maintenance (`ARCH-04`):**
  - The React prototype in `src/` is preserved as a lightweight browser design reference (synchronized on the Tashkent dataset) and verified via `npx tsc --noEmit` and `vitest`, while all new mobile engineering targets `lib/`.
