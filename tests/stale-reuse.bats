#!/usr/bin/env bats

load test_helper/common

setup() {
    setup_common
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
    [[ "$output" == *"already contains benchmark artifacts"* ]]
}

@test "run-all rejects label with existing .failed files" {
    create_result_failed "$RESULTS_DIR" "s01" "AGENT_FAILURE:1"
    create_fake_agent 0 true

    run zsh "${TEST_BENCH_ROOT}/scripts/run-all.sh" \
        --agent "test-agent" --label stale-test s01
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already contains benchmark artifacts"* ]]
}
