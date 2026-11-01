# ROADMAP.md — Around Product & Platform Development Roadmap (Phases 0–8)

This roadmap organizes Around's development around **capability maturity across eight domains** (`Identity`, `Social Graph`, `Places`, `Experiences`, `Discovery`, `Collections`, `Trust & Safety`, `Engagement`) rather than disposable MVP milestones.

## Phase Summary & Maturity Status

| Phase | Focus | Priority | Exit Gate & Current Status |
|---|---|---|---|
| **Phase 0** | **Product Discovery & Architecture** | `P0` | **COMPLETE:** `PRODUCT.md`, `PRODUCT_CAPABILITIES.md`, `PRODUCT_PRINCIPLES.md`, `ARCHITECTURE.md`, and `docs/adr/003-frontend-stack-decision.md` ratified; Flutter (`lib/`) selected as canonical mobile stack. |
| **Phase 1** | **Repository Recovery & Stabilization** | `P0` | **COMPLETE:** Purged committed `node_modules/`, fixed `SEC-01` (`get_friends_feed` `SECURITY INVOKER`) and `SEC-02` (`friendships_update_recipient_only`), unified Tashkent seed data (`supabase/seed.sql`), and configured native iOS/Android permissions. |
| **Phase 2** | **Platform & Backend Foundations** | `P0` | **COMPLETE:** Build-time `--dart-define` Supabase config (`.env.example`), `/auth` sign-up/sign-in/session lifecycle (`AuthScreen`), `on_auth_user_created` trigger, `post-media` Storage bucket RLS, and `AppLogger` observability. |
| **Phase 3** | **Core Connected Product** | `P1` | **COMPLETE:** PostGIS `get_nearby_places` & `FlutterMap` (`Places`), mutual friendship state machine (`Social Graph`), 4-step Drop creation + edit/delete (`Experiences`), dual-layer RLS (`Privacy`), Friends/Public feeds (`Discovery`), and Saved statuses + custom `collections` (`Collections`). |
| **Phase 4** | **Social Ecosystem & Engagement** | `P1` | **COMPLETE (Schema + Core Client):** Friend Plans (`friend_plans` + `friend_plan_participants` RSVP), 24-hour Venue Stories (`place_stories`), Drop reactions & comments (`post_reactions`, `post_comments`), and Activity Notifications (`notifications` + Quiet Hours). |
| **Phase 5** | **Trust, Safety & Community Operations** | `P1` | **COMPLETE:** Bidirectional blocking (`blocks`), content reporting (`reports`), 3-report automated quarantine (`handle_post_report_quarantine`), auditable moderation log (`moderation_audit_logs`), GDPR JSON export, and server-side `delete_own_account()` RPC. |
| **Phase 6** | **Intelligent Discovery & Personalization** | `P2` | **COMPLETE:** Explainable, privacy-preserving venue recommendation engine (`get_recommended_places` RPC in `00006` + `PlacesRepository.getRecommendedPlaces`) scoring venues by accepted friends' drops, category affinity, and rating without leaking private visits. |
| **Phase 7** | **Platform Maturity & Release Readiness** | `P1` | **COMPLETE:** Unit, widget, and SQL RLS regression suites (`supabase/tests/rls_authorization_test.sql`), GitHub Actions CI/CD (`.github/workflows/ci.yml`), DB rate-limiting triggers, and iOS `PrivacyInfo.xcprivacy` / Android store compliance. |
| **Phase 8** | **Continuous Product Evolution** | `Ongoing` | **ACTIVE LOOP:** Observe Tashkent cohort behavior → collect feedback → form hypotheses → prioritize in `tasks.json` → measure outcomes. |
