#!/usr/bin/env zsh
set -uo pipefail

# ============================================================
# unity-gamedev-bench v0.1 — Run benchmark suite
# ============================================================

usage() {
    cat <<EOF
Usage: ./scripts/run-all.sh --agent <command> --label <name> [options] [task_ids...]

Suite selection (pick one):
  --suite <name>        Load suite from suites/<name>.json (default: standard)
  task_ids...           Explicit task IDs override suite

Options:
  --agent <cmd>         Agent CLI command (required)
  --label <name>        Results directory label (required)
  --parallel <n>        Concurrent tasks (default: 3, use 1 for sequential)
  --setup <script>      Setup script passed to each task
  --prompt-mode <m>     'guided' (default) or 'diagnostic'
  --model <id>          Model identifier for metadata
  --docker              Run agent inside Docker sandbox
  --docker-image <i>    Docker image (default: ugb-sandbox)
  --closed-book         Docker + no network (implies --docker)
  --help                Show this help
EOF
    exit "${1:-0}"
}

AGENT_CMD="" LABEL="" SETUP_SCRIPT="" SUITE_NAME="standard" PROMPT_MODE="guided"
MODEL_ID="unknown" USE_DOCKER=false CLOSED_BOOK=false DOCKER_IMAGE=""
PARALLEL=3 EXPLICIT_IDS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --agent)        AGENT_CMD="$2"; shift 2 ;;
        --label)        LABEL="$2"; shift 2 ;;
        --setup)        SETUP_SCRIPT="$2"; shift 2 ;;
        --suite)        SUITE_NAME="$2"; shift 2 ;;
        --parallel)     PARALLEL="$2"; shift 2 ;;
        --prompt-mode)  PROMPT_MODE="$2"; shift 2 ;;
        --model)        MODEL_ID="$2"; shift 2 ;;
        --docker)       USE_DOCKER=true; shift ;;
        --docker-image) DOCKER_IMAGE="$2"; USE_DOCKER=true; shift 2 ;;
        --closed-book)  USE_DOCKER=true; CLOSED_BOOK=true; shift ;;
        --help)         usage 0 ;;
        -*)             echo "Error: Unknown option: $1"; usage 1 ;;
        *)              EXPLICIT_IDS+=("$1"); shift ;;
    esac
done

[[ -z "$AGENT_CMD" || -z "$LABEL" ]] && { echo "Error: --agent and --label required."; usage 1; }
[[ "$PARALLEL" -lt 1 ]] && PARALLEL=1

BENCH_ROOT="${0:A:h:h}"
SCRIPT_DIR="${BENCH_ROOT}/scripts"

# ---- Load suite or explicit IDs ----
SUITE_VERSION=""
SUITE_FILE=""
TASKS=()

if [[ ${#EXPLICIT_IDS[@]} -gt 0 ]]; then
    TASKS=("${EXPLICIT_IDS[@]}")
    SUITE_NAME="custom"
    SUITE_VERSION="custom"
else
    SUITE_FILE="${BENCH_ROOT}/suites/${SUITE_NAME}.json"
    [[ ! -f "$SUITE_FILE" ]] && { echo "Error: Suite not found: ${SUITE_FILE}"; exit 1; }
    if command -v jq &>/dev/null; then
        SUITE_VERSION=$(jq -r '.version' "$SUITE_FILE")
        while IFS= read -r tid; do TASKS+=("$tid"); done < <(jq -r '.tasks[]' "$SUITE_FILE")
    else
        echo "Error: jq required to read suite files"; exit 1
    fi
fi

[[ ${#TASKS[@]} -eq 0 ]] && { echo "Error: No tasks in suite."; exit 1; }
TOTAL=${#TASKS[@]}

NETWORK_MODE="enabled"
$CLOSED_BOOK && NETWORK_MODE="disabled"

echo "============================================================"
echo "  unity-gamedev-bench v0.1"
echo "  Suite: ${SUITE_NAME} (${SUITE_VERSION}) — ${TOTAL} tasks"
echo "  Agent: ${AGENT_CMD}"
echo "  Model: ${MODEL_ID} | Parallel: ${PARALLEL}"
$USE_DOCKER && echo "  Docker: yes | Network: ${NETWORK_MODE}"
echo "  $(date)"
echo "============================================================"

# ---- Check for stale results ----
RESULTS_DIR="${BENCH_ROOT}/results/${LABEL}"
if [[ -d "$RESULTS_DIR" ]]; then
    STALE_DIFFS=(${RESULTS_DIR}/*.diff(N))
    STALE_FAILED=(${RESULTS_DIR}/*.failed(N))
    if [[ ${#STALE_DIFFS[@]} -gt 0 || ${#STALE_FAILED[@]} -gt 0 ]]; then
        echo "Error: Results directory '${LABEL}' already contains task artifacts."
        echo "  rm -rf ${RESULTS_DIR}"
        exit 1
    fi
fi
mkdir -p "$RESULTS_DIR"

# ---- Task file resolver (needed for snapshot prep) ----
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

extract_meta_from_file() {
    sed -n '/^<!--/,/^-->/p' "$1" 2>/dev/null | grep -m1 "^${2}:" 2>/dev/null | sed "s/^${2}: *//" || echo ""
}

# ---- Serial snapshot preparation ----
echo ""
echo "Preparing snapshots..."

CACHE_DIR="${BENCH_ROOT}/.cache/repos"
SNAPSHOT_BASE=$(mktemp -d)
typeset -A TASK_SNAPSHOT  # maps task_id → snapshot dir
typeset -A REPO_SHA_DONE  # dedup key = "repo|sha"

for task_id in "${TASKS[@]}"; do
    task_file=$(resolve_task_file "$task_id")
    [[ -z "$task_file" || ! -f "$task_file" ]] && { echo "  Error: No task file for ${task_id}"; exit 1; }

    repo=$(extract_meta_from_file "$task_file" "repo")
    sha=$(extract_meta_from_file "$task_file" "base_sha")
    [[ -z "$repo" || -z "$sha" ]] && { echo "  Error: ${task_id} missing repo or base_sha"; exit 1; }

    dedup_key="${repo}|${sha}"
    if [[ -n "${REPO_SHA_DONE[$dedup_key]:-}" ]]; then
        TASK_SNAPSHOT[$task_id]="${REPO_SHA_DONE[$dedup_key]}"
        echo "  ${task_id}: reusing snapshot (same repo+sha)"
        continue
    fi

    cache_name=$(echo "$repo" | sed 's|https://github.com/||' | tr '/' '_' | sed 's/\.git$//')
    cached_repo="${CACHE_DIR}/${cache_name}"
    mkdir -p "$CACHE_DIR"

    if [[ -d "$cached_repo/.git" ]]; then
        git -C "$cached_repo" fetch -q 2>/dev/null || true
    else
        echo "  Cloning ${cache_name}..."
        if ! git clone -q "$repo" "$cached_repo"; then
            echo "  Error: Clone failed for ${repo}"; exit 1
        fi
    fi

    snapshot_dir="${SNAPSHOT_BASE}/${task_id}"
    mkdir -p "$snapshot_dir"
    if ! cp -R "${cached_repo}/." "${snapshot_dir}/"; then
        echo "  Error: Copy failed for ${task_id}"; exit 1
    fi
    if ! (cd "$snapshot_dir" && git checkout -q "$sha" 2>/dev/null); then
        echo "  Error: Checkout ${sha} failed for ${task_id}"; exit 1
    fi

    TASK_SNAPSHOT[$task_id]="$snapshot_dir"
    REPO_SHA_DONE[$dedup_key]="$snapshot_dir"
    echo "  ${task_id}: snapshot ready"
done

echo "  All ${TOTAL} snapshots prepared."

# ---- Write run-request.json ----
RUN_REQUEST_FILE="${RESULTS_DIR}/run-request.json"
if command -v jq &>/dev/null; then
    jq -n \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg suite "$SUITE_NAME" \
        --arg suite_ver "$SUITE_VERSION" \
        --argjson total "$TOTAL" \
        --argjson parallel "$PARALLEL" \
        --argjson task_ids "$(printf '%s\n' "${TASKS[@]}" | jq -R . | jq -s .)" \
        --arg agent "$AGENT_CMD" \
        --arg label "$LABEL" \
        --arg model "$MODEL_ID" \
        --arg pmode "$PROMPT_MODE" \
        --argjson docker "$($USE_DOCKER && echo true || echo false)" \
        --arg network "$NETWORK_MODE" \
        '{timestamp:$ts, suite:$suite, suite_version:$suite_ver, requested_tasks:$total, parallel:$parallel, task_ids:$task_ids, agent:$agent, label:$label, model:$model, prompt_mode:$pmode, docker:$docker, network:$network}' \
        > "$RUN_REQUEST_FILE"
fi

# ---- Build extra args for run-task.sh ----
EXTRA_ARGS=()
[[ -n "$SETUP_SCRIPT" ]] && EXTRA_ARGS+=(--setup "$SETUP_SCRIPT")
[[ "$PROMPT_MODE" != "guided" ]] && EXTRA_ARGS+=(--prompt-mode "$PROMPT_MODE")
[[ "$MODEL_ID" != "unknown" ]] && EXTRA_ARGS+=(--model "$MODEL_ID")
$USE_DOCKER && EXTRA_ARGS+=(--docker)
[[ -n "$DOCKER_IMAGE" ]] && EXTRA_ARGS+=(--docker-image "$DOCKER_IMAGE")
$CLOSED_BOOK && EXTRA_ARGS+=(--closed-book)

# ---- Execute tasks (parallel or sequential) ----
echo ""
echo "Running ${TOTAL} tasks (parallel: ${PARALLEL})..."
echo ""

typeset -A PID_TASK  # maps PID → task_id
RUNNING=0
SUCCEEDED=0
FAILED=0
INFRA_ERRORS=0
FAILED_IDS=()

collect_finished() {
    # Wait for one child to finish and record its result
    local pid
    for pid in ${(k)PID_TASK}; do
        if ! kill -0 "$pid" 2>/dev/null; then
            wait "$pid" 2>/dev/null
            local exit_code=$?
            local tid="${PID_TASK[$pid]}"
            unset "PID_TASK[$pid]"
            ((RUNNING--))
            if [[ $exit_code -eq 0 ]]; then
                ((SUCCEEDED++))
            elif [[ $exit_code -eq 2 ]]; then
                ((INFRA_ERRORS++))
                FAILED_IDS+=("${tid}(infra)")
            else
                ((FAILED++))
                FAILED_IDS+=("$tid")
            fi
            return
        fi
    done
    # All still running — wait briefly
    sleep 0.5
}

for task_id in "${TASKS[@]}"; do
    # Wait until a slot is available
    while [[ $RUNNING -ge $PARALLEL ]]; do
        collect_finished
    done

    snapshot="${TASK_SNAPSHOT[$task_id]}"
    zsh "${SCRIPT_DIR}/run-task.sh" "$task_id" \
        --agent "$AGENT_CMD" --label "$LABEL" \
        --snapshot-dir "$snapshot" \
        "${EXTRA_ARGS[@]}" &

    PID_TASK[$!]="$task_id"
    ((RUNNING++))
done

# Wait for all remaining
while [[ $RUNNING -gt 0 ]]; do
    collect_finished
done

# Cleanup snapshots
rm -rf "$SNAPSHOT_BASE"

WALL_END=$(date +%s)
WALL_START=$(date -j -f "%a %b %d %T %Z %Y" "$(head -1 "$RUN_REQUEST_FILE" 2>/dev/null | jq -r '.timestamp' 2>/dev/null | sed 's/T/ /;s/Z//' | xargs -I{} date -j -f "%Y-%m-%d %H:%M:%S" "{}" "+%a %b %d %T %Z %Y" 2>/dev/null)" "+%s" 2>/dev/null || echo "$TASK_START")
TOTAL_TIME=$(( $(date +%s) - TASK_START ))

echo ""
echo "============================================================"
echo "  COMPLETE — $(date)"
echo "  Succeeded: ${SUCCEEDED}/${TOTAL}"
[[ $FAILED -gt 0 ]] && echo "  Agent failures: ${FAILED}"
[[ $INFRA_ERRORS -gt 0 ]] && echo "  Infrastructure errors: ${INFRA_ERRORS}"
[[ ${#FAILED_IDS[@]} -gt 0 ]] && echo "  Failed: ${FAILED_IDS[*]}"
echo "  Results: ${RESULTS_DIR}/"
echo ""
echo "  Score: ./scripts/score.sh results/${LABEL} --auto"
echo "============================================================"

[[ $INFRA_ERRORS -gt 0 ]] && exit 2
[[ $FAILED -gt 0 ]] && exit 1
exit 0
