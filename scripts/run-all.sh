#!/usr/bin/env zsh
set -uo pipefail

# ============================================================
# unity-gamedev-bench — Run multiple tasks
# ============================================================

usage() {
    cat <<EOF
Usage: ./scripts/run-all.sh --agent <command> --label <name> [options] [task_ids...]

Filters (pick one, or give explicit task IDs):
  --all               All scored tasks (default)
  --synthetic         Only s01-s07
  --source <name>     Only from a source (mirror, ngo, bossroom, unityhfsm, vcontainer, litmotion, unitask, inputsystem, crest)
  task_ids...         Explicit: m01 m03 b02 s01 h01

Options:
  --agent <cmd>       Agent CLI command (required)
  --label <name>      Results directory label (required)
  --setup <script>    Setup script passed to each run-task.sh call
  --prompt-mode <m>   'guided' (default) or 'diagnostic'
  --model <id>        Model identifier for metadata
  --docker            Run agent inside Docker sandbox
  --docker-image <i>  Docker image (default: ugb-sandbox, or ugb-unity)
  --closed-book       Docker + no network (implies --docker)
  --help              Show this help
EOF
    exit "${1:-0}"
}

AGENT_CMD="" LABEL="" SETUP_SCRIPT="" FILTER="" SOURCE="" PROMPT_MODE="guided"
MODEL_ID="unknown" USE_DOCKER=false CLOSED_BOOK=false DOCKER_IMAGE="" EXPLICIT_IDS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --agent)       AGENT_CMD="$2"; shift 2 ;;
        --label)       LABEL="$2"; shift 2 ;;
        --setup)       SETUP_SCRIPT="$2"; shift 2 ;;
        --all)         FILTER="all"; shift ;;
        --synthetic)   FILTER="synthetic"; shift ;;
        --source)      FILTER="source"; SOURCE="$2"; shift 2 ;;
        --prompt-mode) PROMPT_MODE="$2"; shift 2 ;;
        --model)       MODEL_ID="$2"; shift 2 ;;
        --docker)      USE_DOCKER=true; shift ;;
        --docker-image) DOCKER_IMAGE="$2"; USE_DOCKER=true; shift 2 ;;
        --closed-book) USE_DOCKER=true; CLOSED_BOOK=true; shift ;;
        --help)        usage 0 ;;
        -*)            echo "Error: Unknown option: $1"; usage 1 ;;
        *)             EXPLICIT_IDS+=("$1"); shift ;;
    esac
done

[[ -z "$AGENT_CMD" || -z "$LABEL" ]] && { echo "Error: --agent and --label required."; usage 1; }

BENCH_ROOT="${0:A:h:h}"
SCRIPT_DIR="${BENCH_ROOT}/scripts"

# ---- Discover tasks from filesystem ----
discover_source_tasks() {
    local source_dir="$1"
    for f in "${source_dir}"/*.md(N); do
        local base=$(basename "$f" .md)
        case "$base" in
            task-[0-9]*)   local num=$(echo "$base" | grep -o '[0-9][0-9]' | head -1); echo "s${num}" ;;
            task-m[0-9]*)  local num=$(echo "$base" | grep -o 'm[0-9][0-9]' | sed 's/m//'); echo "m${num}" ;;
            ngo-[0-9]*)    local num=$(echo "$base" | grep -o '[0-9][0-9]' | head -1); echo "n${num}" ;;
            br-[0-9]*)     local num=$(echo "$base" | grep -o '[0-9][0-9]' | head -1); echo "b${num}" ;;
            h[0-9]*)       echo "${base%%-*}" ;;
            v[0-9]*)       echo "${base%%-*}" ;;
            l[0-9]*)       echo "${base%%-*}" ;;
            u[0-9]*)       echo "${base%%-*}" ;;
            i[0-9]*)       echo "${base%%-*}" ;;
            c[0-9]*)       echo "${base%%-*}" ;;
        esac
    done
}

source_to_dir() {
    case "$1" in
        synthetic)   echo "${BENCH_ROOT}/tasks/synthetic" ;;
        mirror)      echo "${BENCH_ROOT}/tasks/real-world/mirror" ;;
        ngo)         echo "${BENCH_ROOT}/tasks/real-world/ngo" ;;
        bossroom)    echo "${BENCH_ROOT}/tasks/real-world/bossroom" ;;
        unityhfsm)   echo "${BENCH_ROOT}/tasks/real-world/unityhfsm" ;;
        vcontainer)  echo "${BENCH_ROOT}/tasks/real-world/vcontainer" ;;
        litmotion)   echo "${BENCH_ROOT}/tasks/real-world/litmotion" ;;
        unitask)     echo "${BENCH_ROOT}/tasks/real-world/unitask" ;;
        inputsystem) echo "${BENCH_ROOT}/tasks/real-world/inputsystem" ;;
        crest)       echo "${BENCH_ROOT}/tasks/real-world/crest" ;;
        *) echo ""; return 1 ;;
    esac
}

# ---- Build task list ----
TASKS=()

if [[ ${#EXPLICIT_IDS[@]} -gt 0 ]]; then
    TASKS=("${EXPLICIT_IDS[@]}")
elif [[ "$FILTER" == "synthetic" ]]; then
    TASKS=($(discover_source_tasks "${BENCH_ROOT}/tasks/synthetic"))
elif [[ "$FILTER" == "source" ]]; then
    src_dir=$(source_to_dir "$SOURCE")
    if [[ -z "$src_dir" || ! -d "$src_dir" ]]; then
        echo "Error: Unknown source '${SOURCE}'."
        echo "Available: $(ls -1 "${BENCH_ROOT}/tasks/real-world/" 2>/dev/null | tr '\n' ' ')"
        exit 1
    fi
    TASKS=($(discover_source_tasks "$src_dir"))
else
    TASKS=($(discover_source_tasks "${BENCH_ROOT}/tasks/synthetic"))
    for dir in "${BENCH_ROOT}"/tasks/real-world/*(N/); do
        TASKS+=($(discover_source_tasks "$dir"))
    done
fi

if [[ ${#TASKS[@]} -eq 0 ]]; then
    echo "Error: No tasks found for the given filter."
    exit 1
fi

TOTAL=${#TASKS[@]}
SUCCEEDED=0 FAILED=0 FAILED_IDS=()

NETWORK_MODE="enabled"
$CLOSED_BOOK && NETWORK_MODE="disabled"

echo "============================================================"
echo "  unity-gamedev-bench — ${TOTAL} tasks"
echo "  Agent: ${AGENT_CMD} | Label: ${LABEL} | Model: ${MODEL_ID}"
$USE_DOCKER && echo "  Docker: yes | Network: ${NETWORK_MODE}"
echo "  Prompt mode: ${PROMPT_MODE}"
echo "  $(date)"
echo "============================================================"

# Check for existing results label (prevent stale artifact contamination)
RESULTS_LABEL_DIR="${BENCH_ROOT}/results/${LABEL}"
if [[ -d "$RESULTS_LABEL_DIR" ]]; then
    STALE_DIFFS=(${RESULTS_LABEL_DIR}/*.diff(N))
    STALE_FAILED=(${RESULTS_LABEL_DIR}/*.failed(N))
    if [[ ${#STALE_DIFFS[@]} -gt 0 || ${#STALE_FAILED[@]} -gt 0 ]]; then
        echo "Error: Results directory '${LABEL}' already contains task artifacts."
        [[ ${#STALE_DIFFS[@]} -gt 0 ]] && echo "  .diff files: ${#STALE_DIFFS[@]}"
        [[ ${#STALE_FAILED[@]} -gt 0 ]] && echo "  .failed files: ${#STALE_FAILED[@]}"
        echo "  Use a new label, or remove the existing directory first:"
        echo "  rm -rf ${RESULTS_LABEL_DIR}"
        exit 1
    fi
fi

# Write run-request manifest so score.sh knows what was intended
RUN_REQUEST_FILE="${RESULTS_LABEL_DIR}/run-request.json"
mkdir -p "$RESULTS_LABEL_DIR"
if command -v jq &>/dev/null; then
    jq -n \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson total "$TOTAL" \
        --argjson task_ids "$(printf '%s\n' "${TASKS[@]}" | jq -R . | jq -s .)" \
        --arg agent "$AGENT_CMD" \
        --arg label "$LABEL" \
        --arg model "$MODEL_ID" \
        --arg filter "${FILTER:-all}" \
        --argjson docker "$($USE_DOCKER && echo true || echo false)" \
        --arg network "$NETWORK_MODE" \
        --arg prompt_mode "$PROMPT_MODE" \
        '{timestamp:$ts, requested_tasks:$total, task_ids:$task_ids, agent:$agent, label:$label, model:$model, filter:$filter, track:{docker:$docker, network:$network, prompt_mode:$prompt_mode, model:$model}}' \
        > "$RUN_REQUEST_FILE"
else
    cat > "$RUN_REQUEST_FILE" << REOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "requested_tasks": ${TOTAL},
  "task_ids": [$(printf '"%s",' "${TASKS[@]}" | sed 's/,$//')],
  "agent": "$(echo "$AGENT_CMD" | sed 's/"/\\"/g')",
  "label": "${LABEL}",
  "model": "${MODEL_ID}",
  "filter": "${FILTER:-all}",
  "track": {
    "docker": $($USE_DOCKER && echo true || echo false),
    "network": "${NETWORK_MODE}",
    "prompt_mode": "${PROMPT_MODE}",
    "model": "${MODEL_ID}"
  }
}
REOF
fi
echo "  Run request: ${RUN_REQUEST_FILE}"

EXTRA_ARGS=()
[[ -n "$SETUP_SCRIPT" ]] && EXTRA_ARGS+=(--setup "$SETUP_SCRIPT")
[[ "$PROMPT_MODE" != "guided" ]] && EXTRA_ARGS+=(--prompt-mode "$PROMPT_MODE")
[[ "$MODEL_ID" != "unknown" ]] && EXTRA_ARGS+=(--model "$MODEL_ID")
$USE_DOCKER && EXTRA_ARGS+=(--docker)
[[ -n "$DOCKER_IMAGE" ]] && EXTRA_ARGS+=(--docker-image "$DOCKER_IMAGE")
$CLOSED_BOOK && EXTRA_ARGS+=(--closed-book)

for i in $(seq 1 $TOTAL); do
    task="${TASKS[$i]}"
    echo ""
    echo "[${i}/${TOTAL}] Running ${task}..."

    if zsh "${SCRIPT_DIR}/run-task.sh" "$task" --agent "$AGENT_CMD" --label "$LABEL" "${EXTRA_ARGS[@]}"; then
        ((SUCCEEDED++))
    else
        ((FAILED++))
        FAILED_IDS+=("$task")
        echo "WARNING: Task ${task} failed"
    fi
done

echo ""
echo "============================================================"
echo "  COMPLETE — $(date)"
echo "  Succeeded: ${SUCCEEDED}/${TOTAL}"
[[ $FAILED -gt 0 ]] && echo "  Failed: ${FAILED_IDS[*]}"
echo "  Results: ${BENCH_ROOT}/results/${LABEL}/"
echo ""
echo "  Score with: ./scripts/score.sh results/${LABEL}/"
echo "============================================================"

[[ $FAILED -gt 0 ]] && exit 1
exit 0
