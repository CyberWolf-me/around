#!/usr/bin/env bash
# ==============================================================================
# Around — Ralph Wiggum Headless Loop for Google Antigravity CLI (`agy`)
# Spawns a fresh, clean-context `agy -p` agent on every iteration until all
# tasks in `tasks.json` pass external shell verification.
# ==============================================================================
set -uo pipefail

MAX_ITERATIONS="${1:-50}"
SLEEP_SECONDS="${2:-5}"
AGY_BIN="${AGY_BIN:-agy}"

echo "Starting Antigravity Headless Ralph Loop (max iterations: $MAX_ITERATIONS)..."

for ((i=1; i<=MAX_ITERATIONS; i++)); do
  echo ""
  echo "=================================================================="
  echo "[$(date -Iseconds)] Iteration $i / $MAX_ITERATIONS"
  echo "=================================================================="

  # Run one clean-context headless turn in auto mode with permission bypass
  "$AGY_BIN" -p "Read .antigravity/rules.md, AGENTS.md, and tasks.json. Pick the first READY or BACKLOG task whose dependencies are DONE (or generate the next sprint of tasks into tasks.json if all are DONE). Implement the full vertical slice, run verification checks, update tasks.json and COMPANY_PULSE.md, and commit your verified work." \
    --mode=auto \
    --dangerously-skip-permissions

  # External deterministic verification gate
  echo "[Judge] Running external verification gate..."
  if npm run lint && npm test -- --run; then
    if command -v flutter >/dev/null 2>&1; then
      if ! (flutter analyze --no-pub && flutter test); then
        echo "[Judge] Flutter verification failed! Next loop iteration will self-heal..."
        sleep "$SLEEP_SECONDS"
        continue
      fi
    fi
    echo "[Judge] External verification passed! Checkpointing git state..."
    if [[ -n "$(git status --porcelain)" ]]; then
      git add -A
      git commit -m "chore(loop): verified autonomous iteration #$i" || true
    fi
  else
    echo "[Judge] Web/TypeScript verification failed! Feeding failure into next iteration..."
  fi

  sleep "$SLEEP_SECONDS"
done
