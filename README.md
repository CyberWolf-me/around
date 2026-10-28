# Around · Places-First Social Discovery Platform

[![Flutter CI](https://github.com/around-app/around/actions/workflows/ci.yml/badge.svg)](https://github.com/around-app/around/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791.svg)](https://www.postgresql.org/)
[![PostGIS](https://img.shields.io/badge/PostGIS-3.3-00599C.svg)](https://postgis.net/)
[![Supabase](https://img.shields.io/badge/Supabase-Auth%20%26%20RLS-3ECF8E.svg)](https://supabase.com/)

**Around** is a mobile-first social discovery platform designed to answer *“Where should we go?”* through real experiences, verified photos, and curated recommendations from friends and the local urban community.

Unlike traditional review platforms overloaded with 5-star fake reviews and generic directories, **Around** is built on authentic friend connections, an editorial aesthetic, and a dual-layer privacy architecture.

---

## 🏛 Architecture & Tech Stack

```
┌─────────────────────────────────────────────────────────────┐
│                   Flutter Mobile App (iOS & Android)         │
│  - State Management: Riverpod 2.x / 3.x                      │
│  - Navigation: go_router 17.x (StatefulShellRoute)          │
│  - Typography & Design: Bricolage Grotesque & Neo-Brutalist │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS / Realtime WSS
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Supabase Cloud Platform                      │
│  - Authentication: Supabase Auth (JWT + OTP)                 │
│  - Storage: Photo CDN with thumbnail derivation             │
│  - Row-Level Security (RLS): Dual-layer privacy engine       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│              PostgreSQL 15 + PostGIS Spatial Engine          │
│  - Canonical Places: PostGIS GEOGRAPHY(Point, 4326)         │
│  - Spatial GiST Index: Sub-5ms nearby radius queries        │
│  - RLS Policies: Friends vs Public drop isolation           │
└─────────────────────────────────────────────────────────────┘
```

### 1. Mobile Client
- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x)
- **State Management**: [Riverpod](https://riverpod.dev) with reactive invalidation and selective rebuilds
- **Routing**: `go_router` with `StatefulShellRoute.indexedStack` for bottom tab persistence and deep linking
- **Design Language**: Editorial Neo-Brutalist (Bone paper `#FBFAF6`, Signal Orange `#FF5A1F`, crisp 2px ink borders, `Bricolage Grotesque`, `Instrument Sans`, `Space Mono`)

### 2. Backend & Spatial Database
- **Primary Backend**: [Supabase](https://supabase.com) (PostgreSQL 15, Auth, Storage, Edge Functions)
- **Geospatial Engine**: PostGIS `GEOGRAPHY(Point, 4326)` with GiST spatial indexing for real-time radius searching (`ST_DWithin`, `ST_Distance`)
- **Privacy Enforcement**: PostgreSQL Row Level Security (RLS) guaranteeing that friends-only drops are never queried or leaked to strangers.
- **Push & Diagnostics**: Firebase Cloud Messaging (FCM) + Firebase Crashlytics.

---

## 🔒 Dual-Layer Privacy Invariant

The core architecture strictly separates **Friends-Only Drops** from **Public Reviews**:

```sql
-- PostgreSQL Row Level Security Policy (supabase/migrations/00002_row_level_security.sql)
CREATE POLICY posts_select_dual_layer ON posts
  FOR SELECT USING (
    -- Author always has access to their own drops
    author_id = auth.uid()
    OR (
      -- Strangers can only read public drops if not blocked
      audience = 'public'
      AND NOT is_blocked(auth.uid(), author_id)
    )
    OR (
      -- Friends-only drops require mutual/accepted friendship
      audience = 'friends'
      AND are_friends(auth.uid(), author_id)
      AND NOT is_blocked(auth.uid(), author_id)
    )
  );
```

---

## 📁 Repository Structure

```
around/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                     # Automated static analysis, linter & test runner
│   │   └── mobile-release.yml         # iOS Fastlane & Android AAB release train
│   ├── PULL_REQUEST_TEMPLATE.md       # Standard PR checklist and DoR/DoD
│   └── ISSUE_TEMPLATE/                # Bug report and Feature proposal templates
├── assets/                            # Curated high-res venue photography & icons
├── docs/
│   ├── standards/
│   │   ├── COLLABORATION_STANDARDS.md # RACI matrix, Trunk-Based Development, code review SLAs
│   │   ├── DELIVERY_PROCESS.md        # Release train, test pyramid, staged rollout (10%->100%)
│   │   └── PRIVACY_AND_SAFETY_GOVERNANCE.md # Zero tracking, moderation SLAs, GDPR erasure
│   ├── adr/
│   │   ├── 001-mobile-architecture.md # Mobile stack decision: Flutter + Supabase + PostGIS
│   │   └── 002-dual-layer-privacy-model.md # Server-side RLS privacy invariant
│   └── research/
│       └── TASHKENT_MAP_PROVIDER_EVALUATION.md # Yandex MapKit vs. Google Places in Tashkent
├── lib/
│   ├── core/
│   │   ├── constants/app_colors.dart  # Palette tokens (Paper, Ink, Signal Orange, Butter)
│   │   ├── errors/app_failure.dart    # Domain failure & error handling models
│   │   ├── routing/app_router.dart    # GoRouter configuration with StatefulShellRoute
│   │   └── theme/app_theme.dart       # Typography & neo-brutalist theme configuration
│   ├── data/
│   │   ├── models/                    # Place, Post, Profile, SavedPlace data classes
│   │   ├── repositories/              # PlacesRepository, PostsRepository, SavedPlacesNotifier
│   │   └── services/                  # HapticService, SupabaseService
│   ├── features/
│   │   ├── auth/                      # Onboarding walkthrough
│   │   ├── create_post/               # 4-step Drop wizard (Photo, Place, Note, Audience)
│   │   ├── explore/                   # City map with live vector pins & venue list
│   │   ├── feed/                      # Friends Feed bento grid, stories, caught-up state
│   │   ├── places/                    # Venue page (split stats, quote, drops switcher)
│   │   ├── profile/                   # User profile, drops, social graph
│   │   ├── saved_places/              # Saved shortlist, filters, friend plans
│   │   └── settings/                  # Privacy controls, default audience, GDPR export
│   └── main.dart                      # App entry point with ProviderScope & GoRouter
├── supabase/
│   └── migrations/
│       ├── 00001_initial_schema.sql   # PostGIS schema, canonical places, drops & friendships
│       ├── 00002_row_level_security.sql # PostgreSQL RLS policies & privacy functions
│       └── 00003_postgis_functions.sql  # get_nearby_places stored procedure
└── test/
    ├── unit/
    │   ├── post_privacy_test.dart     # Verifies privacy isolation (friends vs public)
    │   ├── places_repository_test.dart# Verifies spatial & category filtering
    │   └── saved_places_test.dart     # Verifies bookmarks & plan toggles
    ├── widget/
    │   └── bento_card_test.dart       # BentoCard rendering & badge verification
    └── widget_test.dart               # Full App navigation smoke test
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.24.0`)
- [Dart SDK](https://dart.dev) (`>= 3.5.0`)
- Optional: Supabase CLI (`brew install supabase/tap/supabase` or `npm install -g supabase`)

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/around-app/around.git
   cd around
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Unit and Widget Tests**:
   ```bash
   flutter test
   ```

4. **Run the App in Debug Mode**:
   ```bash
   # Android emulator or connected device
   flutter run -d android

   # iOS simulator (macOS required)
   flutter run -d ios

   # Chrome preview
   flutter run -d chrome
   ```

---

## 🗺 Tashkent Launch & Map Provider Strategy

For our initial rollout community in Tashkent (Barlow Hill / Mirabad / Yakkasaray districts):
- **Place Ownership**: All place records are canonical and owned in our PostgreSQL database (`places` table).
- **Evaluation**: See [`TASHKENT_MAP_PROVIDER_EVALUATION.md`](file:///docs/research/TASHKENT_MAP_PROVIDER_EVALUATION.md) for the comparative benchmark between **Yandex MapKit** (best local coverage for Uzbek cafés and mahalla alleys) and **Google Places API** (international standard).

---

## 🤝 Team Collaboration Standards & Release Train

Please review our delivery guidelines before submitting contributions:
- [Collaboration Standards & RACI Matrix](file:///docs/standards/COLLABORATION_STANDARDS.md)
- [Delivery Process & Test Pyramid](file:///docs/standards/DELIVERY_PROCESS.md)
- [Privacy & Safety Governance](file:///docs/standards/PRIVACY_AND_SAFETY_GOVERNANCE.md)
- [Engineering Handbook Artifact](file:///C:/Users/User/.gemini/antigravity/brain/239483d3-7044-411b-aaf7-10ead7f2adaf/engineering-handbook-and-delivery-guide.md)

---

## 📄 License
Released under the [MIT License](file:///LICENSE).
