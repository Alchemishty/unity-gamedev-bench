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

# JSON scorer with correctness=8 for cap tests
HIGH_CORRECTNESS_JSON='{"task":"s01","scores":{"correctness":8,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8,"test_quality":6},"violations":[]}'

@test "compile failure with CS diagnostics caps correctness to 2" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/compile-fail.json" "${RESULTS_DIR}/s01.verification.json"
    create_fake_json_scorer "$HIGH_CORRECTNESS_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP"* ]]
    # 8→2: mean(2,7,8,7,8,6)=6.33 → task_score=63
    [[ "$output" == *"63"* ]]
}

@test "infrastructure error does not cap correctness" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/infra-error.json" "${RESULTS_DIR}/s01.verification.json"
    create_fake_json_scorer "$HIGH_CORRECTNESS_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" != *"CAP"* ]]
    # Uncapped: mean(8,7,8,7,8,6)=7.33 → task_score=73
    [[ "$output" == *"73"* ]]
}

@test "runner infra crash does not cap correctness" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/runner-infra-crash.json" "${RESULTS_DIR}/s01.verification.json"
    create_fake_json_scorer "$HIGH_CORRECTNESS_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" != *"CAP"* ]]
    [[ "$output" == *"73"* ]]
}
