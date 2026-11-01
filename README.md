# Around · Places-First Social Discovery Platform

[![CI Pipeline](https://github.com/around-app/around/actions/workflows/ci.yml/badge.svg)](https://github.com/around-app/around/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791.svg)](https://www.postgresql.org/)
[![PostGIS](https://img.shields.io/badge/PostGIS-3.3-00599C.svg)](https://postgis.net/)
[![Supabase](https://img.shields.io/badge/Supabase-Auth%20%26%20RLS-3ECF8E.svg)](https://supabase.com/)

**Around** is a mobile-first social discovery platform designed to answer *“Where should we go?”* through real experiences, verified photos, and curated recommendations from friends and the local urban community.

Unlike traditional review platforms overloaded with 5-star fake reviews and generic directories, **Around** is built on authentic friend connections, an editorial aesthetic, and a dual-layer privacy architecture.

## Architecture & Tech Stack

```
┌─────────────────────────────────────────────────────────────┐
│        Flutter Mobile App (`lib/`) & Web Companion (`src/`) │
│  - Flutter: Riverpod 3.x, go_router 17.x, flutter_map       │
│  - Web Companion: React 18, TypeScript 5.6, Vite 5          │
│  - Typography & Design: Bricolage Grotesque & Neo-Brutalist │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS / PostgREST / Storage
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Supabase Cloud Platform                      │
│  - Authentication: Supabase Auth (JWT + Auto Profile Trigger)│
│  - Storage: `post-media` bucket with owner RLS policies      │
│  - Row-Level Security (RLS): Dual-layer privacy engine       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│              PostgreSQL 15 + PostGIS Spatial Engine          │
│  - Canonical Places: PostGIS GEOGRAPHY(Point, 4326)         │
│  - Spatial GiST + GIN Indexes: Fast nearby & tag queries     │
│  - RLS Policies: Friends vs Public drop isolation           │
└─────────────────────────────────────────────────────────────┘
```

### 1. Client Applications
- **Flutter Mobile Client (`lib/`)**: Built with Flutter & Dart (`>= 3.5.0`), Riverpod state management, `go_router` (`StatefulShellRoute.indexedStack`), `flutter_map`, and `SharedPreferences` local persistence with optional live Supabase cloud synchronization.
- **Interactive Web Companion (`src/`)**: Built with React 18, TypeScript, and Vite for browser-based device simulation (`iPhone` / `Pixel` / `Fullscreen` modes) and rapid prototyping.
- **Design Language**: Editorial Neo-Brutalist (Bone paper `#FBFAF6`, Signal Orange `#FF5A1F`, crisp 2px ink borders, `Bricolage Grotesque`, `Instrument Sans`, `Space Mono`).

### 2. Backend & Spatial Database (`supabase/migrations/`)
- **Primary Backend**: Supabase (PostgreSQL 15, Auth, Storage).
- **Geospatial Engine**: PostGIS `GEOGRAPHY(Point, 4326)` with GiST spatial indexing (`get_nearby_places`).
- **Privacy Enforcement**: PostgreSQL Row Level Security (RLS) and `SECURITY INVOKER` RPCs (`get_friends_feed`) guaranteeing that friends-only drops are never leaked to non-friends or blocked accounts.

## Dual-Layer Privacy Invariant

The core architecture strictly separates **Friends-Only Drops** from **Public Reviews**:

```sql
CREATE POLICY "posts_select_dual_layer" ON posts
  FOR SELECT
  TO authenticated
  USING (
    author_id = auth.uid()
    OR (
      NOT is_blocked(auth.uid(), author_id)
      AND (
        audience = 'public'
        OR (
          audience = 'friends'
          AND are_friends(auth.uid(), author_id)
        )
      )
    )
  );
```

## Getting Started

### Option A: Flutter Mobile App (`lib/`)
1. **Install dependencies**:
   ```bash
   flutter pub get
   ```
2. **Run Unit and Widget Tests**:
   ```bash
   flutter test
   ```
3. **Run the App**:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```
   *(If `SUPABASE_URL` and `SUPABASE_ANON_KEY` are omitted, the app runs seamlessly in offline local persistence mode with pre-seeded Tashkent venues and drops.)*

### Option B: React/TypeScript Web Companion (`src/`)
1. **Install Node dependencies**:
   ```bash
   npm install
   ```
2. **Run Type Check & Unit Tests**:
   ```bash
   npm run lint
   npm test
   ```
3. **Start Vite Dev Server**:
   ```bash
   npm run dev
   ```

## Documentation & Governance
- [Architecture Decision Record 001: Client Architecture](./docs/adr/001-mobile-architecture.md)
- [Architecture Decision Record 002: Dual-Layer Privacy Model](./docs/adr/002-dual-layer-privacy-model.md)
- [Tashkent Map Provider Evaluation](./docs/research/TASHKENT_MAP_PROVIDER_EVALUATION.md)
- [Collaboration Standards & RACI Matrix](./docs/standards/COLLABORATION_STANDARDS.md)
- [Delivery Process & Test Pyramid](./docs/standards/DELIVERY_PROCESS.md)
- [Privacy & Safety Governance](./docs/standards/PRIVACY_AND_SAFETY_GOVERNANCE.md)

## License
Released under the [MIT License](./LICENSE).
