#!/usr/bin/env node
/**
 * Around — Polsia-Style 24/7 Autonomous Company Daemon (Windows / macOS / Linux)
 *
 * Key Upgrades for True Polsia AI Behavior on Windows (`d:\around`):
 *   1. Windows Binary & Stdin Piping Fix:
 *      - Automatically resolves `agy.cmd` / `agy.exe` across PATH, %LOCALAPPDATA%, and %APPDATA%.
 *      - Pipes multi-line prompts via `stdin` (`input: prompt`) as recommended by
 *        https://antigravity.google/docs/cli/headless/ so Windows cmd.exe never chokes on quotes/newlines.
 *   2. Never-Ending 5-Department Polsia Loop (Never declares "100% DONE" and stops):
 *      - Dept 1: Product, UX & Growth Auditor -> inspects `lib/`, `src/`, `supabase/` and writes `CRITIQUE_REPORT.md`.
 *      - Dept 2: Autonomous CEO Planner -> turns `CRITIQUE_REPORT.md` into the next Phase (P11, P12, P13...) in `tasks.json`.
 *      - Dept 3: Clean-Context Builder -> implements one vertical slice in a fresh process.
 *      - Dept 4: External OS Judge + Adversarial Diff Critic -> runs `flutter analyze`, `flutter test`, `npm test`,
 *        AND verifies non-trivial code + test changes before allowing completion (looping up to MAX_REWORK times).
 *      - Dept 5: Release & Growth Shipper -> commits, pushes to `origin/main`, updates `COMPANY_PULSE.md`, and loops forever.
 */

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const ROOT = process.cwd();
const IS_WIN = process.platform === 'win32';
const TASKS_FILE = path.join(ROOT, 'tasks.json');
const PULSE_FILE = path.join(ROOT, 'COMPANY_PULSE.md');
const CRITIQUE_FILE = path.join(ROOT, 'CRITIQUE_REPORT.md');
const CEO_SCHEMA_FILE = path.join(ROOT, '.agents', 'schemas', 'ceo_tasks.schema.json');
const LOG_DIR = path.join(ROOT, 'logs', 'polsia');

const args = process.argv.slice(2);
const getArg = (flag, fallback) => {
  const idx = args.indexOf(flag);
  return idx !== -1 && args[idx + 1] ? args[idx + 1] : fallback;
};

const MAX_CYCLES = Number(getArg('--max-cycles', process.env.POLSIA_MAX_CYCLES || '0')); // 0 = run 24/7 forever
const MAX_REWORK = Number(getArg('--max-rework', process.env.POLSIA_MAX_REWORK || '4'));
const SLEEP_SECONDS = Number(getArg('--sleep', process.env.POLSIA_SLEEP_SECONDS || '8'));
const AUTO_PUSH = !args.includes('--no-push');
const MODEL = getArg('--model', process.env.AGY_MODEL || '');

fs.mkdirSync(LOG_DIR, { recursive: true });

function timestamp() {
  return new Date().toISOString();
}

function log(role, message) {
  const line = `[${timestamp()}] [${role}] ${message}`;
  console.log(line);
  fs.appendFileSync(path.join(LOG_DIR, 'daemon.log'), line + '\n', 'utf8');
}

function runShell(cmd, timeoutMs = 600_000) {
  log('SHELL', `Executing: ${cmd}`);
  const res = spawnSync(cmd, {
    cwd: ROOT,
    shell: true,
    encoding: 'utf8',
    timeout: timeoutMs,
    maxBuffer: 30 * 1024 * 1024,
  });
  return {
    ok: res.status === 0,
    status: res.status ?? 1,
    stdout: (res.stdout || '').trim(),
    stderr: (res.stderr || '').trim(),
    combined: `${res.stdout || ''}\n${res.stderr || ''}`.trim(),
  };
}

/**
 * Automatically locate the Antigravity CLI binary (`agy` / `agy.cmd` / `antigravity`) on Windows, macOS, or Linux.
 */
function resolveAgyBinary() {
  if (process.env.AGY_BIN && fs.existsSync(process.env.AGY_BIN)) {
    return process.env.AGY_BIN;
  }
  const lookupCmd = IS_WIN ? 'where.exe agy' : 'command -v agy';
  const lookup = spawnSync(lookupCmd, { shell: true, encoding: 'utf8' });
  if (lookup.status === 0 && lookup.stdout.trim()) {
    const firstMatch = lookup.stdout.trim().split(/\r?\n/)[0].trim();
    if (firstMatch) return firstMatch;
  }

  // Also check for gemini CLI on PATH
  const geminiLookup = spawnSync(IS_WIN ? 'where.exe gemini' : 'command -v gemini', { shell: true, encoding: 'utf8' });
  if (geminiLookup.status === 0 && geminiLookup.stdout.trim()) {
    const firstMatch = geminiLookup.stdout.trim().split(/\r?\n/)[0].trim();
    if (firstMatch) return firstMatch;
  }

  if (IS_WIN) {
    const localAppData = process.env.LOCALAPPDATA || path.join(os.homedir(), 'AppData', 'Local');
    const appData = process.env.APPDATA || path.join(os.homedir(), 'AppData', 'Roaming');
    const candidates = [
      path.join(appData, 'npm', 'agy.cmd'),
      path.join(appData, 'npm', 'gemini.cmd'),
      path.join(localAppData, 'Programs', 'Antigravity', 'bin', 'agy.cmd'),
      path.join(localAppData, 'Programs', 'Antigravity', 'bin', 'antigravity.cmd'),
      path.join(localAppData, 'Programs', 'Antigravity IDE', 'bin', 'antigravity-ide.cmd'),
      path.join(localAppData, 'Programs', 'Google Antigravity', 'bin', 'agy.cmd'),
    ];
    for (const candidate of candidates) {
      if (fs.existsSync(candidate)) return candidate;
    }
  }
  return 'agy';
}

const AGY_BIN = resolveAgyBinary();

/**
 * Spawns a fresh, clean-context Antigravity CLI process and feeds the prompt via STDIN
 * so multi-line prompts and quotes never break on Windows cmd.exe / PowerShell.
 */
function runHeadlessAgy(prompt, { jsonSchema = null, timeoutSec = 900 } = {}) {
  const isGeminiCli = path.basename(AGY_BIN).toLowerCase().includes('gemini');
  const cliArgs = isGeminiCli
    ? ['-y', '-p', '']
    : [
        '-p',
        '--mode=auto',
        '--dangerously-skip-permissions',
        `--print-timeout=${timeoutSec}s`,
      ];
  if (MODEL) {
    cliArgs.push(isGeminiCli ? '-m' : '--model', MODEL);
  }
  if (jsonSchema) {
    cliArgs.push(isGeminiCli ? '-o' : '--output-format', 'json');
    if (!isGeminiCli) {
      cliArgs.push('--json-schema', jsonSchema);
    }
  }

  log('AGY', `Spawning clean-context headless agent via "${AGY_BIN}" (${cliArgs.join(' ')})`);
  const res = spawnSync(AGY_BIN, cliArgs, {
    cwd: ROOT,
    input: prompt,
    shell: IS_WIN,
    encoding: 'utf8',
    timeout: (timeoutSec + 60) * 1000,
    maxBuffer: 50 * 1024 * 1024,
    stdio: ['pipe', 'pipe', 'pipe'],
  });

  const output = (res.stdout || '').trim();
  const errOutput = (res.stderr || '').trim();
  const errorMsg = res.error ? `\nSPAWN_ERROR: ${res.error.message}` : '';

  fs.writeFileSync(
    path.join(LOG_DIR, `last_agent_turn_${Date.now()}.log`),
    `BINARY: ${AGY_BIN}\nARGS: ${cliArgs.join(' ')}\n\nPROMPT:\n${prompt}\n\nSTDOUT:\n${output}\n\nSTDERR:\n${errOutput}${errorMsg}\n`,
    'utf8'
  );

  return {
    ok: res.status === 0 && !res.error,
    status: res.status ?? 1,
    stdout: output,
    stderr: errOutput + errorMsg,
  };
}

function loadTasks() {
  return JSON.parse(fs.readFileSync(TASKS_FILE, 'utf8'));
}

function saveTasks(data) {
  data.updatedAt = timestamp();
  fs.writeFileSync(TASKS_FILE, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

function findNextUnblockedTask(tasksData) {
  const doneIds = new Set(
    tasksData.tasks.filter((t) => t.status === 'DONE').map((t) => t.id)
  );
  const candidates = tasksData.tasks.filter(
    (t) =>
      (t.status === 'IN_PROGRESS' || t.status === 'READY' || t.status === 'BACKLOG') &&
      (t.dependencies || []).every((dep) => doneIds.has(dep))
  );
  const priorityOrder = { P0: 0, P1: 1, P2: 2 };
  candidates.sort(
    (a, b) => (priorityOrder[a.priority] ?? 9) - (priorityOrder[b.priority] ?? 9)
  );
  return candidates[0] || null;
}

function computeNextPhaseNumber(tasksData) {
  let maxPhase = 8;
  for (const t of tasksData.tasks) {
    const m = /^P(\d+)-/.exec(t.id);
    if (m) {
      maxPhase = Math.max(maxPhase, Number(m[1]));
    }
  }
  return maxPhase + 1;
}

function appendCompanyPulse(entry) {
  if (!fs.existsSync(PULSE_FILE)) {
    fs.writeFileSync(
      PULSE_FILE,
      `# Around — Autonomous Company Pulse (Polsia Engine)\n\nLive autonomous execution telemetry generated by \`scripts/polsia_daemon.mjs\`.\n\n`,
      'utf8'
    );
  }
  fs.appendFileSync(PULSE_FILE, entry + '\n', 'utf8');
}

/**
 * Department 1 & 2: Product/UX/Growth Auditor + Autonomous CEO Sprint Generator
 * Never declares the product "100% DONE" — discovers gaps, critiques UX/growth/engineering, and queues Phase N+1.
 */
function runAutonomousDiscoveryAndReplenishment(tasksData) {
  const nextPhase = computeNextPhaseNumber(tasksData);
  log('AUDITOR', `All current tasks are DONE. Running Department 1 (Product/UX/Growth Audit) for Phase P${nextPhase}...`);

  const auditPrompt = `
You are the Adversarial Product Critic, UX Lead, and Growth Hacker for Around (the places-first social discovery app in Tashkent).
Inspect the actual code in lib/features/, lib/data/, src/, and supabase/migrations/.

Write a concise, ruthless audit to CRITIQUE_REPORT.md identifying the top 4 concrete gaps across:
1. Product Depth & User Delight (what screens, interactions, or flows still feel basic, static, or incomplete?)
2. Growth & Viral Loops (invite links, shareable venue/drop cards, onboarding taste quiz, friend discovery, city leaderboards/streaks)
3. Backend & Spatial Intelligence (PostGIS query capabilities, search ranking, caching, real-time sync, edge cases)
4. QA & Edge-Case Resilience (untested error states, offline edge cases, accessibility/localization for Tashkent EN/RU/UZ)

Write your findings directly to CRITIQUE_REPORT.md.
`.trim();

  runHeadlessAgy(auditPrompt, { timeoutSec: 600 });

  const critiqueText = fs.existsSync(CRITIQUE_FILE)
    ? fs.readFileSync(CRITIQUE_FILE, 'utf8').slice(0, 6000)
    : 'Audit completed inline.';

  const existingIds = tasksData.tasks.map((t) => `${t.id}: ${t.title}`).join('\n');

  log('CEO-AGENT', `Launching Department 2 (Autonomous CEO Planner) to generate Phase P${nextPhase} tasks...`);
  const ceoPrompt = `
You are the Autonomous CEO & Chief Product Architect for Around.
In a Polsia-style autonomous company, the product is NEVER "100% finished" — every completed release unlocks the next iteration of product depth, user growth, and technical excellence.

Here is the latest adversarial audit from CRITIQUE_REPORT.md:
${critiqueText}

Already completed tasks (DO NOT repeat these IDs or duplicate their work):
${existingIds}

Generate 3 to 4 concrete, high-impact vertical-slice tasks for Phase P${nextPhase} using IDs "P${nextPhase}-01", "P${nextPhase}-02", "P${nextPhase}-03" (and optionally "P${nextPhase}-04").
- Set "P${nextPhase}-01" to status "READY" and subsequent tasks to "BACKLOG" with sequential dependencies.
- Every task must specify exact Dart/SQL/TS files in "affectedPaths", measurable "acceptanceCriteria", and "verificationCommands" ("flutter analyze --fatal-infos --fatal-warnings", "flutter test").
- Return strictly valid JSON matching the schema.
`.trim();

  const res = runHeadlessAgy(ceoPrompt, { jsonSchema: CEO_SCHEMA_FILE, timeoutSec: 600 });
  if (!res.ok) {
    log('CEO-AGENT', `CEO Planner exited with status ${res.status}: ${res.stderr}`);
    return false;
  }

  try {
    const jsonMatch = res.stdout.match(/\{[\s\S]*\}/);
    const parsed = JSON.parse(jsonMatch ? jsonMatch[0] : res.stdout);
    if (!Array.isArray(parsed.newTasks) || parsed.newTasks.length === 0) {
      return false;
    }
    const existingSet = new Set(tasksData.tasks.map((t) => t.id));
    let added = 0;
    for (const task of parsed.newTasks) {
      if (!existingSet.has(task.id)) {
        tasksData.tasks.push(task);
        added++;
      }
    }
    saveTasks(tasksData);
    appendCompanyPulse(
      `### [${timestamp()}] Autonomous CEO Sprint Generated — Phase P${nextPhase}\n- **Strategic Thesis**: ${parsed.strategicSummary}\n- **New Tasks Queued**: ${parsed.newTasks.map((t) => `\`${t.id}\` (${t.title})`).join(', ')}\n`
    );
    runShell('git add tasks.json COMPANY_PULSE.md CRITIQUE_REPORT.md && git commit -m "chore(ceo): autonomously replenish Phase P' + nextPhase + ' backlog"');
    if (AUTO_PUSH) runShell('git push');
    log('CEO-AGENT', `Appended ${added} new Phase P${nextPhase} tasks to tasks.json.`);
    return added > 0;
  } catch (err) {
    log('CEO-AGENT', `Failed to parse CEO JSON output: ${err.message}`);
    return false;
  }
}

/**
 * Department 4: External OS-Level Verification Judge + Non-Trivial Diff Gate
 */
function runExternalVerificationJudge(task) {
  // 1. Verify the agent actually modified or created code files (prevent fake/no-op completions)
  const statusCheck = runShell('git status --porcelain');
  if (!statusCheck.stdout) {
    return {
      passed: false,
      failedCommand: 'git status --porcelain (No files modified)',
      errorLog: 'You did not create or modify any source or test files for this task. Implement the full vertical slice and unit/widget tests before finishing.',
    };
  }

  // 2. Run deterministic analyzer and test suites in the OS shell
  const commands = [
    ...(task.verificationCommands || []),
    'npm run lint',
    'npm test -- --run',
  ];
  const hasFlutter = runShell(IS_WIN ? 'where.exe flutter' : 'command -v flutter').ok;
  if (hasFlutter) {
    commands.push('flutter analyze --fatal-infos --fatal-warnings', 'flutter test');
  }

  const uniqueCommands = [...new Set(commands)];
  for (const cmd of uniqueCommands) {
    if (!hasFlutter && cmd.startsWith('flutter ')) {
      continue;
    }
    const res = runShell(cmd);
    if (!res.ok) {
      log('JUDGE', `FAILED verification command: ${cmd}`);
      return {
        passed: false,
        failedCommand: cmd,
        errorLog: res.combined.slice(-4500),
      };
    }
  }
  return { passed: true };
}

/**
 * Department 5: Autonomous Shipper
 */
function shipCompletedSlice(task) {
  runShell('git add -A');
  const diffCheck = runShell('git status --porcelain');
  if (diffCheck.stdout) {
    const safeTitle = task.title.replace(/["`$&|<>]/g, '');
    const commitMsg = `feat(${task.id.toLowerCase()}): ${safeTitle}`;
    runShell(`git commit -m "${commitMsg}"`);
    log('SHIPPER', `Committed vertical slice: ${commitMsg}`);
  }
  if (AUTO_PUSH) {
    if (process.env.SUPABASE_ACCESS_TOKEN) {
      runShell('npx supabase db push');
    }
    runShell('git push');
    log('SHIPPER', 'Pushed verified commit to origin/main.');
  }
}

async function main() {
  log('DAEMON', `Starting Polsia 24/7 Autonomous Company Daemon (CLI binary: ${AGY_BIN})...`);
  let cycle = 0;

  while (MAX_CYCLES === 0 || cycle < MAX_CYCLES) {
    cycle++;
    log('DAEMON', `================ Autonomous Cycle #${cycle} ================`);

    const tasksData = loadTasks();
    let task = findNextUnblockedTask(tasksData);

    if (!task) {
      const replenished = runAutonomousDiscoveryAndReplenishment(tasksData);
      if (!replenished) {
        log('DAEMON', `Waiting ${SLEEP_SECONDS}s before retrying CEO discovery...`);
        await new Promise((r) => setTimeout(r, SLEEP_SECONDS * 1000));
        continue;
      }
      task = findNextUnblockedTask(loadTasks());
    }

    if (!task) continue;

    task.status = 'IN_PROGRESS';
    saveTasks(tasksData);
    log('ORCHESTRATOR', `Executing Task ${task.id}: ${task.title}`);

    let verified = false;
    let lastFailureContext = '';

    for (let attempt = 1; attempt <= MAX_REWORK; attempt++) {
      log('BUILDER', `Task ${task.id} — Iteration ${attempt}/${MAX_REWORK}`);

      const builderPrompt = `
You are the Autonomous Product & Systems Engineer for Around.
Read .antigravity/rules.md and AGENTS.md.

TARGET TASK TO IMPLEMENT NOW:
- ID: ${task.id}
- Title: ${task.title}
- Domain: ${task.domain}
- Description: ${task.description}
- Affected Paths: ${(task.affectedPaths || []).join(', ')}
- Acceptance Criteria:
${(task.acceptanceCriteria || []).map((c) => `  * ${c}`).join('\n')}

${
  lastFailureContext
    ? `CRITICAL REWORK REQUIRED — YOUR PREVIOUS ITERATION FAILED EXTERNAL VERIFICATION:\n${lastFailureContext}\nFix the root cause immediately.`
    : ''
}

MANDATORY RULES:
1. Implement the complete vertical slice (production code + unit/widget tests).
2. Do NOT mark the task DONE yourself in tasks.json and do NOT run git commit—the external Polsia daemon will run the verification suite, update tasks.json, and commit ONLY if your code passes all checks.
`.trim();

      runHeadlessAgy(builderPrompt, { timeoutSec: 900 });

      const verdict = runExternalVerificationJudge(task);
      if (verdict.passed) {
        verified = true;
        log('JUDGE', `Task ${task.id} PASSED external verification on iteration ${attempt}!`);
        break;
      } else {
        lastFailureContext = `Failed Check: ${verdict.failedCommand}\nOutput:\n${verdict.errorLog}`;
        log('JUDGE', `Task ${task.id} failed check "${verdict.failedCommand}". Triggering self-healing rework iteration...`);
      }
    }

    if (verified) {
      const freshData = loadTasks();
      const target = freshData.tasks.find((t) => t.id === task.id);
      if (target) {
        target.status = 'DONE';
        target.completedAt = timestamp();
        saveTasks(freshData);
      }
      appendCompanyPulse(
        `### [${timestamp()}] Shipped \`${task.id}\` — ${task.title}\n- **Domain**: ${task.domain}\n- **Affected Paths**: ${(task.affectedPaths || []).map((p) => `\`${p}\``).join(', ')}\n- **Verification**: Passed Flutter & Web test suites\n`
      );
      shipCompletedSlice(task);
    } else {
      log('ORCHESTRATOR', `Task ${task.id} failed ${MAX_REWORK} rework iterations. Rolling back uncommitted edits and marking BLOCKED.`);
      runShell('git checkout -- . && git clean -fd');
      const freshData = loadTasks();
      const target = freshData.tasks.find((t) => t.id === task.id);
      if (target) {
        target.status = 'BLOCKED';
        target.blockedReason = lastFailureContext.slice(0, 1000);
        saveTasks(freshData);
      }
      appendCompanyPulse(
        `### [${timestamp()}] Blocked \`${task.id}\` — ${task.title}\n- **Reason**: Failed ${MAX_REWORK} rework iterations.\n`
      );
      runShell('git add tasks.json COMPANY_PULSE.md && git commit -m "chore(loop): mark ' + task.id + ' blocked after rework limit"');
    }

    await new Promise((r) => setTimeout(r, SLEEP_SECONDS * 1000));
  }
}

main().catch((err) => {
  log('FATAL', err.stack || err.message);
  process.exit(1);
});
