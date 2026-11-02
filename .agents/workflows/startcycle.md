---
description: Polsia-style autonomous product audit, backlog generation, iterative build, and shipping loop
---

# /startcycle — Polsia-Style Continuous Autonomous Company Loop

NEVER declare the company or repository "100% DONE" and stop. Execute this continuous 5-stage loop:

1. **Stage 1 — Check Queue or Run Product/UX/Growth Discovery**:
   - Inspect `tasks.json` for any task with `"status": "IN_PROGRESS"`, `"READY"`, or `"BACKLOG"` whose dependencies are `"DONE"`.
   - **If ZERO unblocked tasks exist**:
     1. Act as the **Adversarial Product Critic & Growth Lead**: inspect `lib/features/`, `src/`, and `supabase/` to identify the next 3–4 highest-value product features, UX polish improvements, growth/viral loops (e.g., referral links, shareable city cards, taste onboarding, localization), or backend hardening tasks, and write them to `CRITIQUE_REPORT.md`.
     2. Act as the **Autonomous CEO**: append those 3–4 new tasks as the next Phase (`P11-01`..`P11-04`, `P12-01`.., etc.) into `tasks.json`, log the strategy in `COMPANY_PULSE.md`, and commit (`chore(ceo): replenish Phase P<N> backlog`).

2. **Stage 2 — Implement One Vertical Slice (`task-loop-executor`)**:
   - Mark the first unblocked task `"IN_PROGRESS"` in `tasks.json`.
   - Implement the full vertical slice across SQL migrations, Flutter (`lib/`), React (`src/`), and unit/widget tests (`test/`).

3. **Stage 3 — Iterative Self-Healing Verification Gate**:
   - Run `flutter analyze --fatal-infos --fatal-warnings`, `flutter test`, and `npm run lint && npm test -- --run`.
   - If any command fails, inspect the exact error output, fix the code, and re-run until green (up to 4 rework iterations).

4. **Stage 4 — Ship Slice & Immediately Loop**:
   - Mark the task `"DONE"` in `tasks.json`, append the shipped summary to `COMPANY_PULSE.md`, and `git commit` + `git push` to `origin/main`.
   - **Immediately continue to Stage 1** for the next task (and if the milestone just finished, runStage 1's Product Critic + CEO replenishment to start the next Phase immediately).
