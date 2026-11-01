# AGENTS.md — Around Engineering Governance & CTO Mandate

This document defines the operational rules, role responsibilities, and Definition of Done for all engineers and coding agents working on the **Around** repository.

## 1. Canonical Architecture & Source of Truth

- **Canonical Mobile Application:** Flutter (`lib/`, `pubspec.yaml`, `android/`, `ios/`), as ratified in `docs/adr/003-frontend-stack-decision.md`.
- **Backend & Spatial Database:** Supabase (PostgreSQL 15 + PostGIS + Row-Level Security + Supabase Storage) defined in `supabase/migrations/00001` through `00005`, `supabase/seed.sql`, and `supabase/tests/rls_authorization_test.sql`.
- **Reference Design Prototype:** `src/` (React/Vite) is retained strictly as an interactive design/stakeholder preview synchronized on the Tashkent dataset. Do not develop parallel features in `src/` that diverge from `lib/`.
- **Canonical Task Board:** `tasks.json` and `TASKS.md`.

## 2. Mandatory Pre-Implementation Checklist

Before implementing or modifying any feature, every agent or engineer must:
1. Read `PRODUCT.md`, `ARCHITECTURE.md`, `AGENTS.md`, and `docs/adr/001`–`003`.
2. Check `tasks.json` / `TASKS.md` to verify task dependencies and acceptance criteria.
3. Inspect the actual source files, SQL migrations, and existing tests before making assumptions.

## 3. Seven Non-Negotiable Execution Rules

- **Rule A — Verify Before Implementation:** Never trust documentation blindly. Verify actual Dart code, SQL policies, RPC signatures, and test assertions.
- **Rule B — Work Incrementally in Vertical Slices:** A feature is complete only when UI, repository state, Supabase backend integration, error handling, RLS authorization, and automated tests all work together.
- **Rule C — Security First:**
  - Never bypass PostgreSQL Row-Level Security (RLS) to make a feature work.
  - Never trust client-supplied user IDs (`requesting_user_id`); always derive caller identity from `auth.uid()` in SQL.
  - Never include a Supabase `service_role` key in mobile or web client code.
- **Rule D — No Fake Functionality:** No buttons that do nothing, no fake success toasts on failed network operations, no silent `catch (_) {}` blocks, and no hardcoded counters where live state is available.
- **Rule E — No Premature Abstractions:** Keep the Riverpod repository -> service -> model architecture clean and direct.
- **Rule F — Preserve Data Integrity:** Use canonical UUID identifiers in PostgreSQL and slug/UUID resolution in `PlacesRepository.resolveCanonicalId`. Always add corrective migrations (`00005_security_and_rls_remediation.sql`) rather than destructively breaking deployed environments.
- **Rule G — Evidence-Based Completion:** Every completed task must record modified files, verification commands executed, test outputs, and any remaining risks in `tasks.json`.

## 4. Role Ownership Matrix

| Role | Responsibility | Key Directories |
|---|---|---|
| **CTO / Orchestrator** | Architecture governance, ADR ratification, task sequencing, release gates | `AGENTS.md`, `ARCHITECTURE.md`, `tasks.json`, `docs/adr/` |
| **Backend Engineer** | PostgreSQL schema, PostGIS RPCs, triggers, Storage policies, seed data | `supabase/migrations/`, `supabase/seed.sql` |
| **Mobile Engineer** | Flutter screens, Riverpod notifiers, `go_router` navigation, native permissions | `lib/`, `ios/`, `android/`, `pubspec.yaml` |
| **QA Engineer** | Unit, widget, and SQL authorization test suites; CI/CD workflows | `test/`, `supabase/tests/`, `.github/workflows/` |
| **Security Reviewer** | Dual-layer privacy verification, RLS audit, rate-limiting, GDPR deletion | `docs/engineering/SECURITY_CHECKLIST.md`, `supabase/tests/` |

## 5. Definition of Done (DoD)

A task in `tasks.json` may transition to `DONE` only when:
1. All acceptance criteria are satisfied and verified in code.
2. Unit, widget, and SQL authorization tests pass with non-empty assertions.
3. Static analysis (`flutter analyze` and `npx tsc --noEmit`) passes with zero errors.
4. Security invariants (mutual friendship consent, `auth.uid()` binding, block precedence, and `hide_visits_history`) are enforced at both the database and repository layers.
5. Documentation and `tasks.json` are updated to reflect the verified state.
