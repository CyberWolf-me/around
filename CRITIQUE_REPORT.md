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
