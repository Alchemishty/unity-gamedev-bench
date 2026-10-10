#!/usr/bin/env zsh
set -uo pipefail

# ============================================================
# unity-gamedev-bench — Smoke test: validate task preparation
# ============================================================
# Prepares every task's working directory without invoking an agent.
# Verifies that cloning, checkout, scrubbing, and baseline creation
# all succeed, and that the resulting workspace is clean.

usage() {
    cat <<EOF
Usage: ./scripts/smoke-test.sh [task_ids...]

Validates that every task can be prepared successfully.
With no arguments, tests all tasks. Pass specific IDs to test a subset.

Example:
  ./scripts/smoke-test.sh            # all tasks
  ./scripts/smoke-test.sh s01 m01    # just these two
EOF
    exit "${1:-0}"
}

[[ "${1:-}" == "--help" ]] && usage 0

BENCH_ROOT="${0:A:h:h}"

# ---- Task file resolver (from run-task.sh) ----
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

extract_meta() {
    local file="$1" key="$2"
    sed -n '/^<!--/,/^-->/p' "$file" 2>/dev/null | grep -m1 "^${key}:" 2>/dev/null | sed "s/^${key}: *//" || echo ""
}

extract_field() {
    local file="$1" key="$2"
    grep -m1 "^\*\*${key}:\*\*" "$file" 2>/dev/null | sed "s/^\*\*${key}:\*\* *//" | sed 's/ *$//' || echo ""
}

# ---- Discover all tasks (from run-all.sh) ----
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

# ---- Build task list ----
TASKS=()
if [[ $# -gt 0 ]]; then
    TASKS=("$@")
else
    TASKS=($(discover_source_tasks "${BENCH_ROOT}/tasks/synthetic"))
    for dir in "${BENCH_ROOT}"/tasks/real-world/*(N/); do
        TASKS+=($(discover_source_tasks "$dir"))
    done
fi

if [[ ${#TASKS[@]} -eq 0 ]]; then
    echo "Error: No tasks found."
    exit 1
fi

TOTAL=${#TASKS[@]}
PASSED=0 FAILED=0 FAILED_IDS=()

echo "============================================================"
echo "  unity-gamedev-bench smoke test — ${TOTAL} tasks"
echo "  $(date)"
echo "============================================================"

CACHE_DIR="${BENCH_ROOT}/.cache/repos"
mkdir -p "$CACHE_DIR"

for i in $(seq 1 $TOTAL); do
    task_id="${TASKS[$i]}"
    TASK_FILE=$(resolve_task_file "$task_id")

    if [[ -z "$TASK_FILE" || ! -f "$TASK_FILE" ]]; then
        echo "  [${i}/${TOTAL}] ${task_id}: FAIL (task file not found)"
        ((FAILED++))
        FAILED_IDS+=("$task_id")
        continue
    fi

    WORK_DIR=$(mktemp -d)
    TASK_OK=true
    FAIL_REASON=""

    TASK_REPO=$(extract_meta "$TASK_FILE" "repo")
    [[ -z "$TASK_REPO" ]] && TASK_REPO=$(extract_field "$TASK_FILE" "Repo")
    TASK_BASE_SHA=$(extract_meta "$TASK_FILE" "base_sha")
    [[ -z "$TASK_BASE_SHA" ]] && TASK_BASE_SHA=$(extract_field "$TASK_FILE" "Base Commit")

    if [[ -z "$TASK_REPO" ]]; then
        TASK_OK=false; FAIL_REASON="no repo metadata"
    elif [[ -z "$TASK_BASE_SHA" || "$TASK_BASE_SHA" == "Parent of"* || "$TASK_BASE_SHA" == *"TBD"* ]]; then
        TASK_OK=false; FAIL_REASON="no usable base commit (got: '${TASK_BASE_SHA}')"
    else
        cache_name=$(echo "$TASK_REPO" | sed 's|https://github.com/||' | tr '/' '_' | sed 's/\.git$//')
        CACHED_REPO="${CACHE_DIR}/${cache_name}"

        if [[ ! -d "$CACHED_REPO/.git" ]]; then
            if ! git clone -q "$TASK_REPO" "$CACHED_REPO" 2>/dev/null; then
                TASK_OK=false; FAIL_REASON="clone failed"
            fi
        else
            git -C "$CACHED_REPO" fetch -q 2>/dev/null || true
        fi

        if $TASK_OK; then
            if ! cp -R "${CACHED_REPO}/." "${WORK_DIR}/"; then
                TASK_OK=false; FAIL_REASON="copy from cache failed"
            elif ! (cd "$WORK_DIR" && git checkout -q "$TASK_BASE_SHA" 2>/dev/null); then
                TASK_OK=false; FAIL_REASON="checkout ${TASK_BASE_SHA} failed"
            else
                rm -rf "${WORK_DIR}/.git"
                if ! (cd "$WORK_DIR" && git init -q && git add -A && git -c user.name="Benchmark" -c user.email="benchmark@invalid" commit -q -m "baseline" 2>/dev/null); then
                    TASK_OK=false; FAIL_REASON="baseline commit failed"
                fi
            fi
        fi
    fi

    # Verify workspace integrity
    if $TASK_OK; then
        REMOTE_COUNT=$(cd "$WORK_DIR" && git remote 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$REMOTE_COUNT" -ne 0 ]]; then
            TASK_OK=false; FAIL_REASON="remotes still present (${REMOTE_COUNT})"
        fi
    fi

    if $TASK_OK; then
        COMMIT_COUNT=$(cd "$WORK_DIR" && git log --oneline 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$COMMIT_COUNT" -ne 1 ]]; then
            TASK_OK=false; FAIL_REASON="expected 1 commit, found ${COMMIT_COUNT}"
        fi
    fi

    rm -rf "$WORK_DIR"

    if $TASK_OK; then
        echo "  [${i}/${TOTAL}] ${task_id}: PASS"
        ((PASSED++))
    else
        echo "  [${i}/${TOTAL}] ${task_id}: FAIL (${FAIL_REASON})"
        ((FAILED++))
        FAILED_IDS+=("$task_id")
    fi
done

echo ""
echo "============================================================"
echo "  Passed: ${PASSED}/${TOTAL}"
[[ $FAILED -gt 0 ]] && echo "  Failed: ${FAILED_IDS[*]}"
echo "============================================================"

[[ $FAILED -gt 0 ]] && exit 1
exit 0
