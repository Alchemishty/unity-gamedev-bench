#!/usr/bin/env bats

load test_helper/common

setup() {
    setup_common
    RESULTS_DIR="${TEST_TEMP}/results/test"
    mkdir -p "$RESULTS_DIR"
}

teardown() {
    teardown_common
}

@test "valid single-task scorer output produces exact expected score" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"75%"* ]]
    [[ "$output" == *"45/"* ]]
}

@test "incomplete scorer output fails validation" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/incomplete.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
}

@test "unknown task IDs excluded from score" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/unknown-task.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    # z99 excluded: only s01's 30/60 = 50%
    [[ "$output" == *"50%"* ]]
}

@test "missing expected task fails validation" {
    # Both s01 and s02 in results, but scorer only scores s01
    create_result_diff "$RESULTS_DIR" "s01"
    create_result_diff "$RESULTS_DIR" "s02"
    # Need s02 task file too
    cp "${FIXTURES_DIR}/task-files/s01.md" "${TEST_BENCH_ROOT}/tasks/synthetic/task-02-test.md"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/missing-task.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"missed tasks"* ]] || [[ "$output" == *"scorer run"* ]]
}

@test "scorer process failure exits nonzero when all runs fail" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md" 55

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"SCORER FAILURE"* ]]
}

@test "mixed valid/invalid runs: only valid runs in mean" {
    create_result_diff "$RESULTS_DIR" "s01"
    # Run 1 and 2 succeed (75%), run 3 fails
    create_fake_claude_multi \
        "${FIXTURES_DIR}/scorer-output/valid-single.md" \
        "${FIXTURES_DIR}/scorer-output/valid-single.md" \
        "${FIXTURES_DIR}/scorer-output/valid-single.md" \
        -- 3

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --runs 3
    echo "$output"
    [ "$status" -eq 0 ]
    # Mean should be 75% from 2 valid runs, not dragged down by 0
    [[ "$output" == *"75%"* ]]
    [[ "$output" == *"2 valid judgments of 3 attempts"* ]]
}

@test "failed task gets deterministic zeros for all applicable rubrics" {
    # s01 has a .failed marker — scorer mentions it but doesn't score rubrics
    create_result_diff "$RESULTS_DIR" "s01" ""
    create_result_failed "$RESULTS_DIR" "s01" "AGENT_FAILURE:1"

    # Scorer output that mentions the task but has no score rows
    local scorer_output="${TEST_TEMP}/failed-scorer.md"
    cat > "$scorer_output" << 'EOF'
## Task s01: Test Inventory System

**STATUS: FAILED** — Agent crashed. All rubrics score 0.

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

**unity-gamedev-bench score: 0% (0/60)**
EOF
    create_fake_claude "$scorer_output"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"0%"* ]] || [[ "$output" == *"0/"* ]]
}

@test "duplicate rubric rows are rejected" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/duplicate-rubric.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Duplicate rubric"* ]] || [[ "$output" == *"duplicate"* ]] || [[ "$output" == *"INVALID"* ]]
}
