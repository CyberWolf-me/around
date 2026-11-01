# ADR 003: Canonical Frontend Stack Decision (Flutter Mobile-First)

- **Status:** Accepted
- **Date:** 2026-10-30
- **Task IDs:** `ARCH-01`, `ARCH-02`, `ARCH-03`, `ARCH-04`, `ARCH-05`
- **Deciders:** CTO / Engineering Orchestrator, Mobile Lead, Backend/Security Lead

## 1. Context and Problem Statement

Around was audited and found to contain two competing frontend implementations in the same repository root:
1. A **Flutter mobile application** (`lib/`, `pubspec.yaml`, `android/`, `ios/`) targeting native iOS and Android with Riverpod (`flutter_riverpod`), `go_router`, `flutter_map`, `image_picker`, `shared_preferences`, and `supabase_flutter`.
2. A **React 18 + TypeScript + Vite web prototype** (`src/`, `package.json`, `index.html`) built as an interactive browser mockup with a desktop device-frame switcher (`DesktopRail.tsx`, `MobileFrame.tsx`) and static SVG map (`CityMap.tsx`).

Maintaining two parallel frontend implementations created data divergence, split engineering effort, contradictory CI pipelines, and ambiguity over which client represents the production product. Because Around's release strategy is **mobile-first** for a real-world pilot in **Tashkent, Uzbekistan**, we must select a single canonical frontend framework and define the disposition of the secondary implementation.

## 2. Decision Drivers

1. **Mobile-first release target:** Native iOS and Android feel, 60/120fps scrolling, tactile haptics, sheet physics, and native camera/photo-library integration.
2. **Real geospatial mapping:** Interactive pan/zoom street map of Tashkent (`41.3111° N, 69.2797° E`) with real PostGIS coordinates and walking-distance calculation, rather than a static SVG illustration.
3. **Direct Supabase integration:** Official SDK support for PKCE auth session persistence, PostGIS RPC invocation, and multipart binary uploads to Supabase Storage.
4. **Engineering velocity & stabilization cost:** Minimizing rewrite risk by building on the stack that already has native mobile shells and domain repositories.

## 3. Alternatives Considered (`ARCH-01`)

| Criterion | Option A: Flutter (`lib/`) — **SELECTED** | Option B: React + Capacitor/Wrapper (`src/`) |
|---|---|---|
| **Existing implementation** | Complete 8-screen mobile shell, models, repositories, and services (`30` Dart files) | 9-screen browser prototype wrapped in a desktop simulator frame (`31` TS/TSX files) |
| **Native iOS / Android shells** | Native `ios/` (`Info.plist`, `PrivacyInfo.xcprivacy`) and `android/` (`build.gradle.kts`, `AndroidManifest.xml`) already configured | None present; requires introducing Capacitor/Cordova or rewriting UI into React Native |
| **State management** | `flutter_riverpod` (`NotifierProvider`) with clear repository boundaries | Single monolithic `AppContext.tsx` with `localStorage` |
| **Navigation & deep linking** | Declarative `go_router` with `StatefulShellRoute.indexedStack` preserving tab state | Custom in-memory array stack (`stack: StackScreen[]`) with no URL routing |
| **Map implementation** | Real `flutter_map` (`latlong2`) rendering Tashkent coordinates with Haversine distance | Static 4x5 SVG grid (`CityMap.tsx`) using percentage `{x, y}` coordinates |
| **Supabase & Storage SDK** | `supabase_flutter` wired for Auth, PostGIS RPCs, and `post-media` Storage uploads | Zero `@supabase/supabase-js` dependency installed in `package.json` |
| **Automated testing** | `flutter_test` unit + widget test suites (`test/unit/`, `test/widget_test.dart`) | `vitest` unit tests (`src/__tests__/`) |

## 4. Technical Spike Verification (`ARCH-02`)

We verified a complete vertical mobile flow in the Flutter client (`lib/`):
1. **Startup & Environment Initialization:** `lib/main.dart` initializes `StorageService` and `SupabaseService` (via compile-time `--dart-define` environment variables), then mounts `GoRouter` (`lib/core/routing/app_router.dart`).
2. **Navigation & Route Guards:** `StatefulShellRoute.indexedStack` switches cleanly across `/feed`, `/explore`, `/saved`, and `/profile`, while top-level routes (`/places/:id`, `/users/:id`, `/auth`, `/settings`, `/notifications`, `/onboarding`, `/create`) push onto the root navigator.
3. **Native Photo Selection & Validation:** `CreateDropSheet` (`lib/features/create_post/screens/create_drop_sheet.dart`) invokes `ImagePicker` (`camera` and `gallery`), validates MIME extension (`.jpg`, `.jpeg`, `.png`, `.webp`) and size (`<= 5 MB`) via `AppLogger.validateImagePath`, persists local previews safely, and uploads binary objects to Supabase Storage (`post-media`) with orphan cleanup on failure.
4. **Location & Tashkent Map Rendering:** `ExploreScreen` (`lib/features/explore/screens/explore_screen.dart`) renders Tashkent venues on `FlutterMap` centered at `41.3111, 69.2797`, calculates real Haversine walking distances, and degrades gracefully when device location permissions are denied.
5. **Supabase API & RLS Communication:** `PlacesRepository`, `PostsNotifier`, `ProfileNotifier`, `FriendshipStatusesNotifier`, `BlockedUsersNotifier`, and `SavedPlacesNotifier` communicate with PostgreSQL tables and PostGIS RPCs (`get_friends_feed`, `get_nearby_places`, `get_user_visible_drops`, `delete_own_account`).

## 5. Decision Outcome (`ARCH-03`, `ARCH-04`, `ARCH-05`)

**We select Flutter (`lib/`) as the sole canonical mobile application for Around.**

### Consequences & Repository Consolidation Strategy
- **Canonical Client (`lib/`):** All Phase 1–5 engineering work, mobile CI/CD release gates, and Tashkent pilot builds target the Flutter application.
- **Disposition of Web Prototype (`src/`):** In accordance with the CTO Mandate (*"Do not delete reference implementations, designs or assets before confirming what needs to be retained"*), the React prototype in `src/` has been synchronized with the canonical Tashkent dataset and privacy logic to serve as a zero-install visual reference and browser preview, but **no parallel feature development** will occur in `src/`.
- **Clean Version Control:** Committed `node_modules/` (3,077 files, ~97 MB) has been permanently purged from the repository archive.
