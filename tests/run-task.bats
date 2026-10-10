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

@test "successful agent produces diff and exits 0" {
    create_fake_agent 0 true

    run zsh "${TEST_BENCH_ROOT}/scripts/run-task.sh" s01 \
        --agent "test-agent" --label test
    echo "$output"
    [ "$status" -eq 0 ]
    [ -f "${TEST_BENCH_ROOT}/results/test/s01.diff" ]
    local lines
    lines=$(wc -l < "${TEST_BENCH_ROOT}/results/test/s01.diff" | tr -d ' ')
    [ "$lines" -gt 0 ]
}

@test "agent no-op produces NO_CHANGES marker" {
    create_fake_agent 0 false

    run zsh "${TEST_BENCH_ROOT}/scripts/run-task.sh" s01 \
        --agent "test-agent" --label test
    echo "$output"
    [ "$status" -ne 0 ]
    [ -f "${TEST_BENCH_ROOT}/results/test/s01.failed" ]
    local reason
    reason=$(cat "${TEST_BENCH_ROOT}/results/test/s01.failed")
    [[ "$reason" == "NO_CHANGES" ]]
}

@test "agent failure preserves exit code" {
    create_fake_agent 42 true

    run zsh "${TEST_BENCH_ROOT}/scripts/run-task.sh" s01 \
        --agent "test-agent" --label test
    echo "$output"
    [ "$status" -ne 0 ]
    [ -f "${TEST_BENCH_ROOT}/results/test/s01.failed" ]
    local reason
    reason=$(cat "${TEST_BENCH_ROOT}/results/test/s01.failed")
    [[ "$reason" == *"AGENT_FAILURE:42"* ]]
}

@test "setup script failure terminates task" {
    create_fake_agent 0 true
    local setup_script="${TEST_TEMP}/bad-setup.sh"
    echo '#!/bin/bash' > "$setup_script"
    echo 'exit 1' >> "$setup_script"
    chmod +x "$setup_script"

    run zsh "${TEST_BENCH_ROOT}/scripts/run-task.sh" s01 \
        --agent "test-agent" --label test --setup "$setup_script"
    echo "$output"
    [ "$status" -ne 0 ]
    [ -f "${TEST_BENCH_ROOT}/results/test/s01.failed" ]
    local reason
    reason=$(cat "${TEST_BENCH_ROOT}/results/test/s01.failed")
    [[ "$reason" == *"SETUP_FAILURE"* ]]
}
