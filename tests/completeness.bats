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

@test "incomplete run without --allow-partial exits nonzero" {
    # Request s01 + s02 but only s01 has results
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/task-files/s01.md" "${TEST_BENCH_ROOT}/tasks/synthetic/task-02-test.md"
    create_run_request "$RESULTS_DIR" s01 s02
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Incomplete run"* ]] || [[ "$output" == *"--allow-partial"* ]]
}

@test "incomplete run with --allow-partial scores as partial" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/task-files/s01.md" "${TEST_BENCH_ROOT}/tasks/synthetic/task-02-test.md"
    create_run_request "$RESULTS_DIR" s01 s02
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --allow-partial
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PARTIAL"* ]] || [[ "$output" == *"partial"* ]]
}

@test "mismatched task sets detected even with equal counts" {
    # Request s01 + s02, but results have s01 + s03 (same count, different sets)
    create_result_diff "$RESULTS_DIR" "s01"
    create_result_diff "$RESULTS_DIR" "s03"
    cp "${FIXTURES_DIR}/task-files/s01.md" "${TEST_BENCH_ROOT}/tasks/synthetic/task-02-test.md"
    cp "${FIXTURES_DIR}/task-files/s01.md" "${TEST_BENCH_ROOT}/tasks/synthetic/task-03-test.md"
    create_run_request "$RESULTS_DIR" s01 s02
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Missing"* ]] || [[ "$output" == *"missing"* ]] || [[ "$output" == *"does not match"* ]]
}

@test "no run-request.json labels as ad_hoc" {
    create_result_diff "$RESULTS_DIR" "s01"
    # No run-request.json — ad hoc run
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    # Check manifest has ad_hoc
    [ -f "${RESULTS_DIR}/manifest.json" ]
    if command -v jq &>/dev/null; then
        local run_type
        run_type=$(jq -r '.run_type' "${RESULTS_DIR}/manifest.json")
        [ "$run_type" = "ad_hoc" ]
    fi
}
