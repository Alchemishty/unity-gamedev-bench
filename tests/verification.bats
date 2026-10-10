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

@test "compile failure caps correctness to 2" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/compile-fail.json" "${RESULTS_DIR}/s01.verification.json"

    local scorer_file
    scorer_file=$(create_high_correctness_scorer)
    create_fake_claude "$scorer_file"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    # 8 → 2 on Correctness, rest unchanged: 2+7+8+7+7+8 = 39/60 = 65%
    [[ "$output" == *"CAP"* ]]
    [[ "$output" == *"65%"* ]] || [[ "$output" == *"39/"* ]]
}

@test "test regression caps correctness to 4" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/baseline-pass.json" "${RESULTS_DIR}/s01.baseline-verification.json"
    cp "${FIXTURES_DIR}/verification/test-regression.json" "${RESULTS_DIR}/s01.verification.json"

    local scorer_file
    scorer_file=$(create_high_correctness_scorer)
    create_fake_claude "$scorer_file"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    # 8 → 4 on Correctness: 4+7+8+7+7+8 = 41/60 = 68%
    [[ "$output" == *"CAP"* ]]
    [[ "$output" == *"68%"* ]] || [[ "$output" == *"41/"* ]]
}

@test "runner crash with pass=false caps to 4" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/baseline-pass.json" "${RESULTS_DIR}/s01.baseline-verification.json"
    cp "${FIXTURES_DIR}/verification/runner-crash.json" "${RESULTS_DIR}/s01.verification.json"

    local scorer_file
    scorer_file=$(create_high_correctness_scorer)
    create_fake_claude "$scorer_file"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP"* ]]
    # Baseline editmode pass=true, post editmode pass=false → cap to 4
    [[ "$output" == *"68%"* ]] || [[ "$output" == *"41/"* ]]
}

@test "no verification.json leaves score uncapped" {
    create_result_diff "$RESULTS_DIR" "s01"
    # No verification files at all

    local scorer_file
    scorer_file=$(create_high_correctness_scorer)
    create_fake_claude "$scorer_file"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    # Original score preserved: 45/60 = 75%
    [[ "$output" == *"75%"* ]]
    [[ "$output" != *"CAP"* ]]
}
