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

# Helper: create scorer output that gives Correctness 8/10 for s01
create_high_correctness_scorer() {
    local scorer_file="${TEST_TEMP}/high-correctness.md"
    cat > "$scorer_file" << 'EOF'
## Task s01: Test Inventory System

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 8/10 | Works well |
| Robustness | 7/10 | Good |
| Readability | 8/10 | Clear |
| Architecture | 7/10 | Clean |
| Domain Correctness | 7/10 | Correct |
| Test Quality | 8/10 | Good |
| **Task Total** | **45/60** | |

## Final Score

**unity-gamedev-bench score: 75% (45/60)**
EOF
    echo "$scorer_file"
}

@test "compile failure with CS diagnostics caps correctness to 2" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/compile-fail.json" "${RESULTS_DIR}/s01.verification.json"

    local scorer_file
    scorer_file=$(create_high_correctness_scorer)
    create_fake_claude "$scorer_file"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP"* ]]
    # 8 → 2 on Correctness: 2+7+8+7+7+8 = 39/60 = 65%
    [[ "$output" == *"65%"* ]] || [[ "$output" == *"39/"* ]]
}

@test "infrastructure error does not cap correctness" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/infra-error.json" "${RESULTS_DIR}/s01.verification.json"

    local scorer_file
    scorer_file=$(create_high_correctness_scorer)
    create_fake_claude "$scorer_file"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    # No cap applied — infrastructure_error is skipped
    [[ "$output" != *"CAP"* ]]
    [[ "$output" == *"75%"* ]]
}

@test "runner infra crash (outcome=infrastructure_error) does not cap correctness" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/runner-infra-crash.json" "${RESULTS_DIR}/s01.verification.json"

    local scorer_file
    scorer_file=$(create_high_correctness_scorer)
    create_fake_claude "$scorer_file"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" != *"CAP"* ]]
    [[ "$output" == *"75%"* ]]
}
