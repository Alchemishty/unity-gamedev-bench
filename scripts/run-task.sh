#!/usr/bin/env zsh
set -uo pipefail

# ============================================================
# unity-gamedev-bench — Run a single task
# ============================================================

usage() {
    cat <<EOF
Usage: ./scripts/run-task.sh <task_id> --agent <command> --label <name> [options]

Task IDs: s01-s07, m01-m04 m06-m13, n01-n05, b01-b07, h01, v01-v03, l01, u01, i01, c01

Options:
  --agent <cmd>       Agent CLI command (use 'manual' for GUI agents)
  --label <name>      Label for results directory
  --setup <script>    Script to run before the agent
  --session <n>       For multi-session tasks: session 1 or 2
  --prompt-mode <m>   'guided' (default) or 'diagnostic'
  --model <id>        Model identifier for metadata (e.g. claude-opus-4-6-v1)
  --docker            Run agent inside Docker sandbox
  --docker-image <i>  Docker image to use (default: ugb-sandbox, or ugb-unity)
  --closed-book       Docker + no network access (implies --docker)
  --help              Show this help
EOF
    exit "${1:-0}"
}

TASK_ID="" AGENT_CMD="" LABEL="" SETUP_SCRIPT="" SESSION="" PROMPT_MODE="guided"
MODEL_ID="unknown" USE_DOCKER=false CLOSED_BOOK=false DOCKER_IMAGE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --agent)       AGENT_CMD="$2"; shift 2 ;;
        --label)       LABEL="$2"; shift 2 ;;
        --setup)       SETUP_SCRIPT="$2"; shift 2 ;;
        --session)     SESSION="$2"; shift 2 ;;
        --prompt-mode) PROMPT_MODE="$2"; shift 2 ;;
        --model)       MODEL_ID="$2"; shift 2 ;;
        --docker)      USE_DOCKER=true; shift ;;
        --docker-image) DOCKER_IMAGE="$2"; USE_DOCKER=true; shift 2 ;;
        --closed-book) USE_DOCKER=true; CLOSED_BOOK=true; shift ;;
        --help)        usage 0 ;;
        -*)            echo "Error: Unknown option: $1"; usage 1 ;;
        *)             if [[ -z "$TASK_ID" ]]; then TASK_ID="$1"; shift; else echo "Error: Unexpected: $1"; usage 1; fi ;;
    esac
done

[[ -z "$TASK_ID" || -z "$AGENT_CMD" || -z "$LABEL" ]] && { echo "Error: task_id, --agent, --label required."; usage 1; }

BENCH_ROOT="${0:A:h:h}"

extract_field() { grep -m1 "^\*\*${1}:\*\*" "$TASK_FILE" 2>/dev/null | sed "s/^\*\*${1}:\*\* *//" | sed 's/ *$//' || echo ""; }
extract_meta()  { sed -n '/^<!--/,/^-->/p' "$TASK_FILE" 2>/dev/null | grep -m1 "^${1}:" 2>/dev/null | sed "s/^${1}: *//" || echo ""; }

resolve_task_file() {
    local id="$1"
    local prefix="${id%%[0-9]*}"
    local num="${id#${prefix}}"
    [[ -f "$id" ]] && { echo "$id"; return; }
    [[ -f "${BENCH_ROOT}/$id" ]] && { echo "${BENCH_ROOT}/$id"; return; }
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
[[ -z "$TASK_FILE" || ! -f "$TASK_FILE" ]] && { echo "Error: No task file for '${TASK_ID}'. Run ./scripts/list-tasks.sh"; exit 1; }
echo "Task file: ${TASK_FILE}"

TASK_TITLE=$(grep -m1 '^# ' "$TASK_FILE" | sed 's/^# //' | sed 's/^Task[: ]*//')
TASK_CATEGORY=$(extract_field "Category")
TASK_REPO=$(extract_meta "repo"); [[ -z "$TASK_REPO" ]] && TASK_REPO=$(extract_field "Repo")
TASK_BASE_SHA=$(extract_meta "base_sha"); [[ -z "$TASK_BASE_SHA" ]] && TASK_BASE_SHA=$(extract_field "Base Commit")


# ---- Extract prompt ----
PROMPT=""
if [[ "$PROMPT_MODE" == "diagnostic" ]]; then
    PROMPT=$(awk '/^## Prompt Variant: Diagnostic/{f=1;next} f&&/^>/{gsub(/^> ?/,"");print} f&&!/^>/&&!/^$/{exit}' "$TASK_FILE" | sed '/^$/d')
fi
if [[ -z "$PROMPT" ]]; then
    if [[ -n "$SESSION" && "$SESSION" == "2" ]]; then
        PROMPT=$(awk '/^### Session 2/{f=1;next} f&&/^>/{gsub(/^> ?/,"");print} f&&/^##[^#]/{exit}' "$TASK_FILE" | sed '/^$/d')
    else
        # Extract blockquotes under "## Prompt" exactly (not "## Prompt Variant: ...")
        PROMPT=$(awk '/^## Prompt$/{p=1;next} p&&/^## /{exit} p&&/^>/{gsub(/^> ?/,"");print}' "$TASK_FILE" | sed '/^$/d')
        # Fallback: if empty, try Session 1 blockquotes (multi-session tasks)
        if [[ -z "$PROMPT" ]]; then
            PROMPT=$(awk '/^### Session 1/{f=1;next} f&&/^>/{gsub(/^> ?/,"");print} f&&/^###/{exit} f&&/^## /{exit}' "$TASK_FILE" | sed '/^$/d')
        fi
    fi
fi
[[ -z "$PROMPT" ]] && { echo "Error: Could not extract prompt from ${TASK_FILE}"; exit 1; }

# ---- Prepare working directory ----
WORK_DIR=$(mktemp -d); trap 'rm -rf "$WORK_DIR"' EXIT
RESULTS_DIR="${BENCH_ROOT}/results/${LABEL}"; mkdir -p "$RESULTS_DIR"
TASK_SUFFIX="${TASK_ID}"; [[ -n "$SESSION" ]] && TASK_SUFFIX="${TASK_ID}-session${SESSION}"
LOG_FILE="${RESULTS_DIR}/${TASK_SUFFIX}.log"
DIFF_FILE="${RESULTS_DIR}/${TASK_SUFFIX}.diff"
META_FILE="${RESULTS_DIR}/${TASK_SUFFIX}.meta.json"

NETWORK_MODE="enabled"
$CLOSED_BOOK && NETWORK_MODE="disabled"

echo "============================================================"
echo "  Task: ${TASK_ID} — ${TASK_TITLE}"
echo "  Category: ${TASK_CATEGORY}"
echo "  Agent: ${AGENT_CMD} | Label: ${LABEL} | Model: ${MODEL_ID}"
$USE_DOCKER && echo "  Docker: yes | Network: ${NETWORK_MODE}"
[[ -n "$SESSION" ]] && echo "  Session: ${SESSION}"
echo "  $(date)"
echo "============================================================"

TASK_START=$(date +%s)

[[ -z "$TASK_REPO" ]] && { echo "Error: Task file missing repo metadata"; exit 1; }
[[ -z "$TASK_BASE_SHA" || "$TASK_BASE_SHA" == "Parent of"* || "$TASK_BASE_SHA" == *"TBD"* ]] && \
    { echo "Error: No usable base commit for '${TASK_ID}' (got: '${TASK_BASE_SHA}')"; exit 1; }

CACHE_DIR="${BENCH_ROOT}/.cache/repos"
mkdir -p "$CACHE_DIR"
cache_name=$(echo "$TASK_REPO" | sed 's|https://github.com/||' | tr '/' '_' | sed 's/\.git$//')
CACHED_REPO="${CACHE_DIR}/${cache_name}"

if [[ -d "$CACHED_REPO/.git" ]]; then
    echo "Using cached clone: ${cache_name}"
    git -C "$CACHED_REPO" fetch -q 2>/dev/null || true
else
    echo "Cloning ${TASK_REPO} (will be cached for future runs)..."
    if ! git clone -q "$TASK_REPO" "$CACHED_REPO"; then
        echo "Error: Failed to clone ${TASK_REPO}"; exit 1
    fi
fi

echo "Checking out ${TASK_BASE_SHA}..."
if ! cp -R "${CACHED_REPO}/." "${WORK_DIR}/"; then
    echo "Error: Failed to copy cached repo"; exit 1
fi
if ! (cd "$WORK_DIR" && git checkout -q "$TASK_BASE_SHA"); then
    echo "Error: Failed to checkout ${TASK_BASE_SHA} — commit may not exist in repo"; exit 1
fi
echo "Scrubbing git history..."
rm -rf "${WORK_DIR}/.git"
if ! (cd "$WORK_DIR" && git init -q && git add -A && git -c user.name="Benchmark" -c user.email="benchmark@invalid" commit -q -m "baseline"); then
    echo "Error: Failed to create baseline commit"; exit 1
fi

# ---- Setup script ----
if [[ -n "$SETUP_SCRIPT" ]]; then
    resolved="$SETUP_SCRIPT"
    [[ ! -f "$resolved" ]] && resolved="${BENCH_ROOT}/${SETUP_SCRIPT}"
    [[ ! -f "$resolved" ]] && { echo "Error: Setup script not found: ${SETUP_SCRIPT}"; exit 1; }
    if $USE_DOCKER; then
        # In Docker mode, setup runs inside the container via entrypoint.sh — just resolve the path here
        echo "Setup script will run inside Docker: ${resolved}"
    else
        echo "Running setup: ${resolved}"
        SETUP_EXIT=0
        (cd "$WORK_DIR" && bash "$resolved") || SETUP_EXIT=$?
        if [[ "$SETUP_EXIT" -ne 0 ]]; then
            echo "FAILED: Setup script exited ${SETUP_EXIT}"
            mkdir -p "$RESULTS_DIR"
            echo "SETUP_FAILURE:${SETUP_EXIT}" > "${RESULTS_DIR}/${TASK_SUFFIX}.failed"
            exit 1
        fi
        (cd "$WORK_DIR" && git add -A && git -c user.name="Benchmark" -c user.email="benchmark@invalid" commit -q -m "setup" 2>/dev/null || true)
    fi
fi

# ---- Run agent ----
echo ""; echo "Prompt:"; echo "---"; echo "$PROMPT"; echo "---"; echo ""
AGENT_EXIT=0

if $USE_DOCKER; then
    # Docker execution path — use array to avoid word-splitting on spaces in prompt/agent cmd
    [[ -z "$DOCKER_IMAGE" ]] && DOCKER_IMAGE="ugb-sandbox"

    TASK_RESULTS_DIR=$(mktemp -d)

    DOCKER_ARGS=(
        --rm
        -v "${WORK_DIR}:/workspace"
        -v "${TASK_RESULTS_DIR}:/results"
        -e "BENCH_AGENT_CMD=${AGENT_CMD}"
        -e "BENCH_PROMPT=${PROMPT}"
    )

    if [[ -n "$SETUP_SCRIPT" ]]; then
        DOCKER_ARGS+=(-v "${resolved}:/setup/install.sh:ro")
    fi

    $CLOSED_BOOK && DOCKER_ARGS+=(--network none)

    echo "Running in Docker sandbox ($(if $CLOSED_BOOK; then echo 'closed-book'; else echo 'open-book'; fi))..."

    docker run "${DOCKER_ARGS[@]}" "$DOCKER_IMAGE" || AGENT_EXIT=$?

    # Collect Docker outputs from isolated results dir
    [[ -f "${TASK_RESULTS_DIR}/task.diff" ]] && mv "${TASK_RESULTS_DIR}/task.diff" "$DIFF_FILE"
    [[ -f "${TASK_RESULTS_DIR}/agent.log" ]] && mv "${TASK_RESULTS_DIR}/agent.log" "$LOG_FILE"
    # Docker .failed marker is authoritative — preserve the category and real exit code
    DOCKER_MARKER_EXISTS=false
    if [[ -f "${TASK_RESULTS_DIR}/task.failed" ]]; then
        DOCKER_MARKER_EXISTS=true
        failed_reason=$(cat "${TASK_RESULTS_DIR}/task.failed")
        mv "${TASK_RESULTS_DIR}/task.failed" "${RESULTS_DIR}/${TASK_SUFFIX}.failed"
        if [[ "$failed_reason" =~ ^AGENT_FAILURE:([0-9]+) ]]; then
            AGENT_EXIT="${match[1]}"
        fi
    elif [[ "$AGENT_EXIT" -ge 125 && "$AGENT_EXIT" -le 127 ]]; then
        # Docker infrastructure failure (125=daemon error, 126=not executable, 127=not found)
        echo "DOCKER_FAILURE:${AGENT_EXIT}" > "${RESULTS_DIR}/${TASK_SUFFIX}.failed"
        DOCKER_MARKER_EXISTS=true
    fi
    [[ -f "${TASK_RESULTS_DIR}/verification.json" ]] && mv "${TASK_RESULTS_DIR}/verification.json" "${RESULTS_DIR}/${TASK_SUFFIX}.verification.json"
    [[ -f "${TASK_RESULTS_DIR}/baseline-verification.json" ]] && mv "${TASK_RESULTS_DIR}/baseline-verification.json" "${RESULTS_DIR}/${TASK_SUFFIX}.baseline-verification.json"
    rm -rf "$TASK_RESULTS_DIR"
    DIFF_LINES=$(wc -l < "$DIFF_FILE" 2>/dev/null | tr -d ' ')

elif [[ "$AGENT_CMD" == "manual" ]]; then
    echo "MANUAL MODE — Work in: ${WORK_DIR}"; echo "Prompt: ${PROMPT}"; echo ""
    read -r "?Press Enter when done... "
    # Collect diff for manual mode
    (cd "$WORK_DIR" && git add -A && git diff --cached --binary -- . ':!Library/' ':!Temp/' ':!Logs/' ':!obj/' > "$DIFF_FILE" 2>/dev/null) || true
    DIFF_LINES=$(wc -l < "$DIFF_FILE" 2>/dev/null | tr -d ' ')
else
    # Local execution path
    echo "Running agent..."
    (cd "$WORK_DIR" && eval "${AGENT_CMD}" '"${PROMPT}"' 2>&1 | tee "$LOG_FILE") || AGENT_EXIT=$?
    echo "Agent exit code: ${AGENT_EXIT}" >> "$LOG_FILE"

    # Collect diff
    (cd "$WORK_DIR" && git add -A && git diff --cached --binary -- . ':!Library/' ':!Temp/' ':!Logs/' ':!obj/' > "$DIFF_FILE" 2>/dev/null) || true
    DIFF_LINES=$(wc -l < "$DIFF_FILE" 2>/dev/null | tr -d ' ')
fi

TASK_END=$(date +%s)
TASK_DURATION=$(( TASK_END - TASK_START ))

# ---- Determine status ----
TASK_STATUS="success"
if [[ "${DOCKER_MARKER_EXISTS:-false}" == "true" ]]; then
    # Docker mode: .failed marker already written with correct category — read it back
    if [[ -f "${RESULTS_DIR}/${TASK_SUFFIX}.failed" ]]; then
        docker_reason=$(cat "${RESULTS_DIR}/${TASK_SUFFIX}.failed")
        case "$docker_reason" in
            NO_CHANGES*)       TASK_STATUS="no_changes"; echo "FAILED: No changes produced (Docker)." ;;
            SETUP_FAILURE*)    TASK_STATUS="setup_failed"; echo "FAILED: Setup script failed (Docker)." ;;
            DOCKER_FAILURE*)   TASK_STATUS="docker_failed"; echo "FAILED: Docker infrastructure error (exit ${AGENT_EXIT})." ;;
            AGENT_FAILURE*)    TASK_STATUS="agent_failed"; echo "FAILED: Agent exited ${AGENT_EXIT} (diff: ${DIFF_LINES:-0} lines)." ;;
            MISSING_ENV*)      TASK_STATUS="agent_failed"; echo "FAILED: Missing environment variables in container." ;;
            *)                 TASK_STATUS="agent_failed"; echo "FAILED: ${docker_reason}" ;;
        esac
    fi
elif [[ "$AGENT_EXIT" -ne 0 ]]; then
    echo "FAILED: Agent exited ${AGENT_EXIT} (diff: ${DIFF_LINES} lines)."
    echo "AGENT_FAILURE:${AGENT_EXIT}:diff_lines=${DIFF_LINES}" > "${RESULTS_DIR}/${TASK_SUFFIX}.failed"
    TASK_STATUS="agent_failed"
elif [[ "${DIFF_LINES:-0}" -eq 0 ]]; then
    echo "FAILED: No changes produced."
    echo "NO_CHANGES" > "${RESULTS_DIR}/${TASK_SUFFIX}.failed"
    TASK_STATUS="no_changes"
else
    echo "Captured: ${DIFF_LINES} diff lines"
    rm -f "${RESULTS_DIR}/${TASK_SUFFIX}.failed"
fi

# ---- Write per-task metadata (use jq if available, fallback to safe escaping) ----
if command -v jq &>/dev/null; then
    jq -n \
        --arg tid "$TASK_ID" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson dur "$TASK_DURATION" \
        --arg acmd "$AGENT_CMD" \
        --arg model "$MODEL_ID" \
        --arg pmode "$PROMPT_MODE" \
        --argjson docker "$($USE_DOCKER && echo true || echo false)" \
        --arg net "$NETWORK_MODE" \
        --argjson aexit "$AGENT_EXIT" \
        --argjson dlines "${DIFF_LINES:-0}" \
        --arg status "$TASK_STATUS" \
        '{task_id:$tid, timestamp:$ts, duration_seconds:$dur, agent_cmd:$acmd, model:$model, prompt_mode:$pmode, docker:$docker, network:$net, agent_exit_code:$aexit, diff_lines:$dlines, status:$status}' \
        > "$META_FILE"
else
    # Fallback: escape quotes in values
    esc_agent=$(echo "$AGENT_CMD" | sed 's/"/\\"/g')
    esc_model=$(echo "$MODEL_ID" | sed 's/"/\\"/g')
    cat > "$META_FILE" << METAEOF
{
  "task_id": "${TASK_ID}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "duration_seconds": ${TASK_DURATION},
  "agent_cmd": "${esc_agent}",
  "model": "${esc_model}",
  "prompt_mode": "${PROMPT_MODE}",
  "docker": $($USE_DOCKER && echo true || echo false),
  "network": "${NETWORK_MODE}",
  "agent_exit_code": ${AGENT_EXIT},
  "diff_lines": ${DIFF_LINES:-0},
  "status": "${TASK_STATUS}"
}
METAEOF
fi

echo ""; echo "Results:"
echo "  Diff: ${DIFF_FILE} (${DIFF_LINES} lines)"
[[ -f "$LOG_FILE" ]] && echo "  Log:  ${LOG_FILE}"
echo "  Meta: ${META_FILE}"
[[ "$TASK_STATUS" != "success" ]] && echo "  Status: FAILED (${TASK_STATUS})"
echo "  Duration: ${TASK_DURATION}s"
echo "============================================================"

# Exit nonzero if task failed
[[ "$TASK_STATUS" != "success" ]] && exit 1
exit 0
