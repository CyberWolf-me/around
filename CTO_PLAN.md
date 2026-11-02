# Around — CTO Engineering Plan: Production Hardening, Architecture & Scale

**Author:** CTO & Architecture Lead  
**Date:** November 2, 2026  
**Status:** Active — Phase 12 Technical Execution  
**Branch:** `feat/phase-12-strava-for-places`  
**Prerequisites:** Aligns directly with `CEO_PLAN.md` and `COMPETITIVE_ANALYSIS.md`

---

## 0. Technical Architecture & Invariants

### 0.1 The "Strava for Places" Architectural Shift
1. **Thin Place Anchor Layer:** Places in our schema (`places` table) act as spatial anchors and canonical references for user-generated social artifacts (Drops, Stories, Plans, Saves). We resolve external directory IDs and slugs via `PlacesRepository.resolveCanonicalId` without attempting to replicate an exhaustive Yelp/Yandex directory.
2. **Social-First & Feed-First Core:** The mobile experience prioritizes the chronological and friends-first feed, story rail, taste passports, and collaborative plans. The interactive map serves as an exploratory canvas rather than a utility navigator.
3. **Telemetry That Powers Future B2B Analytics (Option B Runway):** All event logging in `AnalyticsService` captures privacy-preserving venue engagement (saves, shares, view counts, peak atmosphere affinity) so that the B2B venue analytics platform (Phase 12D) has rich, longitudinal historical data from Day 1.

---

## 1. Workstream Breakdown & Deliverables

### 1.1 Mobile Engineering Workstream

| Task ID | Title | Scope & Affected Paths | Acceptance Criteria |
|---|---|---|---|
| **P12-01** (CTO-M06) | Environment Configuration Architecture | `lib/core/config/app_config.dart`, `lib/data/services/supabase_service.dart`, `.env.example`, `.env.staging`, `.env.production` | Seamless switching across `dev`, `staging`, and `production` via `--dart-define=ENV=...`. Service role key strictly prohibited. |
| **P12-02** (CTO-M02 / A01) | Production Analytics & Venue Telemetry Service | `lib/core/services/analytics_service.dart`, `lib/core/services/app_logger.dart`, `test/unit/analytics_service_test.dart` | 12 core funnel & social events instrumented (signup, drop_created, place_saved, plan_created, etc.). Captures venue affinity metrics for future B2B portal. |
| **P12-03** (CTO-M03) | First-Run Onboarding Redesign (Social & Privacy Focused) | `lib/features/auth/screens/onboarding_screen.dart`, `lib/core/routing/app_router.dart`, `test/widget/onboarding_screen_test.dart` | 3-step interactive flow: (1) "Discover Through Friends", (2) "Drop a Place & Choose Your Circle", (3) "Pick District & Invite Friends". |
| **P12-04** (CTO-M15) | Telegram Social Graph & Invite Loop Integration | `lib/core/services/telegram_share_service.dart`, `lib/features/profile/screens/friend_invite_screen.dart`, `test/unit/telegram_share_service_test.dart` | One-tap native Telegram invite link generation, share sheet payload formatting, and web deep link handler. |
| **P12-05** (CTO-M09) | Actionable Empty States & Error Resilience UX | `lib/core/widgets/empty_state_widget.dart`, `lib/features/feed/screens/feed_screen.dart`, `lib/features/saved_places/screens/saved_screen.dart` | Thoughtful empty states with clear CTAs for feed, saved places, and network errors. Zero blank views. |

### 1.2 Backend & Database Workstream

| Task ID | Title | Scope & Affected Paths | Acceptance Criteria |
|---|---|---|---|
| **P12-06** (CTO-B04) | Production Scale Composite Indexes | `supabase/migrations/00011_production_indexes.sql` | Composite indexes on `posts(place_id, audience, is_quarantined, created_at DESC)`, `saved_places(user_id, status)`, `friendships(user_id, status)`, and `place_stories(place_id, expires_at)`. |
| **P12-07** (CTO-B05 / S01) | Production RLS Security & Rate-Limit Audit | `supabase/tests/rls_authorization_test.sql`, `supabase/migrations/00012_rate_limit_expansion.sql` | Verification of all 57 RLS policies under production load. Triggers enforce comment (20/5m), reaction (50/5m), and friend-request (20/day) limits. |
| **P12-08** (CTO-B18) | Aggregated Venue Analytics Views (Option B Foundation) | `supabase/migrations/00013_venue_analytics_foundation.sql` | Materialized/SQL views aggregating place drop counts, unique friend visitors, save intent, and peak atmosphere hours without exposing PII. |

---

## 2. Execution Sequence & Dependencies

```
[P12-01: AppConfig Environment Separation]
      │
      ├───► [P12-02: Analytics & Venue Telemetry Engine]
      │           │
      │           └───► [P12-03: First-Run Onboarding Redesign]
      │                       │
      │                       └───► [P12-04: Telegram Invite & Share Engine]
      │                                   │
      │                                   └───► [P12-05: Actionable Empty States]
      │
      └───► [P12-06: Production Composite Indexes Migration]
                  │
                  └───► [P12-07: RLS Rate Limit & Security Hardening]
                              │
                              └───► [P12-08: Aggregated Venue Analytics Views]
```

---

## 3. Definition of Done for Phase 12

1. **Static Analysis & Compilation:** Zero analyzer warnings (`flutter analyze --fatal-infos --fatal-warnings`) and zero TypeScript compiler issues (`npx tsc --noEmit`).
2. **Automated Verification:** 100% of unit, widget, and RLS tests pass with non-empty assertions.
3. **Security Invariant:** PostgreSQL RLS dual-layer visibility and `auth.uid()` derivation preserved unconditionally. Zero `service_role` keys in client code.
4. **Documentation & Tracking:** `tasks.json` and `COMPANY_PULSE.md` updated with verified evidence and test counts.
