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

@test "empty results directory exits nonzero" {
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No task results found"* ]]
}

@test "unknown task ID exits nonzero" {
    echo "diff --git a/test b/test" > "${RESULTS_DIR}/z99.diff"
    create_fake_json_scorer ""

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not match a benchmark task"* ]]
}

@test "mixed valid and unknown task IDs exits nonzero" {
    create_result_diff "$RESULTS_DIR" "s01"
    echo "diff --git a/test b/test" > "${RESULTS_DIR}/z99.diff"
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"z99"* ]]
}

@test "assemble-only with unknown task exits nonzero" {
    echo "diff --git a/test b/test" > "${RESULTS_DIR}/z99.diff"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --assemble-only
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not match a benchmark task"* ]]
}
