# Around — Adversarial Product, UX & Growth Critique Report (Phase 13 Audit)

**Audit Date**: November 3, 2026  
**Auditor Personas**: CTO & Autonomous Loop Orchestrator, Senior Spatial Engineer, Tashkent Growth Lead  
**Target Milestone**: Phase 13 — City Taste Quests, Spatial Privacy Density & Telegram Mini App Bridge  
**Branch**: `feat/phase-12-strava-for-places`  

---

## Executive Summary & Strategic Position

With Phase 12 fully delivered (10 milestones across Launch Readiness and Closed Beta Cohort Activation, tagged `v1.2.0-staging.1`):
- **146 / 146 Flutter tests** passing with zero errors.
- **21 / 21 Web Vitest tests** passing with zero errors.
- **0 static analysis warnings** across all Dart & TypeScript code.
- **50 curated Tashkent venues** with PostGIS coordinates across 5 central districts.
- **Closed beta VIP code gate** (`TASH50`, `MIRAB1`, `YAKK02`, etc.) active.
- **Telegram preview meta tags** and deep link routing bridge live.

### The Adversarial Growth Audit

Now that our closed beta cohort (Tashkent 50) is entering the product, the primary operational threat shifts from *initial onboarding* to **habitual weekly retention & social proof**:

1. **Lack of Inherent "Strava-Like" Progress & Motivation**:
   - In Strava, runners don't just log miles; they hunt Segments, build weekly streaks, and earn "Local Legend" status.
   - In Around, visiting 3 artisan bakeries in Mirabad or tasting plov across Old City currently gives no progressive milestone feedback or collectible city badge.
   - **Remedy**: Introduce curated **Tashkent Taste Quests** ("Mirabad Specialty Coffee Trail", "Old City Plov Connoisseur", "Evening Jazz & Wine Circuit") with unlockable badge flair displayed on Taste Passports and profiles.

2. **Map Lacks Visual Aggregate Social Heat**:
   - The map displays static venue pins, but gives no visceral sense of where friends or locals are clustering right now.
   - However, showing exact real-time GPS locations violates our non-negotiable **dual-layer privacy invariant**.
   - **Remedy**: Implement privacy-preserving **Venue Activity Heatmap & District Density Clusters** aggregating drop activity by district and venue without exposing precise user timestamps or raw coordinates.

3. **Telegram Friction in Uzbekistan**:
   - 90%+ of our target demographic in Tashkent lives in Telegram. When an invite link or passport link is opened on a mobile device, users prefer an immediate Telegram WebApp (TWA) overlay rather than breaking context to open external Safari/Chrome browsers.
   - **Remedy**: Integrate Telegram WebApp (TWA) SDK hooks and viewport bridges into `src/` to provide an instant interactive preview within Telegram chats.

4. **Cryptographic Privacy & GDPR Data Erasure Guarantee**:
   - Trust is our core differentiator against massive directories like Yandex Maps. To back up our privacy promises, users must have an unambiguous, single-tap cryptographic visit history purge RPC (`purge_my_visit_history`) that immediately zeros out their sensitive places history in both database and device cache.

---

## Phase 13 Backlog Roadmap (`tasks.json`)

### `P13-01`: Tashkent City Taste Quests & Local Legend Badges
- **Domain**: `Gamification & Retention`
- **Owner**: `Flutter & Web Product Engineer`
- **Deliverables**:
  - `QuestModel` & `QuestsRepository` managing curated city discovery trails (e.g., Mirabad Coffee Crawl, Old City Heritage Plov, Botanical Evening Stroll).
  - Progress tracking engine based on saved places, drops, and verified visits.
  - Interactive Quest Sheet and unlockable profile badge flair.
  - Comprehensive unit and widget tests.

### `P13-02`: Privacy-Preserving Venue Activity Heatmap & District Density Engine
- **Domain**: `Spatial Data & Discovery`
- **Owner**: `Backend & Security Engineer`
- **Deliverables**:
  - PostGIS aggregation function `get_district_activity_density` calculating anonymous drop counts per Tashkent district over sliding 7-day windows.
  - Flutter map overlay displaying soft ambient heat rings around active neighborhoods without exposing individual user identities or raw coordinates.
  - SQL authorization assertions and unit tests.

### `P13-03`: Telegram WebApp (TWA) Mini App Bridge & Direct Invite Injection
- **Domain**: `Social Graph & Distribution`
- **Owner**: `Flutter & Web Product Engineer`
- **Deliverables**:
  - `src/services/telegramWebApp.ts` supporting Telegram WebApp initialization, theme synchronization (`tg.themeParams`), and viewport auto-expansion.
  - Automatic cohort invite token detection from `Telegram.WebApp.initDataUnsafe.start_param`.
  - Vitest test suite for TWA launch parameters.

### `P13-04`: Cryptographic Visit History Purge RPC & Zero-Knowledge Self-Destruct
- **Domain**: `Trust & Safety`
- **Owner**: `Backend & Security Engineer`
- **Deliverables**:
  - Migration `00013_visit_history_purge.sql` with `SECURITY DEFINER` RPC `purge_my_visit_history()`.
  - Atomic deletion of all user visit logs, reactions, and check-ins while preserving account integrity.
  - UI action in `SettingsScreen` with double confirmation and haptic warning.
  - pgTap and Dart unit tests.


---

# Phase 14 Audit — Viral Social Story Cards, Multilingual Search, District Heat Navigation & Weekly Rhythm Digest

**Audit Date**: November 3, 2026  
**Auditor Personas**: CTO & Autonomous Loop Orchestrator, Product Growth Lead, Senior Mobile Engineer  
**Target Milestone**: Phase 14 — Viral Social Proof, Multilingual Spatial Intelligence & Map Heat Navigation  
**Branch**: `feat/phase-12-strava-for-places`  

## Executive Summary & Strategic Position

With Phase 13 fully delivered (Taste Quests, District Density RPC, Telegram TWA SDK, and Cryptographic Purge, tagged `v1.3.0-staging.1`):
- **161 / 161 Flutter tests** passing with zero errors.
- **30 / 30 Web Vitest tests** passing with zero errors.
- **0 static analysis warnings** across all Dart & TypeScript code.

### The Adversarial Growth Audit

1. **Map Exploration Friction**:
   - `DistrictDensityOverlay` was engineered and tested, but users on `ExploreScreen` and `CityMapWidget` still lack a direct toggle between Venue Pins and District Social Heat rings with smooth camera fly-to animations when tapping a district chip.
2. **Multilingual Uzbek Cyrillic/Latin & Russian Search Invariant**:
   - In Uzbekistan, users query venues using Latin Uzbek (`Choyxona`), Cyrillic Uzbek (`Чойхона`), Russian (`Чайхана`), and English (`Tea House`). A naive substring match fails when users type Cyrillic characters into Latin catalog fields. We must implement a bidirectional transliteration & multilingual fuzzy normalizer in `PlacesRepository.searchPlacesMultilingual`.
3. **Viral Social Story Cards for Telegram & Instagram**:
   - In Tashkent, youth and young professionals share discoveries on 9:16 Telegram and Instagram Stories. Users need a high-aesthetic, branded story card exporter widget rendering venue photo, user drop quote, rating, district badge, and Around watermark.
4. **Local Weekly Rhythm Digest & Weekend Social Re-engagement**:
   - Strava drives Sunday evening engagement via weekly summaries. In Tashkent, Friday evening ("Juma oqshomi") and Saturday morning are the prime socializing peaks. We need `WeeklyDigestEngine` to aggregate weekly neighborhood stats and generate notification digests for weekend planning.

---

## Phase 14 Backlog Roadmap (`tasks.json`)

### `P14-01`: Map District Heat Integration & Smooth Centroid Navigation
- **Domain**: Spatial Data & Discovery
- **Owner**: Mobile Engineering
- **Deliverables**: Wire `DistrictDensityOverlay` into `ExploreScreen` and `CityMapWidget`, animating camera center to district centroids with haptic feedback.

### `P14-02`: Multilingual Cyrillic/Latin Uzbek & Russian Spatial Search Normalizer
- **Domain**: Places Catalog & Intelligence
- **Owner**: Mobile Engineering & Core Engineering
- **Deliverables**: Implement `searchPlacesMultilingual` in `PlacesRepository` supporting bidirectional Uzbek Cyrillic-to-Latin transliteration and Russian category synonyms.

### `P14-03`: Viral Story & Passport Card Visual Exporter (9:16 Story Canvas)
- **Domain**: Social Graph & Distribution
- **Owner**: Flutter & Web Product Engineer
- **Deliverables**: Tactical 9:16 story preview widget with clipboard export and deep link QR for Telegram and Instagram Stories.

### `P14-04`: Local Weekly Rhythm Digest & Weekend Social Re-engagement Trigger
- **Domain**: Retention & Engagement
- **Owner**: Mobile Engineering
- **Deliverables**: `WeeklyDigestEngine` computing weekly district drop volumes, peak atmosphere hours, and inviting friends to weekend meetups.


---

# Phase 15 Audit — Weekend Rhythm Feed UI, Taste Radar Visualization, Telegram MainButton Integration & District Tastemaker Badges

**Audit Date**: November 3, 2026  
**Auditor Personas**: CTO & Autonomous Loop Orchestrator, Growth & Viral Mechanics Lead, Senior Flutter Engineer  
**Target Milestone**: Phase 15 — Habitual Weekend Loops, Visual Taste Radar & Local Legend Leaderboards  
**Branch**: `feat/phase-12-strava-for-places`  

## Executive Summary & Strategic Position

With Phase 14 fully delivered (Map Heat Navigation, Multilingual Transliteration Engine, Viral 9:16 Story Exporter, and WeeklyDigestEngine, tagged `v1.4.0-staging.1`):
- **174 / 174 Flutter tests** passing with zero errors.
- **30 / 30 Web Vitest tests** passing with zero errors.
- **0 static analysis warnings** across all Dart & TypeScript code.

### The Adversarial Growth Audit

1. **Invisible Weekly Digest**:
   - `WeeklyDigestEngine` (`P14-04`) computes aggregate 7-day momentum and Friday/Saturday prompts, but users on `FeedScreen` have no visual UI card surfacing this insight during the weekend window.
   - **Remedy**: Create `WeeklyDigestBanner` widget on `FeedScreen` displaying weekly top district momentum and a one-tap "Gather Circle" Telegram invite trigger.
2. **Taste Passport Lacks Visual Metric Radar**:
   - Taste Passports track badge counts, but lack a visual multi-axis footprint (Coffee, Dining, Nightlife, Culture, Parks) analogous to Strava's training breakdown.
   - **Remedy**: Build `TasteRadarWidget` rendering dynamic category weight meters and culinary personality archetype ("Specialty Connoisseur", "Old City Nomad", etc.).
3. **Telegram WebApp Native UI Bridge**:
   - In `src/`, expand the Telegram Mini App bridge to wire Telegram's native bottom `MainButton` ("Share to Telegram Story / Friends") and `HapticFeedback` to place detail actions.
4. **District Tastemaker & Local Legend Mechanics**:
   - Build `DistrictLegendEngine` computing the top explorer for each Tashkent district over the rolling 30-day window, awarding visible "Local Legend" profile badge flair.

---

## Phase 15 Backlog Roadmap (`tasks.json`)

### `P15-01`: Weekend Rhythm Feed Banner & Social Coordination Sheet
- **Domain**: Retention & Engagement
- **Owner**: Mobile Engineering
- **Deliverables**: Tactile `WeeklyDigestBanner` mounted at the head of `FeedScreen` during weekend windows (Fri 16:00 – Sun 23:59), launching an interactive bottom sheet with top district stats and instant Telegram friend invite generator.

### `P15-02`: Multi-Axis Taste Radar & Explorer Archetype Engine
- **Domain**: Gamification & Retention
- **Owner**: Flutter & Web Product Engineer
- **Deliverables**: `TasteRadarWidget` in `TastePassportScreen` rendering category momentum bars, diversity ratio, and calculated explorer archetype with unit/widget tests.

### `P15-03`: Telegram WebApp Native MainButton & Haptic Bridge
- **Domain**: Social Graph & Distribution
- **Owner**: Web Companion Engineer
- **Deliverables**: Upgrade `src/services/telegramWebApp.ts` and `src/components/PlaceDetailModal.tsx` with native `Telegram.WebApp.MainButton` controls, clipboard link sync, and Vitest test assertions.

### `P15-04`: District Tastemaker & Rolling 30-Day Local Legend Engine
- **Domain**: Social Graph & Reputation
- **Owner**: Backend & Mobile Engineering
- **Deliverables**: `DistrictLegendEngine` computing per-district drop rankings and awarding "Mirabad Legend", "Old City Nomad", and "Yunusabad Pioneer" badges.
