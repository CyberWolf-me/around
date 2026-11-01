# TASKS.md — Around Canonical Platform Task Board (Phases 0–8)

Synchronized with `tasks.json`. Organizes all engineering work across Around's **eight capability domains** (`Identity`, `Social Graph`, `Places`, `Experiences`, `Discovery`, `Collections`, `Trust & Safety`, `Engagement`) plus shared `Platform` infrastructure.

| ID | Phase | Domain | Title | Priority | Status | Affected Paths |
|---|---|---|---|---|---|---|
| **P0-01** | Phase 0 | `Platform` | Product Vision, Principles & 8-Domain Capability Mapping | `P0` | **DONE** | `PRODUCT.md`, `PRODUCT_CAPABILITIES.md`, `PRODUCT_PRINCIPLES.md`, `ROADMAP.md` |
| **P0-02** | Phase 0 | `Platform` | Frontend Architecture Evaluation & ADR 003 Ratification | `P0` | **DONE** | `docs/adr/003-frontend-stack-decision.md`, `docs/reports/PHASE_0_ARCHITECTURE_VALIDATION.md` |
| **P0-03** | Phase 0 | `Platform` | 8-Domain Entity-Relationship & Data Contract Architecture | `P0` | **DONE** | `ARCHITECTURE.md`, `AGENTS.md` |
| **P1-01** | Phase 1 | `Platform` | Repository Consolidation & Build Artifact Purge | `P0` | **DONE** | `.gitignore`, `README.md`, `.github/workflows/ci.yml` |
| **P1-02** | Phase 1 | `Trust & Safety` | Critical Database Security Remediation (`SEC-01` & `SEC-02`) | `P0` | **DONE** | `supabase/migrations/00002`, `00003`, `00005`, `supabase/tests/rls_authorization_test.sql` |
| **P1-03** | Phase 1 | `Places` | Application Stabilization & Canonical Tashkent Seed Alignment | `P0` | **DONE** | `lib/data/repositories/*.dart`, `supabase/seed.sql`, `analysis_options.yaml` |
| **P1-04** | Phase 1 | `Platform` | Native Mobile Foundation & Toolchain Constraints (`^3.5.0`) | `P0` | **DONE** | `pubspec.yaml`, `ios/Runner/Info.plist`, `PrivacyInfo.xcprivacy`, `AndroidManifest.xml` |
| **P2-01** | Phase 2 | `Platform` | Backend Infrastructure, Environment Config & Observability | `P0` | **DONE** | `supabase/config.toml`, `.env.example`, `supabase_service.dart`, `app_logger.dart` |
| **P2-02** | Phase 2 | `Identity` | Identity Lifecycle, Authentication & Profile Triggers | `P0` | **DONE** | `auth_screen.dart` (`/auth`), `profile_screen.dart`, `00004_triggers_and_storage.sql` |
| **P2-03** | Phase 2 | `Experiences` | Media Storage Infrastructure & Upload Lifecycle | `P0` | **DONE** | `00004_triggers_and_storage.sql`, `supabase_service.dart`, `app_image.dart`, `create_drop_sheet.dart` |
| **P3-01** | Phase 3 | `Places` | Geospatial Discovery, Search & Tashkent Map (`FlutterMap`) | `P1` | **DONE** | `00003_postgis_functions.sql`, `places_repository.dart`, `explore_screen.dart`, `place_detail_screen.dart` |
| **P3-02** | Phase 3 | `Social Graph` | Mutual Friendship State Machine & User Profiles (`/users/:id`) | `P1` | **DONE** | `profiles_repository.dart`, `user_profile_screen.dart`, `app_router.dart` |
| **P3-03** | Phase 3 | `Experiences` | Drop Creation, Editing (`editDrop`), Deletion (`deleteDrop`) & Rating Sync | `P1` | **DONE** | `create_drop_sheet.dart`, `posts_repository.dart`, `00004_triggers_and_storage.sql` |
| **P3-04** | Phase 3 | `Discovery` | Dual-Layer Feeds & Place Detail Partitioning | `P1` | **DONE** | `feed_screen.dart`, `place_detail_screen.dart`, `posts_repository.dart` |
| **P3-05** | Phase 3 | `Collections` | Saved Places (`want_to_go` / `been`) & Custom Curated Collections | `P1` | **DONE** | `saved_screen.dart`, `saved_places_repository.dart`, `collections_repository.dart`, `00006` |
| **P4-01** | Phase 4 | `Engagement` | Social Ecosystem: Notifications, Reactions, Comments, Friend Plans & 24h Stories | `P1` | **DONE** | `notifications_repository.dart`, `stories_repository.dart`, `comments_sheet.dart`, `bento_card.dart`, `story_rail.dart`, `00006` |
| **P5-01** | Phase 5 | `Trust & Safety` | Blocking, 3-Report Quarantine, Audit Logs & Server-Side `delete_own_account()` | `P1` | **DONE** | `00004`, `00005`, `00006`, `00008`, `settings_screen.dart`, `posts_repository.dart` |
| **P6-01** | Phase 6 | `Discovery` | Intelligent Discovery: Explainable Recommendations Surface | `P2` | **DONE** | `explore_screen.dart`, `places_repository.dart`, `00006_platform_domains_and_discovery.sql` |
| **P7-01** | Phase 7 | `Platform` | Platform Maturity, Hardened Staging, Credential Isolation & CI/CD Gates | `P1` | **DONE** | `00008`, `integration_test/`, `build.gradle.kts`, `key.properties.example`, `test/`, `docs/reports/` |
