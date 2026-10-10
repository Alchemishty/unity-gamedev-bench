#!/usr/bin/env bats

load test_helper/common

setup() {
    setup_common
    # run-all.sh computes BENCH_ROOT from its own location, so results go to TEST_BENCH_ROOT/results/
    RESULTS_DIR="${TEST_BENCH_ROOT}/results/stale-test"
    mkdir -p "$RESULTS_DIR"
}

teardown() {
    teardown_common
}

@test "run-all rejects label with existing .diff files" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_agent 0 true

    run zsh "${TEST_BENCH_ROOT}/scripts/run-all.sh" \
        --agent "test-agent" --label stale-test s01
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already contains task artifacts"* ]]
    [[ "$output" == *".diff files:"* ]]
}

@test "run-all rejects label with existing .failed files only" {
    create_result_failed "$RESULTS_DIR" "s01" "AGENT_FAILURE:1"
    create_fake_agent 0 true

    run zsh "${TEST_BENCH_ROOT}/scripts/run-all.sh" \
        --agent "test-agent" --label stale-test s01
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already contains task artifacts"* ]]
    [[ "$output" == *".failed files:"* ]]
}

@test "run-all rejects label with both .diff and .failed files" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_result_failed "$RESULTS_DIR" "s02" "AGENT_FAILURE:1"
    create_fake_agent 0 true

    run zsh "${TEST_BENCH_ROOT}/scripts/run-all.sh" \
        --agent "test-agent" --label stale-test s01
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already contains task artifacts"* ]]
}

@test "run-all allows empty results directory" {
    # Directory exists but has no .diff or .failed files — only other artifacts
    echo '{}' > "${RESULTS_DIR}/run-request.json"
    create_fake_agent 0 true

    run zsh "${TEST_BENCH_ROOT}/scripts/run-all.sh" \
        --agent "test-agent" --label stale-test s01
    echo "$output"
    [ "$status" -eq 0 ]
}
