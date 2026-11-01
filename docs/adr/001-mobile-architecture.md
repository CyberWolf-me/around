# ADR 001: Mobile Application & Web Companion Architecture

## Status
Accepted (Updated for Tashkent Launch)

## Context
Around requires a mobile-first user experience that feels native, tactile, visual, and instantaneous for our launch cohort in **Tashkent, Uzbekistan** (Mirabad, Yakkasaray, Yunusabad, Shaykhontohur, and Mirzo Ulugbek districts). The product mandates:
- Rich tactile micro-interactions (haptics, sheet gestures, bento grid layout, interactive maps).
- Strict dual-layer privacy enforcement (mutual friends vs. public community discovery) backed by PostgreSQL Row-Level Security (RLS) and PostGIS.
- Offline-first resilience (caching saved places, statuses, custom drops, and privacy settings).
- Multi-platform accessibility: a native iOS/Android mobile client (`lib/`) paired with an interactive browser-based web companion (`src/`) for rapid stakeholder demos and desktop device-frame previews.

## Decision
We maintain a unified **Around · Tashkent** domain model across two complementary client targets backed by a shared **Supabase PostgreSQL 15 + PostGIS** backend (`supabase/migrations/`):

1. **Primary Mobile Client (`lib/`, `pubspec.yaml`)**:
   - **Framework**: Flutter & Dart (`>= 3.5.0`).
   - **State Management**: Riverpod (`flutter_riverpod`) with `SharedPreferences` local persistence (`lib/data/services/storage_service.dart`) and live Supabase cloud synchronization (`lib/data/services/supabase_service.dart`).
   - **Navigation**: `go_router` with `StatefulShellRoute.indexedStack` for persistent bottom tabs (`/feed`, `/explore`, `/saved`, `/profile`) and top-level routes (`/places/:id`, `/users/:id`, `/auth`, `/settings`, `/notifications`, `/onboarding`).
   - **Mapping**: `flutter_map` with configurable raster/vector tile layers centered on Tashkent (`41.3111, 69.2797`) and Haversine walking distance calculation.
2. **Interactive Web Companion (`src/`, `package.json`)**:
   - **Framework**: React 18 + TypeScript 5.6 + Vite 5.
   - **Runtime Modes**: Supports in-device preview frames (`iPhone 16 Pro`, `Pixel`, and `Fullscreen` mobile viewport) for instant browser evaluation without native compilation.
3. **Design Tokens & Theme Architecture**:
   - Typography: `Bricolage Grotesque` (display headings), `Instrument Sans` (body copy), `Space Mono` (metadata/tags).
   - Color Palette: Bone paper (`#FBFAF6`), Ink (`#15130F`), Signal Orange (`#FF5A1F`), Butter (`#FFE07A`), Mint (`#D5E8CB`), Cobalt (`#2B4CFF`).

## Consequences
- **Positive**:
  - Native mobile performance on iOS and Android via Flutter while preserving zero-install browser previews via Vite/React.
  - Canonical Tashkent venue UUIDs in PostGIS (`00004_triggers_and_storage.sql`) decouple our social graph from external map vendor lock-in.
  - Compile-time `--dart-define` configuration prevents credential exposure in client storage.
