#!/usr/bin/env bats

REAL_BENCH_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

@test "standard suite exists and has 10 tasks" {
    local suite="${REAL_BENCH_ROOT}/suites/standard.json"
    [ -f "$suite" ]
    local count
    count=$(jq '.task_count' "$suite")
    [ "$count" -eq 10 ]
    local actual
    actual=$(jq '.tasks | length' "$suite")
    [ "$actual" -eq 10 ]
}

@test "smoke suite exists and has 3 tasks" {
    local suite="${REAL_BENCH_ROOT}/suites/smoke.json"
    [ -f "$suite" ]
    local count
    count=$(jq '.task_count' "$suite")
    [ "$count" -eq 3 ]
}

@test "smoke tasks are a subset of standard tasks" {
    local standard="${REAL_BENCH_ROOT}/suites/standard.json"
    local smoke="${REAL_BENCH_ROOT}/suites/smoke.json"
    local missing=()
    while IFS= read -r tid; do
        if ! jq -e --arg t "$tid" '.tasks | index($t)' "$standard" >/dev/null 2>&1; then
            missing+=("$tid")
        fi
    done < <(jq -r '.tasks[]' "$smoke")
    echo "Not in standard: ${missing[*]:-none}"
    [ "${#missing[@]}" -eq 0 ]
}

@test "all suite versions are set" {
    for suite in "${REAL_BENCH_ROOT}"/suites/*.json; do
        local ver
        ver=$(jq -r '.version' "$suite")
        [[ -n "$ver" && "$ver" != "null" ]]
    done
}
