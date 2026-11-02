---
description: Autonomous self-building and self-shipping development loop for Around
---

# /startcycle — Autonomous Build, Verify & Ship Loop

Execute the following multi-agent loop continuously until the targeted milestone in `tasks.json` has zero remaining tasks:

1. **Initialize Context (`CTO / Loop Orchestrator`)**:
   - Read `.antigravity/rules.md`, `.agents/agents.md`, and `tasks.json`.
   - Identify all tasks in the active milestone whose dependencies are `"DONE"`. If all tasks in the milestone are `"DONE"`, skip to Step 4 (`staging-shipper`).

2. **Execute Vertical Slice (`task-loop-executor` Skill)**:
   - Invoke the `task-loop-executor` skill as the **Backend & Security Engineer** and **Flutter & Web Product Engineer**.
   - Implement the selected task end-to-end across `supabase/`, `lib/`, `src/`, and `test/`.

3. **Adversarial QA & Rework Gate (`QA & Release Lead`)**:
   - Run `flutter analyze --fatal-infos --fatal-warnings`, `flutter test`, and `npm test`.
   - For UI changes, launch the local preview (`npm run dev` or `flutter run -d web-server`) and inspect the rendered view with the Antigravity Browser Agent to confirm zero console errors or broken layouts.
   - **Loop Condition**: If any check fails, return a defect list to Step 2 and repeat until green (up to 3 rework iterations per task).
   - Once green, update `tasks.json` (`"status": "DONE"`), update `PRODUCT_CAPABILITIES.md`, and create an atomic Git commit (`feat(<task-id>): <title>`).

4. **Continuous Loop or Ship (`staging-shipper` Skill)**:
   - If more unblocked tasks remain in the current milestone, recursively invoke `/startcycle` for the next task.
   - Once the milestone is complete, invoke the `staging-shipper` skill to push migrations, run `supabase/tests/rls_authorization_test.sql`, build the release artifact, and push to staging.
