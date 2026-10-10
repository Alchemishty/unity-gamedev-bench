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

HIGH_CORRECTNESS_JSON='{"task":"s01","scores":{"correctness":8,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8,"test_quality":6},"violations":[]}'

@test "compile failure caps correctness to 2" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/compile-fail.json" "${RESULTS_DIR}/s01.verification.json"
    create_fake_json_scorer "$HIGH_CORRECTNESS_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP"* ]]
    # After cap: mean(2,7,8,7,8,6) = 6.33 → 63
    [[ "$output" == *"63"* ]]
}

@test "test regression caps correctness to 4" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/baseline-pass.json" "${RESULTS_DIR}/s01.baseline-verification.json"
    cp "${FIXTURES_DIR}/verification/test-regression.json" "${RESULTS_DIR}/s01.verification.json"
    create_fake_json_scorer "$HIGH_CORRECTNESS_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP"* ]]
    # After cap: mean(4,7,8,7,8,6) = 6.67 → 67
    [[ "$output" == *"67"* ]]
}

@test "runner crash with pass=false caps to 4" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/baseline-pass.json" "${RESULTS_DIR}/s01.baseline-verification.json"
    cp "${FIXTURES_DIR}/verification/runner-crash.json" "${RESULTS_DIR}/s01.verification.json"
    create_fake_json_scorer "$HIGH_CORRECTNESS_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"CAP"* ]]
    # Same as test regression: mean(4,7,8,7,8,6) = 6.67 → 67
    [[ "$output" == *"67"* ]]
}

@test "no verification.json leaves score uncapped" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_json_scorer "$HIGH_CORRECTNESS_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" != *"CAP"* ]]
    # Uncapped: mean(8,7,8,7,8,6) = 7.33 → 73
    [[ "$output" == *"73"* ]]
}
