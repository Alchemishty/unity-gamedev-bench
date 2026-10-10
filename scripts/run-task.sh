#!/usr/bin/env zsh
set -uo pipefail

# ============================================================
# unity-gamedev-bench v0.1 — Run a single task
# ============================================================

usage() {
    cat <<EOF
Usage: ./scripts/run-task.sh <task_id> --agent <command> --label <name> [options]

Options:
  --agent <cmd>         Agent CLI command (use 'manual' for GUI agents)
  --label <name>        Label for results directory
  --setup <script>      Script to run before the agent
  --snapshot-dir <dir>  Pre-prepared immutable snapshot (skips clone/fetch)
  --model <id>          Model identifier for metadata
  --docker              Run agent inside Docker sandbox
  --docker-image <i>    Docker image (default: ugb-sandbox)
  --closed-book         Docker + no network (implies --docker)
  --help                Show this help
EOF
    exit "${1:-0}"
}

TASK_ID="" AGENT_CMD="" LABEL="" SETUP_SCRIPT="" SNAPSHOT_DIR=""
MODEL_ID="unknown" USE_DOCKER=false CLOSED_BOOK=false DOCKER_IMAGE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --agent)        AGENT_CMD="$2"; shift 2 ;;
        --label)        LABEL="$2"; shift 2 ;;
        --setup)        SETUP_SCRIPT="$2"; shift 2 ;;
        --snapshot-dir) SNAPSHOT_DIR="$2"; shift 2 ;;
        --prompt-mode)  shift 2 ;; # Accepted but ignored in v0.1
        --model)        MODEL_ID="$2"; shift 2 ;;
        --docker)       USE_DOCKER=true; shift ;;
        --docker-image) DOCKER_IMAGE="$2"; USE_DOCKER=true; shift 2 ;;
        --closed-book)  USE_DOCKER=true; CLOSED_BOOK=true; shift ;;
        --help)         usage 0 ;;
        -*)             echo "Error: Unknown option: $1"; usage 1 ;;
        *)              if [[ -z "$TASK_ID" ]]; then TASK_ID="$1"; shift; else echo "Error: Unexpected: $1"; usage 1; fi ;;
    esac
done

[[ -z "$TASK_ID" || -z "$AGENT_CMD" || -z "$LABEL" ]] && { echo "Error: task_id, --agent, --label required."; usage 1; }

BENCH_ROOT="${0:A:h:h}"

# ---- Task file resolution ----
extract_field() { grep -m1 "^\*\*${1}:\*\*" "$TASK_FILE" 2>/dev/null | sed "s/^\*\*${1}:\*\* *//" | sed 's/ *$//' || echo ""; }
extract_meta()  { sed -n '/^<!--/,/^-->/p' "$TASK_FILE" 2>/dev/null | grep -m1 "^${1}:" 2>/dev/null | sed "s/^${1}: *//" || echo ""; }

resolve_task_file() {
    local id="$1"
    local prefix="${id%%[0-9]*}"
    local num="${id#${prefix}}"
    local p="$(printf '%02d' "$num" 2>/dev/null || echo "$num")"
    case "$prefix" in
        s) set -- "${BENCH_ROOT}"/tasks/synthetic/task-${p}-*.md(N) ;;
        m) set -- "${BENCH_ROOT}"/tasks/real-world/mirror/task-m${p}-*.md(N) ;;
        n) set -- "${BENCH_ROOT}"/tasks/real-world/ngo/ngo-${p}-*.md(N) ;;
        b) set -- "${BENCH_ROOT}"/tasks/real-world/bossroom/br-${p}-*.md(N) ;;
        h) set -- "${BENCH_ROOT}"/tasks/real-world/unityhfsm/h${p}-*.md(N) ;;
        v) set -- "${BENCH_ROOT}"/tasks/real-world/vcontainer/v${p}-*.md(N) ;;
        l) set -- "${BENCH_ROOT}"/tasks/real-world/litmotion/l${p}-*.md(N) ;;
        u) set -- "${BENCH_ROOT}"/tasks/real-world/unitask/u${p}-*.md(N) ;;
        i) set -- "${BENCH_ROOT}"/tasks/real-world/inputsystem/i${p}-*.md(N) ;;
        c) set -- "${BENCH_ROOT}"/tasks/real-world/crest/c${p}-*.md(N) ;;
        *) echo ""; return ;;
    esac
    [[ $# -gt 0 && -f "$1" ]] && echo "$1" || echo ""
}

TASK_FILE=$(resolve_task_file "$TASK_ID")
[[ -z "$TASK_FILE" || ! -f "$TASK_FILE" ]] && { echo "Error: No task file for '${TASK_ID}'."; exit 1; }

TASK_TITLE=$(grep -m1 '^# ' "$TASK_FILE" | sed 's/^# //' | sed 's/^Task[: ]*//')
TASK_CATEGORY=$(extract_field "Category")
TASK_DIFFICULTY=$(extract_meta "difficulty")
[[ -z "$TASK_DIFFICULTY" ]] && TASK_DIFFICULTY=$(extract_field "Difficulty" | tr '[:upper:]' '[:lower:]')
TASK_REPO=$(extract_meta "repo"); [[ -z "$TASK_REPO" ]] && TASK_REPO=$(extract_field "Repo")
TASK_BASE_SHA=$(extract_meta "base_sha"); [[ -z "$TASK_BASE_SHA" ]] && TASK_BASE_SHA=$(extract_field "Base Commit")

# ---- Extract ONLY the user-facing prompt (blockquotes under ## Prompt) ----
PROMPT=$(awk '/^## Prompt$/{p=1;next} p&&/^## /{exit} p&&/^>/{gsub(/^> ?/,"");print}' "$TASK_FILE" | sed '/^$/d')
[[ -z "$PROMPT" ]] && { echo "Error: Could not extract prompt from ${TASK_FILE}"; exit 1; }

# ---- Prepare working directory ----
WORK_DIR=$(mktemp -d); trap 'rm -rf "$WORK_DIR"' EXIT
RESULTS_DIR="${BENCH_ROOT}/results/${LABEL}"; mkdir -p "$RESULTS_DIR"
LOG_FILE="${RESULTS_DIR}/${TASK_ID}.log"
DIFF_FILE="${RESULTS_DIR}/${TASK_ID}.diff"
META_FILE="${RESULTS_DIR}/${TASK_ID}.meta.json"

NETWORK_MODE="enabled"
$CLOSED_BOOK && NETWORK_MODE="disabled"

echo "  [${TASK_ID}] ${TASK_TITLE} (${TASK_DIFFICULTY:-?})"

TASK_START=$(date +%s)

# ---- Prepare workspace from snapshot or clone ----
if [[ -n "$SNAPSHOT_DIR" && -d "$SNAPSHOT_DIR" ]]; then
    # Use pre-prepared immutable snapshot (from run-all.sh)
    if ! cp -R "${SNAPSHOT_DIR}/." "${WORK_DIR}/"; then
        echo "  [${TASK_ID}] INFRA ERROR: Failed to copy snapshot"; exit 2
    fi
else
    # Standalone mode: clone/fetch ourselves
    [[ -z "$TASK_REPO" ]] && { echo "  [${TASK_ID}] INFRA ERROR: Task file missing repo metadata"; exit 2; }
    [[ -z "$TASK_BASE_SHA" || "$TASK_BASE_SHA" == *"TBD"* ]] && { echo "  [${TASK_ID}] INFRA ERROR: No usable base commit"; exit 2; }

    CACHE_DIR="${BENCH_ROOT}/.cache/repos"
    mkdir -p "$CACHE_DIR"
    cache_name=$(echo "$TASK_REPO" | sed 's|https://github.com/||' | tr '/' '_' | sed 's/\.git$//')
    CACHED_REPO="${CACHE_DIR}/${cache_name}"

    if [[ -d "$CACHED_REPO/.git" ]]; then
        git -C "$CACHED_REPO" fetch -q 2>/dev/null || true
    else
        if ! git clone -q "$TASK_REPO" "$CACHED_REPO"; then
            echo "  [${TASK_ID}] INFRA ERROR: Clone failed"; exit 2
        fi
    fi

    if ! cp -R "${CACHED_REPO}/." "${WORK_DIR}/"; then
        echo "  [${TASK_ID}] INFRA ERROR: Copy from cache failed"; exit 2
    fi
    if ! (cd "$WORK_DIR" && git checkout -q "$TASK_BASE_SHA"); then
        echo "  [${TASK_ID}] INFRA ERROR: Checkout ${TASK_BASE_SHA} failed"; exit 2
    fi
fi

# ---- Clean isolation: delete .git, init fresh, assert clean ----
rm -rf "${WORK_DIR}/.git"
if ! (cd "$WORK_DIR" && git init -q && git add -A && git -c user.name="Benchmark" -c user.email="benchmark@invalid" commit -q -m "baseline"); then
    echo "  [${TASK_ID}] INFRA ERROR: Baseline commit failed"; exit 2
fi

# ---- Setup script ----
if [[ -n "$SETUP_SCRIPT" ]]; then
    resolved="$SETUP_SCRIPT"
    [[ ! -f "$resolved" ]] && resolved="${BENCH_ROOT}/${SETUP_SCRIPT}"
    [[ ! -f "$resolved" ]] && { echo "  [${TASK_ID}] INFRA ERROR: Setup script not found: ${SETUP_SCRIPT}"; exit 2; }
    resolved="${resolved:A}"
    if $USE_DOCKER; then
        echo "  [${TASK_ID}] Setup will run inside Docker: ${resolved}"
    else
        SETUP_EXIT=0
        (cd "$WORK_DIR" && bash "$resolved") || SETUP_EXIT=$?
        if [[ "$SETUP_EXIT" -ne 0 ]]; then
            echo "  [${TASK_ID}] INFRA ERROR: Setup script exited ${SETUP_EXIT}"
            echo "SETUP_FAILURE:${SETUP_EXIT}" > "${RESULTS_DIR}/${TASK_ID}.failed"
            exit 2
        fi
        (cd "$WORK_DIR" && git add -A && git -c user.name="Benchmark" -c user.email="benchmark@invalid" commit -q -m "setup" 2>/dev/null || true)
    fi
fi

# ---- Run agent ----
AGENT_EXIT=0

if $USE_DOCKER; then
    [[ -z "$DOCKER_IMAGE" ]] && DOCKER_IMAGE="ugb-sandbox"
    TASK_RESULTS_DIR=$(mktemp -d)
    DOCKER_ARGS=(--rm -v "${WORK_DIR}:/workspace" -v "${TASK_RESULTS_DIR}:/results"
        -e "BENCH_AGENT_CMD=${AGENT_CMD}" -e "BENCH_PROMPT=${PROMPT}")
    [[ -n "$SETUP_SCRIPT" ]] && DOCKER_ARGS+=(-v "${resolved}:/setup/install.sh:ro")
    $CLOSED_BOOK && DOCKER_ARGS+=(--network none)

    docker run "${DOCKER_ARGS[@]}" "$DOCKER_IMAGE" || AGENT_EXIT=$?

    [[ -f "${TASK_RESULTS_DIR}/task.diff" ]] && mv "${TASK_RESULTS_DIR}/task.diff" "$DIFF_FILE"
    [[ -f "${TASK_RESULTS_DIR}/agent.log" ]] && mv "${TASK_RESULTS_DIR}/agent.log" "$LOG_FILE"
    DOCKER_MARKER_EXISTS=false
    if [[ -f "${TASK_RESULTS_DIR}/task.failed" ]]; then
        DOCKER_MARKER_EXISTS=true
        mv "${TASK_RESULTS_DIR}/task.failed" "${RESULTS_DIR}/${TASK_ID}.failed"
    elif [[ "$AGENT_EXIT" -ge 125 && "$AGENT_EXIT" -le 127 ]]; then
        echo "DOCKER_FAILURE:${AGENT_EXIT}" > "${RESULTS_DIR}/${TASK_ID}.failed"
        DOCKER_MARKER_EXISTS=true
    fi
    [[ -f "${TASK_RESULTS_DIR}/verification.json" ]] && mv "${TASK_RESULTS_DIR}/verification.json" "${RESULTS_DIR}/${TASK_ID}.verification.json"
    [[ -f "${TASK_RESULTS_DIR}/baseline-verification.json" ]] && mv "${TASK_RESULTS_DIR}/baseline-verification.json" "${RESULTS_DIR}/${TASK_ID}.baseline-verification.json"
    rm -rf "$TASK_RESULTS_DIR"
    DIFF_LINES=$(wc -l < "$DIFF_FILE" 2>/dev/null | tr -d ' ')

elif [[ "$AGENT_CMD" == "manual" ]]; then
    echo "  MANUAL MODE — Work in: ${WORK_DIR}"
    echo "  Prompt: ${PROMPT}"
    read -r "?  Press Enter when done... "
    (cd "$WORK_DIR" && git add -A && git diff --cached --binary -- . ':!Library/' ':!Temp/' ':!Logs/' ':!obj/' > "$DIFF_FILE" 2>/dev/null) || true
    DIFF_LINES=$(wc -l < "$DIFF_FILE" 2>/dev/null | tr -d ' ')
else
    (cd "$WORK_DIR" && eval "${AGENT_CMD}" '"${PROMPT}"' 2>&1 | tee "$LOG_FILE") || AGENT_EXIT=$?
    echo "Agent exit code: ${AGENT_EXIT}" >> "$LOG_FILE"
    (cd "$WORK_DIR" && git add -A && git diff --cached --binary -- . ':!Library/' ':!Temp/' ':!Logs/' ':!obj/' > "$DIFF_FILE" 2>/dev/null) || true
    DIFF_LINES=$(wc -l < "$DIFF_FILE" 2>/dev/null | tr -d ' ')
fi

TASK_END=$(date +%s)
TASK_DURATION=$(( TASK_END - TASK_START ))

# ---- Determine status ----
# Exit code 2 = infrastructure error (already handled above for setup/clone failures)
# Agent failures and no-changes are agent-level results, not infra errors
TASK_STATUS="success"
if [[ "${DOCKER_MARKER_EXISTS:-false}" == "true" ]]; then
    if [[ -f "${RESULTS_DIR}/${TASK_ID}.failed" ]]; then
        docker_reason=$(cat "${RESULTS_DIR}/${TASK_ID}.failed")
        case "$docker_reason" in
            DOCKER_FAILURE*|SETUP_FAILURE*|MISSING_ENV*) TASK_STATUS="infra_error" ;;
            *)  TASK_STATUS="agent_failed" ;;
        esac
    fi
elif [[ "$AGENT_EXIT" -ne 0 ]]; then
    echo "AGENT_FAILURE:${AGENT_EXIT}:diff_lines=${DIFF_LINES}" > "${RESULTS_DIR}/${TASK_ID}.failed"
    TASK_STATUS="agent_failed"
elif [[ "${DIFF_LINES:-0}" -eq 0 ]]; then
    echo "NO_CHANGES" > "${RESULTS_DIR}/${TASK_ID}.failed"
    TASK_STATUS="no_changes"
else
    rm -f "${RESULTS_DIR}/${TASK_ID}.failed"
fi

# ---- Parse token usage from log (best-effort) ----
TOKENS_IN="null"
TOKENS_OUT="null"
if [[ -f "$LOG_FILE" ]]; then
    # Claude CLI may print token usage in various formats
    local tin tout
    tin=$(grep -oi 'input.tokens[: ]*[0-9,]*' "$LOG_FILE" 2>/dev/null | head -1 | grep -o '[0-9,]*$' | tr -d ',')
    tout=$(grep -oi 'output.tokens[: ]*[0-9,]*' "$LOG_FILE" 2>/dev/null | head -1 | grep -o '[0-9,]*$' | tr -d ',')
    [[ -n "$tin" ]] && TOKENS_IN="$tin"
    [[ -n "$tout" ]] && TOKENS_OUT="$tout"
fi

# ---- Write per-task metadata ----
if command -v jq &>/dev/null; then
    jq -n \
        --arg tid "$TASK_ID" \
        --arg diff "${TASK_DIFFICULTY:-unknown}" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson dur "$TASK_DURATION" \
        --arg acmd "$AGENT_CMD" \
        --arg model "$MODEL_ID" \
        --arg pmode "guided" \
        --argjson docker "$($USE_DOCKER && echo true || echo false)" \
        --arg net "$NETWORK_MODE" \
        --argjson aexit "$AGENT_EXIT" \
        --argjson dlines "${DIFF_LINES:-0}" \
        --arg status "$TASK_STATUS" \
        --argjson tin "$TOKENS_IN" \
        --argjson tout "$TOKENS_OUT" \
        '{task_id:$tid, difficulty:$diff, timestamp:$ts, duration_seconds:$dur, agent_cmd:$acmd, model:$model, prompt_mode:$pmode, docker:$docker, network:$net, agent_exit_code:$aexit, diff_lines:$dlines, status:$status, tokens_in:$tin, tokens_out:$tout}' \
        > "$META_FILE"
else
    cat > "$META_FILE" << METAEOF
{
  "task_id": "${TASK_ID}",
  "difficulty": "${TASK_DIFFICULTY:-unknown}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "duration_seconds": ${TASK_DURATION},
  "agent_cmd": "$(echo "$AGENT_CMD" | sed 's/"/\\"/g')",
  "model": "$(echo "$MODEL_ID" | sed 's/"/\\"/g')",
  "prompt_mode": "guided",
  "docker": $($USE_DOCKER && echo true || echo false),
  "network": "${NETWORK_MODE}",
  "agent_exit_code": ${AGENT_EXIT},
  "diff_lines": ${DIFF_LINES:-0},
  "status": "${TASK_STATUS}",
  "tokens_in": ${TOKENS_IN},
  "tokens_out": ${TOKENS_OUT}
}
METAEOF
fi

# Print summary
case "$TASK_STATUS" in
    success)      echo "  [${TASK_ID}] ✓ ${DIFF_LINES} lines, ${TASK_DURATION}s" ;;
    agent_failed) echo "  [${TASK_ID}] ✗ agent failed (exit ${AGENT_EXIT}), ${DIFF_LINES:-0} lines, ${TASK_DURATION}s" ;;
    no_changes)   echo "  [${TASK_ID}] ✗ no changes, ${TASK_DURATION}s" ;;
    infra_error)  echo "  [${TASK_ID}] ⚠ infrastructure error, ${TASK_DURATION}s" ;;
esac

# Exit codes: 0=success, 1=agent failure, 2=infrastructure error
case "$TASK_STATUS" in
    success)     exit 0 ;;
    infra_error) exit 2 ;;
    *)           exit 1 ;;
esac
