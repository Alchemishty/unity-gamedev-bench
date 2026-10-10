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

@test "scorer uses --bare --tools '' --disable-slash-commands --strict-mcp-config" {
    create_result_diff "$RESULTS_DIR" "s01"

    local args_file="${TEST_TEMP}/claude_args"
    cat > "${FAKE_BIN}/claude" << CLAUDE
#!/bin/bash
cat >/dev/null 2>&1 || true
printf '%s\n' "\$@" > "${args_file}"
echo '${S01_VALID_JSON}'
CLAUDE
    chmod +x "${FAKE_BIN}/claude"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]

    local args
    args=$(cat "$args_file")
    [[ "$args" == *"--bare"* ]]
    [[ "$args" == *"--tools"* ]]
    [[ "$args" == *"--disable-slash-commands"* ]]
    [[ "$args" == *"--strict-mcp-config"* ]]
    [[ "$args" != *"--dangerously-skip-permissions"* ]]
}

@test "scorer receives input via stdin" {
    create_result_diff "$RESULTS_DIR" "s01"

    local stdin_file="${TEST_TEMP}/claude_stdin"
    cat > "${FAKE_BIN}/claude" << CLAUDE
#!/bin/bash
cat > "${stdin_file}"
echo '${S01_VALID_JSON}'
CLAUDE
    chmod +x "${FAKE_BIN}/claude"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    [ "$status" -eq 0 ]
    [ -f "$stdin_file" ]
    local stdin_lines
    stdin_lines=$(wc -l < "$stdin_file" | tr -d ' ')
    [ "$stdin_lines" -gt 10 ]
}

@test "scorer output is JSON not markdown" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    [ "$status" -eq 0 ]
    [ -f "${RESULTS_DIR}/scoring-output-1.json" ]
    # Output should contain valid JSON line
    local line
    line=$(grep '"task"' "${RESULTS_DIR}/scoring-output-1.json" | head -1)
    echo "$line" | jq empty 2>/dev/null
}
