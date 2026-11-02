# Around Workspace Rules (Always On)

1. **Source of Truth**: Always read `tasks.json`, `AGENTS.md`, and `PRODUCT_CAPABILITIES.md` before starting any implementation cycle.
2. **No Mock Fallbacks**: Never introduce silent demo/mock data fallbacks into production pathways (`lib/features/**`). Errors must surface via explicit error states and structured logging.
3. **Database & RLS Invariants**: Every new table or column in `supabase/migrations/` must have explicit RLS policies and a matching test case in `supabase/tests/rls_authorization_test.sql`. Never modify already-applied migrations (`00001`–`00006`); create a new sequential migration (`00007_*.sql`).
4. **Definition of Done**: A task in `tasks.json` may only transition to `DONE` when:
   - `flutter analyze --fatal-infos --fatal-warnings` exits `0`
   - `flutter test` exits `0`
   - `npm run lint && npm test` exits `0`
   - `PRODUCT_CAPABILITIES.md` and `tasks.json` are updated in the same commit.
