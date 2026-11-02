# Around — CEO Strategic Plan: From Build to Launch

**Author:** CEO & Founder  
**Date:** November 2, 2026  
**Status:** Active — Phase 12 Strategy  
**Branch:** `feat/phase-12-strava-for-places`  
**Strategic Foundation:** Path A ("Strava for Places") with Path B Venue Analytics Monetization Runway

---

## 1. Situation Assessment

### What We Have Built (Phases 0–11)
- **Canonical Mobile App (Flutter):** 57 Dart source files across 8 capability domains.
- **Backend & Spatial Database (Supabase / PostGIS):** 10 versioned SQL migrations, Row-Level Security on every table, dual-layer privacy enforcement, and PostGIS spatial queries.
- **Verification Gate:** 97/97 Flutter tests passing, 16/16 Web Vitest tests passing, 0 compiler/analyzer warnings (`flutter analyze --fatal-infos --fatal-warnings`).
- **Feature Inventory:** Authentication, mutual friendship graph, PostGIS map discovery, Drop creation with EXIF metadata stripping, dual-layer RLS feeds, cursor-based pagination, saved places + custom collections, friend plans with RSVP, 24h venue stories, post reactions, threaded comments, Supabase Realtime broadcast channels, biometric app lock vault, deep link routing, offline outbox with exponential retry, Taste Passport profile cards, QR connection engine, time-of-day atmosphere engine, and trilingual Tashkent localization (UZ/RU/EN).

### The Reality
- Zero live users. Zero revenue. Zero App Store presence. 14 seed venues.
- The engineering foundation is battle-tested. The product must now reach real human hands.

---

## 2. Strategic Thesis: The "Strava for Places" Model

Around's moat is **trust-layered local social knowledge**. We do not compete with Yandex Maps or 2GIS on directory size or turn-by-turn navigation; they are infrastructure utilities.

Around is the social network for city life in Tashkent:
- **Feed-First UX:** The chronological social feed of friends' drops and plans is the primary experience.
- **Social Graph Primacy:** "Where did my close friends go, what did they order, and what are their honest ratings?"
- **Telegram Distribution:** Telegram is the universal communication fabric in Uzbekistan. Deep linking, share sheets, and Telegram friend discovery are our primary growth engines.
- **Data Monetization Runway (Option B):** Consumer usage produces high-intent spatial intelligence (saves, atmosphere peaks, visit patterns). This data will be aggregated and monetized in later phases as analytics subscriptions for Tashkent cafe and restaurant owners.

---

## 3. Four-Quarter Phase 12 Plan

### Phase 12A: Launch Readiness & Hardening (Weeks 1–4)
**Goal:** Make the app rock-solid, privacy-hardened, and shippable to real beta users.

| Initiative | Description | Owner | Success Criteria |
|---|---|---|---|
| Environment Configuration | Implement 3-tier config (`dev`, `staging`, `production`) in `AppConfig` via `--dart-define` | Mobile / Backend | Seamless project switching; zero secrets in client code |
| Crash & Telemetry Instrumentation | Integrate Crashlytics/Sentry and structured logging | Mobile Eng | Automatic crash reporting with breadcrumbs; <60s alert latency |
| Analytics Event Taxonomy | Instrument 12 core funnel & engagement events via `AnalyticsService` | Mobile / Data Eng | Funnel visibility: signup → onboarding → drop → friend → return; venue telemetry recorded |
| First-Run Onboarding Redesign | 3-screen flow: "Discover through friends" → "Drop a place & set circle" → "District & invites" | Mobile Eng | Onboarding completion <60s; completion rate >90% |
| Production Database Hardening | Composite indexes (`00011_production_indexes.sql`) & RLS audit | Backend Eng | `EXPLAIN ANALYZE` shows index scans; zero RLS leaks |
| Closed Beta Cohort | 50 Tashkent residents (specialty coffee community, university students) | Growth / Product | 50 active beta users with ≥3 mutual friendships each |

### Phase 12B: Go-to-Market & Telegram Loops (Weeks 5–8)
**Goal:** Public launch in Tashkent with organic social density.

| Initiative | Description | Owner | Success Criteria |
|---|---|---|---|
| Tashkent Public Launch | Open store registration; launch event at partner venue (e.g., Breadly) | Product / Growth | 500 signups in first week |
| Telegram Growth Loop | Native Telegram share sheet, invite links, and contact connect | Mobile Eng | 1.3 viral coefficient on new signups |
| Venue Partnership Pilot | 15 partner cafes with physical Around table cards / QR Taste Passports | Growth | 15 venues displaying Around QR codes |
| Push Notification Delivery | Supabase Edge Function + FCM/APNs push delivery for friend drops/plans | Backend / Mobile | Notification delivery latency <10s; 40% opt-in |

### Phase 12C: Growth & Retention (Weeks 9–16)
**Goal:** Turn signups into daily active city explorers.

| Initiative | Description | Owner | Success Criteria |
|---|---|---|---|
| Content Density & Atmosphere | Dynamic atmosphere pushes ("Morning Brew", "Golden Hour") | Product | 200+ organic drops created per week |
| Retention & Funnel Optimization | D1/D7/D30 cohort tracking via analytics dashboard | Data / Mobile | 30% Day-7 retention rate |
| Empty-State & Error UX | Actionable empty states for zero-friends, zero-saved, and offline | Mobile Eng | Zero blank screens; clear CTAs on every view |
| Community Moderation | Moderation queue review and quarantine management | Trust & Safety | Quarantine queue cleared daily; zero spam drops |

### Phase 12D: Scale & B2B Venue Analytics Monetization (Weeks 17–26)
**Goal:** Monetize aggregated analytics and expand footprint.

| Initiative | Description | Owner | Success Criteria |
|---|---|---|---|
| B2B Venue Analytics Portal | Self-service dashboard for cafe owners displaying foot-traffic affinity and saves | Backend / Growth | 10 paying venues ($20–$50/mo subscription) |
| Samarkand Regional Expansion | Seed regional hubs and local friend circles | Product / Growth | 100 active users and 25 partner venues in Samarkand |
| Around Plus Consumer Tier | Advanced collection curation and passport customization | Product | 50 paying consumer subscribers ($3/mo) |

---

## 4. Key Performance Targets (90 Days Post-Launch)

| Metric | Target | Current |
|---|---|---|
| Daily Active Users (DAU) | 500 | 0 |
| Total Registered Users | 2,000 | 0 |
| Organic Drops Created | 2,000 | 0 |
| Day-7 Retention Rate | 30% | N/A |
| Average Friendships Per User | 5 | 0 |
| Notification Opt-In Rate | 40% | 0% |
| App Store & Play Store Rating | ≥ 4.6 | Pre-release |

---

## 5. Budget & Capital Allocation

- **Phase 12A (Launch Readiness):** ~$200 (Supabase Pro + Apple/Google developer licenses)
- **Phase 12B (Go-to-Market):** ~$500 (Table cards, launch event, micro-influencer seeding)
- **Phase 12C (Growth & Telemetry):** ~$300 (Analytics infrastructure, community perks)
- **Phase 12D (Scale & B2B Portal):** ~$1,000 (Payment gateway integration, Samarkand launch)
- **Total Phase 12 Budget:** ~$2,000 (Self-funded through Phase 12C)
