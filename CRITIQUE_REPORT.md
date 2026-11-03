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


---

# Around — Adversarial Product, UX & Growth Critique Report (Phase 19 Audit)

**Audit Date**: November 3, 2026  
**Auditor Personas**: CTO & Autonomous Loop Orchestrator, Growth & Retention Lead, Senior Product Engineer  
**Target Milestone**: Phase 19 — Trophy Cabinet, Venue Rhythm Sparklines, Web Haptic Audio & Taste Circle Suggestions  
**Branch**: `feat/phase-12-strava-for-places`  

## Executive Summary & Strategic Position

With Phase 18 fully delivered (tagged `v1.8.0-staging.1`):
- **225 / 225 Flutter tests** passing with zero errors.
- **41 / 41 Web Vitest tests** passing with zero errors.
- **0 static analysis warnings** across all Dart & TypeScript code.

### The Adversarial Growth Audit

1. **Scattered Achievements Without a Unified Showcase**:
   - Curators earn District Crowns, Discovery Streak Badges, and Quest Medals, but they are scattered across different screens.
   - **Remedy**: Build `TrophyCabinetWidget` in `lib/features/profile/widgets/trophy_cabinet_widget.dart` on `TastePassportScreen` providing a filterable trophy case for unlocked & locked accolades.

2. **Static Place Details Lack Temporal Rhythm**:
   - When deciding where to go, curators need to know when a venue is most active with friends.
   - **Remedy**: Create `VenueRhythmSparkline` on `PlaceDetailScreen` showing 24-hour activity distribution and peak atmosphere indicators.

3. **Web Companion Audio Synthesizer Not Yet Wired to Interactive UI**:
   - `soundEffects.ts` was implemented in Phase 18, but key interactive web components (star ratings, audience toggles, share buttons) need direct integration with `playSoundWithHaptic`.
   - **Remedy**: Connect audio-tactile feedback into web components and verify with Vitest.

4. **Cold Social Discovery: Lack of Taste-Based Curator Recommendations**:
   - Curators currently rely solely on manual invite links to find friends.
   - **Remedy**: Build `CuratorRecommendationEngine` in `lib/core/services/curator_recommendation_engine.dart` suggesting mutual friends and curators with overlapping neighborhood tastes in Tashkent.

---

## Phase 19 Backlog Roadmap (`tasks.json`)

### `P19-01`: Curator Trophy Cabinet & Achievement Grid Widget
- **Domain**: Gamification & Reputation
- **Owner**: Mobile Engineering
- **Deliverables**: `TrophyCabinetWidget` on `TastePassportScreen` displaying filterable grid of District Crowns, Streak Badges, and Quest Medals.

### `P19-02`: Venue Rhythm Sparkline & Peak Atmosphere Indicator
- **Domain**: Places Catalog & Intelligence
- **Owner**: Mobile Engineering
- **Deliverables**: `VenueRhythmSparkline` widget on `PlaceDetailScreen` displaying 24h activity curve, friend drop density, and peak hours.

### `P19-03`: Web Companion Audio-Tactile UI Component Integration
- **Domain**: Social Graph & Distribution
- **Owner**: Web Companion Engineer
- **Deliverables**: Connect `playSoundWithHaptic` into `AudienceBadge`, `StarRating`, and `PassportShareModal` with Vitest assertions.

### `P19-04`: Curator Mutual Discovery & Taste Overlap Engine
- **Domain**: Social Graph & Engagement
- **Owner**: Core Engineering
- **Deliverables**: `CuratorRecommendationEngine` in `lib/core/services/curator_recommendation_engine.dart` computing taste similarity and mutual neighborhood overlap.


---

## Phase 20 Sprint Audit — Taste Compatibility UI, Sunday Retrospective Dialog, Web Leaderboard & Outbox Sync Bus

### `P20-01`: User Profile Taste Compatibility Card & Mutual Match Widget
- **Domain**: Social Graph & Engagement
- **Owner**: Flutter & Web Product Engineer
- **Deliverables**: `CuratorTasteOverlapCard` on `UserProfileScreen` utilizing `CuratorRecommendationEngine` to compute and display live taste match score (e.g. "86% Taste Match"), shared favorite spots, and localized overlap highlights.

### `P20-02`: Sunday Retrospective Celebration Modal & Streak Rescue CTA
- **Domain**: Gamification & Retention
- **Owner**: Flutter & Web Product Engineer
- **Deliverables**: `WeeklyRetrospectiveModal` on `FeedScreen` triggering during the Sunday retrospective window (or streak at-risk period), celebrating weekly milestones or presenting an urgent "Save Streak with a Drop" action.

### `P20-03`: Web Companion District Crown Leaderboard & Local Legend Showcase
- **Domain**: Social Graph & Distribution
- **Owner**: Web Companion Engineer
- **Deliverables**: `CuratorLeaderboard.tsx` in `src/components/` rendering district crown holders, streak rankings, and direct passport link previews with Vitest tests.

### `P20-04`: Reactive Offline Outbox Sync Bus & Network Reconnection Flush
- **Domain**: Resilience & Offline Experience
- **Owner**: Core Engineering
- **Deliverables**: `OfflineOutboxSyncBus` in `lib/core/services/offline_outbox_sync_bus.dart` listening to connectivity pulses and automatically flushing queued drops with localized status callbacks.


---

## Autonomous Product Audit & Replenishment — Phase 21 (November 3, 2026)

### Strategic Evaluation: Milestone 2.0 Complete & Viral Social Density
With Phase 20 successfully delivered and released as `v2.0.0-staging.1` (248 Flutter tests, 53 Web tests, zero static analysis warnings), Around has transitioned from basic place check-ins to an active social habit engine.

However, to convert discovery into real-world social meetups and prevent streak churn, Phase 21 introduces 4 critical mechanisms:

1. **Curator Mutual Coffee Match & Telegram Invite Sheet (`P21-01`)**:
   - When curators discover high taste overlap on `UserProfileScreen`, provide an instant tactile action sheet to coordinate a coffee meetup at their shared top venue on Telegram (`t.me/<handle>` pre-filled deep link).
2. **Explorer Streak Freeze Shield & Grace Period Engine (`P21-02`)**:
   - Provide retention protection inspired by Strava/Duolingo: active curators who log ≥3 drops in a week bank an automatic "Streak Freeze Shield". When Sunday reflection expires with zero drops, the shield is consumed to protect the explorer's multi-week streak from resetting.
3. **Web Companion Live Place Atmosphere Heatmap & Rhythm Tracker (`P21-03`)**:
   - Port the 24-hour urban rhythm sparkline into the Web Companion (`PlaceRhythmHeatmap.tsx`) with peak atmosphere badges, hour selection, and direct mobile app deep links.
4. **Curator Milestone & Trophy In-App Notification Dispatcher (`P21-04`)**:
   - Reactive milestone notification dispatcher (`CuratorNotificationService`) issuing in-app notifications and haptic alerts when curators unlock achievements, level up streaks, or secure district crowns.


---

## Autonomous Product Audit & Replenishment — Phase 22 (November 3, 2026)

### Strategic Evaluation: Milestone 2.1 Complete & Urban Metro Navigation
With Phase 21 successfully delivered and released as `v2.1.0-staging.1` (267 Flutter tests, 59 Web tests, zero static analysis warnings), Around has solidified its core taste discovery, streak preservation, and in-app milestone triggers.

However, to ground Around deeply into the physical geography of Tashkent and solve group coordination, Phase 22 introduces 4 high-value capabilities:

1. **Tashkent Subway Station Proximity & Transit Landmark Beacon (`P22-01`)**:
   - In Tashkent, residents and curators locate spots by their nearest metro station ("Kosmonavtlar", "Oybek", "Mustaqillik Maydoni", "Amir Timur Xiyoboni", "Chorsu", etc.).
   - `SubwayProximityEngine` calculates geodesic distance to all key Tashkent metro stations across the Chilonzor, O'zbekiston, and Yunusobod lines, providing walking estimates and line badge indicators.
2. **Curator Group Meetup Coordination Sheet & Multi-Friend Telegram RSVPs (`P22-02`)**:
   - Extends 1-on-1 coffee pings to small groups (3-6 curators) for weekend brunches and coffee study sessions, generating pre-formatted group coordination links with RSVP tracking.
3. **Web Companion Metro Landmark Filter & Station Quick-Jump (`P22-03`)**:
   - Introduces `MetroStationFilter.tsx` to the web companion, allowing quick venue discovery along major subway transit hubs with audio-tactile click feedback.
4. **Cryptographic Drop Anti-Tamper & Verified Visit Seal Engine (`P22-04`)**:
   - Solidifies the "Strava for Places" guarantee by signing drops on-device with cryptographic hashes and displaying a "Verified Visit" seal on authentic local drops.


---

## Autonomous Product Audit & Replenishment — Phase 23 (November 3, 2026)

### Strategic Evaluation: Milestone 2.2 Complete & Curator Progression
With Phase 22 delivered and tagged as `v2.2.0-staging.1` (286 Flutter tests, 67 Web tests, zero static analysis warnings), Around features subway transit integration, group meetups, web station filters, and cryptographic drop verification.

To further deepen the Strava/Duolingo gaming loop and reward persistent explorers in Tashkent, Phase 23 establishes the full Curator Level Progression system:

1. **Curator Badging & Level Progression Engine (`P23-01`)**:
   - Computes XP from verified drops, multi-week streaks, and district crown holds.
   - Maps total XP to 4 progressive tiers: `Neighborhood Scout` (Tier 1), `District Curator` (Tier 2), `City Pioneer` (Tier 3), and `Tashkent Legend` (Tier 4) with trilingual titles and unlockable border flairs.
2. **Interactive Curator Level Badge & XP Progress Bar Widget (`P23-02`)**:
   - `CuratorLevelBadgeWidget` on `ProfileScreen` and `TastePassportScreen` rendering live XP meters, current level badge, and points needed to reach the next tier.
3. **Web Companion Curator Level & Tier Showcase Component (`P23-03`)**:
   - `CuratorLevelBadge.tsx` displaying the curator's tier badge and level details with audio-tactile click feedback.
4. **Offline Cache Telemetry & Subway Sync Diagnostics (`P23-04`)**:
   - Diagnostics service monitoring offline cache hit performance, underground subway commute connectivity loss, and post-reconnection sync latency.


---

## Autonomous Product Audit & Replenishment — Phase 24 (November 3, 2026)

### Strategic Evaluation: Milestone 2.3 Complete & Personal City Exploration Heatmaps
With Phase 23 delivered and tagged as `v2.3.0-staging.1` (302 Flutter tests, 74 Web tests, zero static analysis warnings), Around has established the 4-tier Curator XP progression system.

To take the "Strava for Places" metaphor to its ultimate expression in Tashkent, Phase 24 establishes Personal City Coverage:

1. **Curator City District Coverage Engine (`P24-01`)**:
   - Calculates the curator's personal exploration coverage across Tashkent's 5 key districts (Mirabad, Central Tashkent, Yakkasaray, Old City, Yunusabad) based on verified drops and saved places.
   - Generates completion percentages, district badges, and recommends the next unvisited gem in under-explored districts.
2. **Interactive District Coverage Card & Exploration Overlay Widget (`P24-02`)**:
   - `DistrictCoverageCard` in `lib/features/explore/widgets/district_coverage_card.dart` mounted on `ExploreScreen` and `TastePassportScreen` displaying animated district progress bars and tactile district filter taps.
3. **Web Companion Personal City Coverage Meter (`P24-03`)**:
   - `DistrictCoverageMeter.tsx` in `src/components/` rendering responsive district progress rings and Web Audio tactile haptics.
4. **Supabase SQL Schema & District Leaderboard RPC Migration (`P24-04`)**:
   - `00013_curator_levels_and_district_leaderboard.sql` adding `curator_xp`, `curator_tier`, and `curator_level` to `profiles`, alongside idempotent RPC `get_curator_leaderboard` with PostGIS RLS authorization assertions.


---

## Autonomous Product Audit & Replenishment — Phase 25 (November 3, 2026)

### Strategic Evaluation: Milestone 2.4 Complete & Curated Multi-Stop City Crawls
With Phase 24 delivered and tagged as `v2.4.0-staging.1` (317 Flutter tests, 80 Web tests, zero static analysis warnings), Around has established the 5-district personal coverage system and Supabase curator leaderboard migration.

### The Adversarial Growth Audit for Phase 25:
In Tashkent, people don't explore venues in isolation. Social life revolves around curated multi-stop itineraries:
- "The Mirabad Specialty Coffee Crawl" (Breadly -> Socials -> Ekler)
- "The Chorsu Heritage Food Trail" (Chorsu Bread Bakers -> Lamb Skewers Alley -> Samarkand Darvoza)
- "Central Tashkent Cultural & Evening Promenade" (Amir Temur Square -> TIMS Roastery -> Afsona)

Currently, users have to assemble these stops manually. In Strava, athletes follow segments and courses. In Around, curators should be able to create, share, and follow **Curated Multi-Stop Crawls & Walking Routes** with:
1. Ordered venue waypoints, estimated walking time, and nearest Tashkent Metro station connectors.
2. Step-by-step progress tracking that verifies each stop via check-ins and awards a "Route Finisher" XP bonus.
3. Interactive route timeline visualization in both the Flutter app and React web companion.
4. Supabase SQL migration creating `curated_routes` and `route_completions` tables with an atomic completion RPC.

### Phase 25 Work Breakdown:
1. **Curated City Walking Crawls & Route Itinerary Engine (`P25-01`)**:
   - `CuratedRouteEngine` in `lib/core/services/curated_route_engine.dart` computing route distance, walking minutes, metro connectors, and stop completion state.
2. **Interactive Multi-Stop Route Map & Itinerary Card Widget (`P25-02`)**:
   - `CuratedRouteCard` and `RouteStopTimelineWidget` in `lib/features/explore/widgets/curated_route_card.dart` rendering step-by-step stop timelines with transit badges.
3. **Web Companion Interactive Itinerary Preview & Stop Navigator (`P25-03`)**:
   - `CuratedRouteNavigator.tsx` in `src/components/` rendering interactive multi-stop route timelines with audio-tactile haptic feedback.
4. **Supabase SQL Schema & Shared Route Completion RPC Migration (`P25-04`)**:
   - `00016_curated_routes_and_crawl_completions.sql` adding `curated_routes` and `route_completions` tables, with idempotent RPC `complete_curated_route` rewarding 150 curator XP upon verifying all stops.


---

## Autonomous Product Audit & Replenishment — Phase 26 (November 3, 2026)

### Strategic Evaluation: Milestone 2.5 Complete & Group Crawl Live Beacons
With Phase 25 delivered and tagged as `v2.5.0-staging.1` (335 Flutter tests, 86 Web tests, zero static analysis warnings), Around has established the curated walking routes and multi-stop crawl engine.

### The Adversarial Growth Audit for Phase 26:
In Tashkent, people almost never do coffee crawls or culinary food walks alone—they go with 2–4 close friends or colleagues.
Currently, routes can only be tracked individually. There is no collective group experience:
- Friends have no way to synchronize their progress along a crawl route.
- If Kamila arrives at Breadly 10 minutes earlier than Bekzod, there is no in-app signal showing where the rest of the group is without exchanging clumsy Telegram chat messages ("Where are you guys?").
- If a group completes a crawl together, they should receive a collective **"Squad Finisher" XP Multiplier** (+200 XP).

Crucially, this must respect our non-negotiable **Rule C & Dual-Layer Privacy Invariant**:
- We NEVER stream or broadcast continuous raw GPS coordinates.
- Presence is signaled solely via explicit venue check-in tokens (`current_place_id`) associated with the active crawl stop.

### Phase 26 Work Breakdown:
1. **Group Crawl Session & Collective Route Progress Engine (`P26-01`)**:
   - `GroupCrawlSessionEngine` in `lib/core/services/group_crawl_session_engine.dart` managing session codes (`CRAWL-XXXX`), participant states, collective stop progress, and squad completion qualification.
2. **Interactive Group Crawl Radar & Live Presence HUD Widget (`P26-02`)**:
   - `GroupCrawlRadarHUD` in `lib/features/explore/widgets/group_crawl_radar_hud.dart` displaying friend avatars placed along the route stops, collective completion percentage, and join modal.
3. **Web Companion Group Crawl Live Beacon & Room Viewer (`P26-03`)**:
   - `GroupCrawlRoomViewer.tsx` in `src/components/` rendering real-time group crawl participants, stop badges, and Web Audio tactile feedback.
4. **Supabase SQL Schema & Group Crawl Session RPC Migration (`P26-04`)**:
   - `00017_group_crawl_sessions_and_live_beacons.sql` creating session tables, RLS participant isolation, and idempotent `join_or_update_group_crawl` RPC.


---

## Autonomous Product Audit & Replenishment — Phase 27 (November 3, 2026)

### Strategic Evaluation: Milestone 2.6 Complete & Curator Postcard Engine
With Phase 26 delivered and tagged as `v2.6.0-staging.1` (351 Flutter tests, 90 Web tests, zero static analysis warnings), Around has established the group crawl session and live presence beacon system.

### The Adversarial Growth Audit for Phase 27:
In Strava, the viral distribution flywheel is driven by the post-workout activity card: runners and cyclists share high-contrast graphics featuring their route map, pace, and segment PRs to Instagram Stories and Strava clubs.
Currently in Around, when a curator checks in at Breadly or completes the Mirabad Coffee Crawl, their achievement stays trapped within the app:
- Curators in Tashkent love sharing aesthetic food photography and coffee receipts to Telegram channels and Instagram Stories.
- Without a native, branded **Curator Visit Postcard & Cultural Receipt Generator**, Around misses its #1 organic growth channel (viral visual exports).
- The postcard must combine:
  1. The venue name and district stamp.
  2. The cryptographic verified visit seal (`AR-XXXX-XXXX`).
  3. The curator's level tier badge and total Tashkent XP.
  4. Nearest Tashkent Metro station beacon.
  5. Perforated editorial receipt styling fitting the Around visual design language.

### Phase 27 Work Breakdown:
1. **Curator Visit Postcard & Cultural Receipt Engine (`P27-01`)**:
   - `CuratorPostcardEngine` in `lib/core/services/curator_postcard_engine.dart` computing postcard metadata, aesthetic theme palettes, stamp text, and receipt formatting.
2. **Interactive Curator Postcard & Visual Stamp Exporter Widget (`P27-02`)**:
   - `CuratorPostcardCard` in `lib/features/explore/widgets/curator_postcard_card.dart` rendering the aesthetic paper receipt with perforated borders, seal stamp, and Telegram share actions.
3. **Web Companion Curator Postcard Generator & Story Styler (`P27-03`)**:
   - `CuratorPostcardGenerator.tsx` in `src/components/` rendering interactive postcard previews with 1:1 vs 9:16 aspect ratio toggling and audio-tactile haptic feedback.
4. **Supabase SQL Schema & Postcard Share Telemetry RPC Migration (`P27-04`)**:
   - `00018_curator_postcards_and_viral_telemetry.sql` adding `postcard_shares` table with RLS and idempotent RPC `record_postcard_share` awarding `+25 XP`.


---

## Autonomous Product Audit & Replenishment — Phase 28 (November 3, 2026)

### Strategic Evaluation: Milestone 2.7 Complete & Monthly Seasons / Trophy Wall
With Phase 27 delivered and tagged as `v2.7.0-staging.1` (367 Flutter tests, 95 Web tests, zero static analysis warnings), Around has shipped the viral curator postcard and cultural receipt engine.

### The Adversarial Growth Audit for Phase 28:
In Strava, the core retention mechanism that keeps athletes coming back month after month is **Monthly Challenges & Trophy Badges** (e.g. "November 50k Running Challenge", "Gran Fondo Trophy").
Without monthly resets:
1. All-time leaderboards inevitably stagnate. Early adopters who accumulated 5,000+ XP become permanently uncatchable, creating high churn among new users joining in Tashkent.
2. Curators need fresh monthly objectives (e.g., *Autumn in Tashkent: Discover 5 new tea & coffee spots in Mirabad*, *Subway Explorer: Check in along Chilanzar Line*).
3. Hard-earned monthly accomplishments must be permanently memorialized on a **Trophy Wall** on the user's profile and taste passport.

### Phase 28 Work Breakdown:
1. **Monthly Curator Seasons & Trophy Engine (`P28-01`)**:
   - `SeasonTrophyEngine` in `lib/core/services/season_trophy_engine.dart` computing current season timeframe, monthly active challenges, trophy qualification rules, and localized trophy narratives.
2. **Interactive Season Trophy Wall Widget (`P28-02`)**:
   - `SeasonTrophyCard` in `lib/features/explore/widgets/season_trophy_card.dart` rendering seasonal challenge progress rings, gold/silver/bronze trophy badges, and countdown timer to season rollover.
3. **Web Companion Season Standings & Trophy Showcase (`P28-03`)**:
   - `SeasonTrophyShowcase.tsx` in `src/components/` rendering interactive trophy showcase, filter by season month, and Web Audio celebration sounds.
4. **Supabase SQL Schema & Seasonal Snapshot RPC Migration (`P28-04`)**:
   - `00019_curator_seasons_and_trophy_wall.sql` creating `seasonal_trophies` table with RLS and idempotent `claim_seasonal_trophy` RPC.
