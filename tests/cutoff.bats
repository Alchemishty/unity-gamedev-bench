#!/usr/bin/env bats

load test_helper/common

setup() {
    setup_common
    RESULTS_DIR="${TEST_TEMP}/results/test"
    mkdir -p "$RESULTS_DIR"

    # Install m01 fixture (has merge_date: 2026-01-14)
    mkdir -p "${TEST_BENCH_ROOT}/tasks/real-world/mirror"
    cp "${FIXTURES_DIR}/task-files/m01.md" "${TEST_BENCH_ROOT}/tasks/real-world/mirror/task-m01-syncvar-hook-race.md"
}

teardown() {
    teardown_common
}

@test "post-cutoff filters tasks by merge_date and preserves completeness" {
    # s01 has no merge_date (exempt), m01 has merge_date 2026-01-14
    create_result_diff "$RESULTS_DIR" "s01"
    create_result_diff "$RESULTS_DIR" "m01"
    create_run_request "$RESULTS_DIR" s01 m01

    # Scorer output for just s01 (m01 filtered out)
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    # Cutoff 2026-06-01 excludes m01 (merge_date 2026-01-14 <= cutoff)
    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --post-cutoff 2026-06-01
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"excluded 1 tasks"* ]]
    [[ "$output" == *"Cutoff-exempt"* ]]

    # Manifest should record cutoff
    [ -f "${RESULTS_DIR}/manifest.json" ]
    local cutoff_date
    cutoff_date=$(jq -r '.cutoff.date' "${RESULTS_DIR}/manifest.json")
    [ "$cutoff_date" = "2026-06-01" ]
}

@test "post-cutoff rejects zero-task filtered result" {
    # Only m01, which will be excluded
    create_result_diff "$RESULTS_DIR" "m01"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --post-cutoff 2026-06-01
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"excluded all tasks"* ]]
}

@test "post-cutoff manifest records excluded and exempt IDs" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_result_diff "$RESULTS_DIR" "m01"
    create_run_request "$RESULTS_DIR" s01 m01
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --post-cutoff 2026-06-01
    echo "$output"
    [ "$status" -eq 0 ]

    # Check manifest counts and IDs
    local total valid excluded exempt
    total=$(jq -r '.total_tasks' "${RESULTS_DIR}/manifest.json")
    [ "$total" -eq 1 ]
    excluded=$(jq -r '.cutoff.excluded_ids | length' "${RESULTS_DIR}/manifest.json")
    [ "$excluded" -eq 1 ]
    exempt=$(jq -r '.cutoff.exempt_ids | length' "${RESULTS_DIR}/manifest.json")
    [ "$exempt" -eq 1 ]
    local exempt_id
    exempt_id=$(jq -r '.cutoff.exempt_ids[0]' "${RESULTS_DIR}/manifest.json")
    [ "$exempt_id" = "s01" ]
}

@test "post-cutoff recomputes valid/failed counts" {
    # s01 valid, m01 valid but excluded, s02 failed
    create_result_diff "$RESULTS_DIR" "s01"
    create_result_diff "$RESULTS_DIR" "m01"
    create_result_diff "$RESULTS_DIR" "s02" ""
    create_result_failed "$RESULTS_DIR" "s02" "AGENT_FAILURE:1"
    cp "${FIXTURES_DIR}/task-files/s01.md" "${TEST_BENCH_ROOT}/tasks/synthetic/task-02-test.md"

    # Scorer for s01 (75%) and s02 (0%)
    local scorer="${TEST_TEMP}/cutoff-scorer.md"
    cat > "$scorer" << 'EOF'
## Task s01: Test Inventory System

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 8/10 | Works |
| Robustness | 7/10 | Good |
| Readability | 8/10 | Clear |
| Architecture | 7/10 | Clean |
| Domain Correctness | 7/10 | Correct |
| Test Quality | 8/10 | Good |
| **Task Total** | **45/60** | |

## Task s02: Test Task 2

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 0/10 | Failed |
| Robustness | 0/10 | Failed |
| Readability | 0/10 | Failed |
| Architecture | 0/10 | Failed |
| Domain Correctness | 0/10 | Failed |
| Test Quality | 0/10 | Failed |
| **Task Total** | **0/60** | |

## Final Score

**unity-gamedev-bench score: 37% (45/120)**
EOF
    create_fake_claude "$scorer"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --post-cutoff 2026-06-01
    echo "$output"
    [ "$status" -eq 0 ]

    local valid failed
    valid=$(jq -r '.valid_tasks' "${RESULTS_DIR}/manifest.json")
    failed=$(jq -r '.failed_tasks' "${RESULTS_DIR}/manifest.json")
    [ "$valid" -eq 1 ]
    [ "$failed" -eq 1 ]
}

@test "post-cutoff succeeds when missing requested task predates cutoff" {
    # Requested: s01 + m01, but only s01 has results
    # m01 (merge_date 2026-01-14) predates cutoff — should be excluded, not missing
    create_result_diff "$RESULTS_DIR" "s01"
    create_run_request "$RESULTS_DIR" s01 m01
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --post-cutoff 2026-06-01
    echo "$output"
    [ "$status" -eq 0 ]
    # Should be a complete filtered run, not partial
    [[ "$output" != *"ERROR"* ]]
    [[ "$output" != *"--allow-partial"* ]]

    # Manifest should show m01 in cutoff.excluded_ids
    local excluded
    excluded=$(jq -r '.cutoff.excluded_ids[0]' "${RESULTS_DIR}/manifest.json")
    [ "$excluded" = "m01" ]

    # run_type should be full (not partial)
    local run_type
    run_type=$(jq -r '.run_type' "${RESULTS_DIR}/manifest.json")
    [ "$run_type" = "full" ]
}
