---
name: task-loop-executor
description: Selects the next unblocked task from tasks.json, implements the full vertical slice across Supabase and Flutter/React, and runs the self-correcting verification loop.
---

# Task Loop Executor Skill

## Step 1: Select Next Unblocked Task
1. Read `tasks.json` and `AGENTS.md`.
2. Find the first task with `"status": "IN_PROGRESS"`, `"READY"`, or `"BACKLOG"` where all IDs in `"dependencies"` have `"status": "DONE"`.
3. Update that task's status to `"IN_PROGRESS"` in `tasks.json`.

## Step 2: Implement the Vertical Slice
1. **Database Layer**: If the task requires schema or RPC updates, create the next sequential migration in `supabase/migrations/` and append RLS verification assertions to `supabase/tests/rls_authorization_test.sql`.
2. **Application Layer**: Implement or update the repository, state provider, and UI screen in `lib/features/` (and `src/` if web-applicable) following the task's `acceptance_criteria`.
3. **Test Layer**: Add unit/widget tests in `test/` covering success, empty, and error states.

## Step 3: Self-Correcting Rework Loop (Max 3 Iterations)
Run the verification suite:
```bash
flutter analyze --fatal-infos --fatal-warnings
flutter test
npm run lint && npm test
```
- If **any command fails**: inspect the stack trace or analyzer output, fix the root cause in code, and re-run the suite before proceeding. Do NOT mark the task `DONE` while any check fails.
- If **all commands pass**: mark the task `"status": "DONE"` in `tasks.json`, update `PRODUCT_CAPABILITIES.md`, and commit the slice on a feature branch or current working branch.
