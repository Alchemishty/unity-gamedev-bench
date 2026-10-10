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
    # No .diff or .failed files — just an empty dir
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No task results found"* ]]
}

@test "unknown task ID (no matching benchmark task) exits nonzero" {
    # z99 doesn't exist as a benchmark task
    echo "diff --git a/test b/test" > "${RESULTS_DIR}/z99.diff"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"do not match any scored benchmark task"* ]]
    [[ "$output" == *"z99"* ]]
}

@test "mixed valid and unknown task IDs exits nonzero" {
    # s01 is valid, z99 is not
    create_result_diff "$RESULTS_DIR" "s01"
    echo "diff --git a/test b/test" > "${RESULTS_DIR}/z99.diff"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"z99"* ]]
}

@test "empty directory does not produce 0/0 score" {
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --assemble-only
    echo "$output"
    [ "$status" -ne 0 ]
    # Must not contain a score line
    [[ "$output" != *"0% (0/0)"* ]]
}

@test "assemble-only with unknown task ID exits nonzero" {
    echo "diff --git a/test b/test" > "${RESULTS_DIR}/z99.diff"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --assemble-only
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"do not match any scored benchmark task"* ]]
}
