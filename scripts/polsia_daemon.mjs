#!/usr/bin/env node
/**
 * Around — Polsia-Style 24/7 Autonomous Company Daemon for Google Antigravity CLI (agy)
 *
 * Why standard IDE workflows stop:
 *   Chat slash-commands (/startcycle) live inside a single LLM context window and stop
 *   when a turn ends, when context fills up, or when a permission prompt appears.
 *
 * How this daemon works (like Polsia AI + Ralph Wiggum Loops):
 *   1. Outer OS Process Loop: Runs continuously outside the LLM, spawning a fresh,
 *      clean-context `agy -p` headless agent process on every single iteration.
 *   2. Autonomous CEO Phase (Self-Replenishing Backlog): When `tasks.json` has zero
 *      unblocked READY/BACKLOG tasks, the daemon spawns the CEO Planner agent with
 *      `--json-schema .agents/schemas/ceo_tasks.schema.json` to inspect `PRODUCT_CAPABILITIES.md`,
 *      audit the codebase for gaps/bugs/UX improvements, and generate the next sprint automatically.
 *   3. Autonomous Builder Phase: Invokes `agy -p --mode=auto --dangerously-skip-permissions`
 *      for one vertical slice at a time.
 *   4. Hard External Judge Gate (Zero Hallucinated Victory): The Node daemon itself runs
 *      `flutter analyze`, `flutter test`, `npm test`, and SQL RLS checks in the OS shell.
 *      If any command fails, the agent is NOT allowed to mark the task DONE; the daemon feeds
 *      the exact compiler/test stderr back into a fresh rework invocation (up to MAX_REWORK times).
 *   5. Autonomous Shipper & Company Pulse Log: Commits verified slices, updates `tasks.json`
 *      and `COMPANY_PULSE.md`, and pushes to staging (`supabase db push` + `git push`).
 */

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const TASKS_FILE = path.join(ROOT, 'tasks.json');
const PULSE_FILE = path.join(ROOT, 'COMPANY_PULSE.md');
const CEO_SCHEMA_FILE = path.join(ROOT, '.agents', 'schemas', 'ceo_tasks.schema.json');
const LOG_DIR = path.join(ROOT, 'logs', 'polsia');

const args = process.argv.slice(2);
const getArg = (flag, fallback) => {
  const idx = args.indexOf(flag);
  return idx !== -1 && args[idx + 1] ? args[idx + 1] : fallback;
};

const MAX_CYCLES = Number(getArg('--max-cycles', process.env.POLSIA_MAX_CYCLES || '0')); // 0 = infinite 24/7 loop
const MAX_REWORK = Number(getArg('--max-rework', process.env.POLSIA_MAX_REWORK || '4'));
const SLEEP_SECONDS = Number(getArg('--sleep', process.env.POLSIA_SLEEP_SECONDS || '10'));
const AUTO_PUSH = args.includes('--push') || process.env.POLSIA_AUTO_PUSH === 'true';
const AGY_BIN = getArg('--agy-bin', process.env.AGY_BIN || 'agy');
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

function runShell(cmd, timeoutMs = 300_000) {
  log('SHELL', `Executing: ${cmd}`);
  const res = spawnSync(cmd, {
    cwd: ROOT,
    shell: true,
    encoding: 'utf8',
    timeout: timeoutMs,
    maxBuffer: 20 * 1024 * 1024,
  });
  return {
    ok: res.status === 0,
    status: res.status ?? 1,
    stdout: (res.stdout || '').trim(),
    stderr: (res.stderr || '').trim(),
    combined: `${res.stdout || ''}\n${res.stderr || ''}`.trim(),
  };
}

function hasBinary(bin) {
  const checkCmd = process.platform === 'win32' ? `where ${bin}` : `command -v ${bin}`;
  return runShell(checkCmd).ok;
}

function runHeadlessAgy(prompt, { jsonSchema = null, timeoutSec = 900 } = {}) {
  const cliArgs = [
    '-p',
    prompt,
    '--mode=auto',
    '--dangerously-skip-permissions',
    `--print-timeout=${timeoutSec}s`,
  ];
  if (MODEL) {
    cliArgs.push('--model', MODEL);
  }
  if (jsonSchema) {
    cliArgs.push('--output-format', 'json', '--json-schema', jsonSchema);
  }

  log('AGY', `Spawning clean-context headless agent (${cliArgs.join(' ').slice(0, 120)}...)`);
  const res = spawnSync(AGY_BIN, cliArgs, {
    cwd: ROOT,
    encoding: 'utf8',
    timeout: (timeoutSec + 30) * 1000,
    maxBuffer: 50 * 1024 * 1024,
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  const output = (res.stdout || '').trim();
  const errOutput = (res.stderr || (res.error ? res.error.message : '')).trim();
  if (res.error) {
    log('AGY', `Spawn error: ${res.error.message}. Ensure "${AGY_BIN}" is installed in PATH or pass --agy-bin <path>.`);
  }
  fs.writeFileSync(
    path.join(LOG_DIR, `last_agent_turn_${Date.now()}.log`),
    `PROMPT:\n${prompt}\n\nSTDOUT:\n${output}\n\nSTDERR:\n${errOutput}\n`,
    'utf8'
  );

  return {
    ok: res.status === 0,
    status: res.status ?? 1,
    stdout: output,
    stderr: errOutput,
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
 * Phase 1: Autonomous CEO Agent — Self-Replenishes `tasks.json` when the queue is empty
 */
function runAutonomousCeoReplenishment(tasksData) {
  log('CEO-AGENT', 'No unblocked READY/BACKLOG tasks remain. Launching Autonomous CEO Product Planner...');
  const existingIds = tasksData.tasks.map((t) => `${t.id}: ${t.title} (${t.status})`).join('\n');

  const ceoPrompt = `
You are the Autonomous CEO & Chief Product Architect for Around (a places-first social discovery platform in Tashkent).
All current tasks in tasks.json are DONE:
${existingIds}

Your job is to keep the company shipping continuously:
1. Inspect PRODUCT.md, PRODUCT_CAPABILITIES.md, ARCHITECTURE.md, lib/, and supabase/migrations/.
2. Identify the top 3 highest-leverage unbuilt capabilities, production hardening improvements, UX polish slices, or test coverage expansions that move Around further toward a world-class production release.
3. Return strictly valid JSON matching the schema so the orchestrator can append these tasks to tasks.json and immediately begin implementing them.
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
      `### [${timestamp()}] CEO Sprint Replenishment\n- **Strategy**: ${parsed.strategicSummary}\n- **Queued Tasks**: ${parsed.newTasks.map((t) => `\`${t.id}\` (${t.title})`).join(', ')}\n`
    );
    log('CEO-AGENT', `Appended ${added} new autonomous tasks to tasks.json.`);
    return added > 0;
  } catch (err) {
    log('CEO-AGENT', `Failed to parse CEO JSON output: ${err.message}`);
    return false;
  }
}

/**
 * Phase 3: External OS-Level Verification Judge (Never trusts the LLM's word)
 */
function runExternalVerificationJudge(task) {
  const commands = [
    ...(task.verificationCommands || []),
    'npm run lint',
    'npm test -- --run',
  ];
  // Run flutter checks if flutter is installed on the host machine
  const hasFlutter = hasBinary('flutter');
  if (hasFlutter) {
    commands.push('flutter analyze --no-pub', 'flutter test');
  }
  // Run Supabase RLS test suite if SUPABASE_DB_URL is set and psql is available
  if (process.env.SUPABASE_DB_URL && hasBinary('psql')) {
    commands.push(
      'psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_authorization_test.sql'
    );
  }

  const uniqueCommands = [...new Set(commands)];
  for (const cmd of uniqueCommands) {
    if (!hasFlutter && cmd.startsWith('flutter ')) {
      log('JUDGE', `Skipping "${cmd}" (flutter binary not in PATH on this runner)`);
      continue;
    }
    const res = runShell(cmd);
    if (!res.ok) {
      log('JUDGE', `FAILED verification command: ${cmd}`);
      return {
        passed: false,
        failedCommand: cmd,
        errorLog: res.combined.slice(-4000),
      };
    }
  }
  return { passed: true };
}

/**
 * Phase 4: Autonomous Shipper — Commits, updates state, and pushes to staging
 */
function shipCompletedSlice(task) {
  runShell('git add -A');
  const diffCheck = runShell('git status --porcelain');
  if (diffCheck.stdout) {
    const commitMsg = `feat(${task.id.toLowerCase()}): ${task.title.replace(/"/g, '')}`;
    runShell(`git commit -m "${commitMsg}"`);
    log('SHIPPER', `Committed vertical slice: ${commitMsg}`);
  }

  if (AUTO_PUSH) {
    if (process.env.SUPABASE_ACCESS_TOKEN) {
      runShell('npx supabase db push');
    }
    runShell('git push');
    log('SHIPPER', 'Pushed verified commit and migrations to remote.');
  }
}

async function main() {
  log('DAEMON', 'Starting Polsia-Style Autonomous Company Daemon for Around...');
  let cycle = 0;

  while (MAX_CYCLES === 0 || cycle < MAX_CYCLES) {
    cycle++;
    log('DAEMON', `=== Starting Autonomous Cycle #${cycle} ===`);

    const tasksData = loadTasks();
    let task = findNextUnblockedTask(tasksData);

    if (!task) {
      const replenished = runAutonomousCeoReplenishment(tasksData);
      if (!replenished) {
        log('DAEMON', `No tasks available and CEO replenishment produced none. Sleeping ${SLEEP_SECONDS}s...`);
        await new Promise((r) => setTimeout(r, SLEEP_SECONDS * 1000));
        continue;
      }
      task = findNextUnblockedTask(tasksData);
    }

    if (!task) continue;

    // Mark task IN_PROGRESS on disk
    task.status = 'IN_PROGRESS';
    saveTasks(tasksData);
    log('ORCHESTRATOR', `Selected Task ${task.id}: ${task.title}`);

    let verified = false;
    let lastFailureContext = '';

    for (let attempt = 1; attempt <= MAX_REWORK; attempt++) {
      log('BUILDER', `Task ${task.id} — Implementation Attempt ${attempt}/${MAX_REWORK}`);

      const builderPrompt = `
You are executing an autonomous engineering iteration for Around.
Read .antigravity/rules.md and AGENTS.md.

CURRENT TARGET TASK:
- ID: ${task.id}
- Title: ${task.title}
- Domain: ${task.domain}
- Description: ${task.description}
- Affected Paths: ${(task.affectedPaths || []).join(', ')}
- Acceptance Criteria:
${(task.acceptanceCriteria || []).map((c) => `  * ${c}`).join('\n')}

${
  lastFailureContext
    ? `PREVIOUS ATTEMPT FAILED EXTERNAL VERIFICATION. FIX THIS EXACT ERROR IMMEDIATELY:\n${lastFailureContext}\n`
    : ''
}

INSTRUCTIONS:
1. Implement the complete vertical slice across the affected paths (database migrations/RLS tests, Flutter lib/, React src/ if applicable, and unit/widget tests).
2. Update PRODUCT_CAPABILITIES.md if this task upgrades a domain capability.
3. Do NOT fake test results—the external daemon will run the verification suite as soon as you exit.
`.trim();

      runHeadlessAgy(builderPrompt, { timeoutSec: 900 });

      const verdict = runExternalVerificationJudge(task);
      if (verdict.passed) {
        verified = true;
        log('JUDGE', `Task ${task.id} PASSED all external verification checks on attempt ${attempt}!`);
        break;
      } else {
        lastFailureContext = `Command \`${verdict.failedCommand}\` failed with output:\n${verdict.errorLog}`;
        log('JUDGE', `Task ${task.id} failed check "${verdict.failedCommand}". Queueing rework iteration...`);
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
        `### [${timestamp()}] Shipped \`${task.id}\` — ${task.title}\n- **Domain**: ${task.domain}\n- **Verified Paths**: ${(task.affectedPaths || []).map((p) => `\`${p}\``).join(', ')}\n- **Status**: DONE & Committed\n`
      );
      shipCompletedSlice(task);
    } else {
      log('ORCHESTRATOR', `Task ${task.id} exhausted ${MAX_REWORK} rework attempts. Reverting dirty working tree changes and marking BLOCKED.`);
      runShell('git checkout -- . && git clean -fd');
      const freshData = loadTasks();
      const target = freshData.tasks.find((t) => t.id === task.id);
      if (target) {
        target.status = 'BLOCKED';
        target.blockedReason = lastFailureContext.slice(0, 1000);
        saveTasks(freshData);
      }
      appendCompanyPulse(
        `### [${timestamp()}] Blocked \`${task.id}\` — ${task.title}\n- **Reason**: Exhausted ${MAX_REWORK} rework attempts.\n`
      );
    }

    await new Promise((r) => setTimeout(r, SLEEP_SECONDS * 1000));
  }
}

main().catch((err) => {
  log('FATAL', err.stack || err.message);
  process.exit(1);
});
