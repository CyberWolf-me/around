# Around Workspace Rules (Always On)

1. **Source of Truth**: Always read `tasks.json`, `AGENTS.md`, and `PRODUCT_CAPABILITIES.md` before starting any implementation cycle.
2. **No Mock Fallbacks**: Never introduce silent demo/mock data fallbacks into production pathways (`lib/features/**`). Errors must surface via explicit error states and structured logging.
3. **Database & RLS Invariants**: Every new table or column in `supabase/migrations/` must have explicit RLS policies and a matching test case in `supabase/tests/rls_authorization_test.sql`. Never modify already-applied migrations (`00001`–`00006`); create a new sequential migration (`00007_*.sql`).
4. **Definition of Done**: A task in `tasks.json` may only transition to `DONE` when:
   - `flutter analyze --fatal-infos --fatal-warnings` exits `0`
   - `flutter test` exits `0`
   - `npm run lint && npm test` exits `0`
   - `PRODUCT_CAPABILITIES.md` and `tasks.json` are updated in the same commit.
5. **Rule H — Data Over Bespoke Engines (Anti-Bloat Guardrail)**:
   - NEVER create dedicated SQL tables, migrations, Dart services, or custom UI widgets for individual venue categories, cultural themes, food items, or crafts (e.g., tea pouring, bread stamping, paper burnishing, synth sequencers, coal heat monitors).
   - New city themes, trails, and cultural highlights must ALWAYS be represented as data rows inside existing `public.places`, `public.collections`, `public.collection_items`, and `public.curated_crawls` schemas.
6. **Rule I — Strict 4-Tab Surface & Complexity Cap**:
   - The app must maintain a maximum of 4 top-level tabs (`Feed`, `Explore`, `Saved`, `Profile`).
   - Before proposing any new task in `tasks.json`, the CEO Planner must verify whether an existing screen or table can support the use case via configuration or seed data, and must prioritize bug fixes, performance, localization (`UZ/RU/EN`), and test reliability over new UI widgets.

