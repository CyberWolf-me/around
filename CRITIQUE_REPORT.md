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


---

# Phase 16 Audit — District Leaderboard UI, TWA BackButton Navigation, Low-Bandwidth Image Cache & Ambient Friend Presence

**Audit Date**: November 3, 2026  
**Auditor Personas**: CTO & Autonomous Loop Orchestrator, Growth & Viral Mechanics Lead, Senior Mobile Engineer  
**Target Milestone**: Phase 16 — Social Competition, Telegram Navigation, Network Resilience & Ambient Presence  
**Branch**: `feat/phase-12-strava-for-places`  

## Executive Summary & Strategic Position

With Phase 15 fully delivered (Weekend Rhythm UI, Multi-Axis Taste Radar, Telegram MainButton Bridge, and District Legend Engine, tagged `v1.5.0-staging.1`):
- **186 / 186 Flutter tests** passing with zero errors.
- **31 / 31 Web Vitest tests** passing with zero errors.
- **0 static analysis warnings** across all Dart & TypeScript code.

### The Adversarial Growth Audit

1. **Unsurfaced Local Legend Status in Mobile UI**:
   - `DistrictLegendEngine` (`P15-04`) calculates who reigns supreme in each district, but the mobile profile and taste passport don't visually render the `👑 Local Legend` crown badge or a district leaderboard sheet where users can see rankings and fight for the top spot.
   - **Remedy**: Create `DistrictLeaderboardCard` and profile crown flair displaying neighborhood rankings and drops needed to claim the crown.
2. **Telegram Mini App BackButton & Direct Place Share**:
   - Inside Telegram Mini Apps, Android hardware back buttons or Telegram header back buttons should seamlessly close sheets or navigate back to the discovery grid without exiting the bot.
   - **Remedy**: Wire `Telegram.WebApp.BackButton` into `src/services/telegramWebApp.ts` and `src/router.tsx`.
3. **Uzbekistan Cellular Network Resilience & Image Caching**:
   - Mobile network latency across Tashkent subway lines and basements causes repeated image reloads.
   - **Remedy**: Build `LowBandwidthImageCache` ensuring venue photos and story assets are stored in memory and local app storage with instant offline fallback.
4. **Ambient Friend Presence & Social Momentum**:
   - Users need immediate visual cues that friends are actively exploring Tashkent.
   - **Remedy**: Implement `FriendPresenceEngine` computing ambient activity badges ("Active today in Mirabad", "Dropped 2h ago at Breadly") without revealing exact private coordinates.

---

## Phase 16 Backlog Roadmap (`tasks.json`)

### `P16-01`: District Leaderboard & Local Legend Profile Crown Flair
- **Domain**: Gamification & Reputation
- **Owner**: Mobile Engineering
- **Deliverables**: `DistrictLeaderboardSheet` and `LocalLegendBadge` widgets displaying Tashkent neighborhood rankings, crown flair, and drop count progress.

### `P16-02`: Telegram WebApp Native BackButton & Modal Navigation Bridge
- **Domain**: Social Graph & Distribution
- **Owner**: Web Companion Engineer
- **Deliverables**: Wire `Telegram.WebApp.BackButton` lifecycle and deep-linked place sharing into `src/services/telegramWebApp.ts` and `src/router.tsx` with Vitest test assertions.

### `P16-03`: Low-Bandwidth Asset Cache & Subway Offline Image Store
- **Domain**: Platform & Performance
- **Owner**: Mobile Engineering
- **Deliverables**: `LowBandwidthCacheService` with memory caching, cache eviction, and offline placeholder fallback for low-connectivity subway commutes in Tashkent.

### `P16-04`: Ambient Friend Presence & Neighborhood Rhythm Indicator
- **Domain**: Social Graph & Engagement
- **Owner**: Mobile Engineering
- **Deliverables**: `FriendPresenceEngine` computing recency and neighborhood activity indicators for friend cards without raw GPS leakage.

---

# Around — Adversarial Product, UX & Growth Critique Report (Phase 17 Audit)

**Audit Date**: November 3, 2026  
**Auditor Personas**: CTO & Autonomous Loop Orchestrator, Growth & Retention Lead, Senior Product Engineer  
**Target Milestone**: Phase 17 — Ambient Presence Rail, Neighborhood Map Pulse, Web Share & Explorer Streaks  
**Branch**: `feat/phase-12-strava-for-places`  

## Executive Summary & Strategic Position

With Phase 16 fully delivered (tagged `v1.6.0-staging.1`):
- **204 / 204 Flutter tests** passing with zero errors.
- **32 / 32 Web Vitest tests** passing with zero errors.
- **0 static analysis warnings** across all Dart & TypeScript code.

### The Adversarial Growth Audit

1. **Ambient Presence Is Computed but Unsurfaced in Mobile Feed**:
   - `FriendPresenceEngine` (`P16-04`) calculates ambient recency and neighborhood presence badges without GPS leakage, but the mobile Feed screen lacks a visual horizontal avatar rail showing friends active today in Mirabad or Yunusabad.
   - **Remedy**: Build `FriendPresenceRail` with pulse indicators and district chips at the top of `FeedScreen`.

2. **Map Lacks Real-Time Neighborhood Social Heat**:
   - Curators opening the Map screen need to know at a glance which Tashkent district is buzzing with activity tonight.
   - **Remedy**: Create `NeighborhoodPulseBanner` integrating `FriendPresenceEngine.getNeighborhoodFriendCounts` to display aggregate friend counts per district and allow 1-tap district filtering.

3. **Web Companion Needs 1-Tap Telegram Social Share**:
   - When a friend receives a link to a place or taste passport on Telegram, they open `src/`. The web companion must offer a native Telegram share card with pre-formatted invite text for forwarding to friends and group chats.
   - **Remedy**: Implement `PassportShareModal` and native Telegram share URL builder in the web companion.

4. **Retention Engine: Weekly Explorer Streak**:
   - Strava's weekly mileage streak is the ultimate retention driver. For Around in Tashkent, curators should build consecutive weekly discovery streaks by logging ≥1 drop or visit each week.
   - **Remedy**: Implement `ExplorerStreakEngine` computing consecutive active weeks, longest streak, and awarding streak badges ("🔥 3-Week Explorer").

---

## Phase 17 Backlog Roadmap (`tasks.json`)

### `P17-01`: Friend Presence Rail & Ambient Social Avatar Ring
- **Domain**: Social Graph & Engagement
- **Owner**: Mobile Engineering
- **Deliverables**: `FriendPresenceRail` widget for `FeedScreen` displaying active friends, online pulse rings, and neighborhood badges.

### `P17-02`: Neighborhood Social Pulse Map Banner & District Heat Filter
- **Domain**: Places Catalog & Intelligence
- **Owner**: Mobile Engineering
- **Deliverables**: `NeighborhoodPulseBanner` on the map screen showing live district friend clusters and enabling quick zoom to active neighborhoods.

### `P17-03`: Web Companion Telegram Direct Share & Passport Link Generator
- **Domain**: Social Graph & Distribution
- **Owner**: Web Companion Engineer
- **Deliverables**: `PassportShareModal` in `src/components/PassportShareModal.tsx` with native Telegram share URL builder and Vitest test assertions.

### `P17-04`: Weekly Discovery Streak & Sunday Retrospective Engine
- **Domain**: Gamification & Retention
- **Owner**: Core Engineering
- **Deliverables**: `ExplorerStreakEngine` in `lib/core/services/explorer_streak_engine.dart` computing weekly active streaks and badge awards with unit tests.


---

# Around — Adversarial Product, UX & Growth Critique Report (Phase 18 Audit)

**Audit Date**: November 3, 2026  
**Auditor Personas**: CTO & Autonomous Loop Orchestrator, Growth & Retention Lead, Senior Product Engineer  
**Target Milestone**: Phase 18 — Streak Profile Flair, Sunday Retrospectives, Web Micro-Sounds & Crown Rivalry  
**Branch**: `feat/phase-12-strava-for-places`  

## Executive Summary & Strategic Position

With Phase 17 fully delivered (tagged `v1.7.0-staging.1`):
- **213 / 213 Flutter tests** passing with zero errors.
- **36 / 36 Web Vitest tests** passing with zero errors.
- **0 static analysis warnings** across all Dart & TypeScript code.

### The Adversarial Growth Audit

1. **Explorer Streak Is Computed but Unsurfaced in Profile Screen**:
   - `ExplorerStreakEngine` (`P17-04`) computes consecutive discovery weeks and milestone badges, but the user profile and taste passport don't visually show the flame counter (`🔥 4-Week Explorer`) or countdown days remaining before streak expiration.
   - **Remedy**: Create `StreakProgressCard` in `lib/features/profile/widgets/streak_progress_card.dart` and embed on `ProfileScreen`.

2. **Missing Sunday Evening Retrospective Loop**:
   - Sunday evening (18:00–21:00 Tashkent time) is the optimal window to celebrate weekly discoveries or warn curators whose streak is at risk.
   - **Remedy**: Build `SundayRetrospectiveService` in `lib/core/services/sunday_retrospective_service.dart` generating retrospective alerts and notifications.

3. **Telegram Mini App Companion Lacks Audio-Tactile Micro-Feedback**:
   - The web companion in `src/` has haptics, but lacks subtle audio feedback on button taps, story views, and bookmark clicks, dampening the sensory experience.
   - **Remedy**: Implement `soundEffects.ts` Web Audio API synthesizer in `src/services/soundEffects.ts` with Vitest test assertions.

4. **Friendly Competition: Crown Usurpation & Rivalry Engine**:
   - The ultimate motivation in Strava is defending your Local Legend crown against friends.
   - **Remedy**: Build `CrownRivalryEngine` in `lib/core/services/crown_rivalry_engine.dart` detecting when a friend takes the lead in a Tashkent district and alerting the previous crown holder.

---

## Phase 18 Backlog Roadmap (`tasks.json`)

### `P18-01`: Profile Streak Progress Card & Milestone Flame Flair
- **Domain**: Gamification & Retention
- **Owner**: Mobile Engineering
- **Deliverables**: `StreakProgressCard` widget on `ProfileScreen` displaying consecutive week flame counter, progress toward next badge, and days remaining.

### `P18-02`: Sunday Evening Social Digest & Retrospective Trigger Engine
- **Domain**: Social Graph & Engagement
- **Owner**: Core Engineering
- **Deliverables**: `SundayRetrospectiveService` generating localized weekly discovery digests and at-risk streak alerts with unit tests.

### `P18-03`: Web Companion Audio-Tactile Sound Effects Synthesizer
- **Domain**: Social Graph & Distribution
- **Owner**: Web Companion Engineer
- **Deliverables**: Web Audio API sound generator in `src/services/soundEffects.ts` with volume controls, haptic sync, and Vitest test assertions.

### `P18-04`: District Crown Rivalry & Usurpation Notification Engine
- **Domain**: Gamification & Reputation
- **Owner**: Backend & Mobile Engineering
- **Deliverables**: `CrownRivalryEngine` in `lib/core/services/crown_rivalry_engine.dart` detecting district leader changes and generating friendly rivalry notifications.
