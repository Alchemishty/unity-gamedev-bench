#!/usr/bin/env bats

# Validates rubric declarations for the standard suite tasks

REAL_BENCH_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

resolve_task_file() {
    local id="$1"
    local prefix="${id%%[0-9]*}"
    local num="${id#${prefix}}"
    local p="$(printf '%02d' "$((10#$num))" 2>/dev/null || echo "$num")"
    local f=""
    case "$prefix" in
        s) f=$(find "${REAL_BENCH_ROOT}/tasks/synthetic" -name "task-${p}-*.md" 2>/dev/null | head -1) ;;
        m) f=$(find "${REAL_BENCH_ROOT}/tasks/real-world/mirror" -name "task-m${p}-*.md" 2>/dev/null | head -1) ;;
        *) echo ""; return ;;
    esac
    [[ -n "$f" && -f "$f" ]] && echo "$f" || echo ""
}

@test "all standard suite tasks have rubric declarations" {
    local suite="${REAL_BENCH_ROOT}/suites/standard.json"
    [ -f "$suite" ]
    local missing=()
    local count=0
    while IFS= read -r tid; do
        ((++count))
        local f
        f=$(resolve_task_file "$tid")
        if [[ -z "$f" || ! -f "$f" ]]; then
            missing+=("${tid}: no task file")
            continue
        fi
        local rubrics
        rubrics=$(sed -n '/^<!--/,/^-->/p' "$f" 2>/dev/null | grep -m1 "^rubrics:" | sed "s/^rubrics: *//" || echo "")
        if [[ -z "$rubrics" ]]; then
            missing+=("${tid}: no rubrics")
        fi
    done < <(jq -r '.tasks[]' "$suite")
    echo "Checked: ${count}, Missing: ${missing[*]:-none}"
    [ "$count" -eq 10 ]
    [ "${#missing[@]}" -eq 0 ]
}

@test "all standard suite tasks have difficulty metadata" {
    local suite="${REAL_BENCH_ROOT}/suites/standard.json"
    local missing=()
    while IFS= read -r tid; do
        local f
        f=$(resolve_task_file "$tid")
        [[ -z "$f" ]] && continue
        local diff
        diff=$(sed -n '/^<!--/,/^-->/p' "$f" 2>/dev/null | grep -m1 "^difficulty:" | sed "s/^difficulty: *//" || echo "")
        if [[ -z "$diff" ]]; then
            missing+=("$tid")
        fi
    done < <(jq -r '.tasks[]' "$suite")
    echo "Missing difficulty: ${missing[*]:-none}"
    [ "${#missing[@]}" -eq 0 ]
}

@test "every rubric declaration includes correctness" {
    local suite="${REAL_BENCH_ROOT}/suites/standard.json"
    local missing=()
    while IFS= read -r tid; do
        local f
        f=$(resolve_task_file "$tid")
        [[ -z "$f" ]] && continue
        local rubrics
        rubrics=$(sed -n '/^<!--/,/^-->/p' "$f" 2>/dev/null | grep -m1 "^rubrics:" | sed "s/^rubrics: *//" || echo "")
        if [[ ! "$rubrics" == *"correctness"* ]]; then
            missing+=("$tid")
        fi
    done < <(jq -r '.tasks[]' "$suite")
    echo "Missing correctness: ${missing[*]:-none}"
    [ "${#missing[@]}" -eq 0 ]
}
