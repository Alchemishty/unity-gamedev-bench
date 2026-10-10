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

@test "scorer uses --bare --tools '' --disable-slash-commands --strict-mcp-config (no --dangerously-skip-permissions)" {
    create_result_diff "$RESULTS_DIR" "s01"

    # Create a fake claude that records its arguments
    local args_file="${TEST_TEMP}/claude_args"
    cat > "${FAKE_BIN}/claude" << CLAUDE
#!/bin/bash
cat >/dev/null 2>&1 || true
printf '%s\n' "\$@" > "${args_file}"
cat "${FIXTURES_DIR}/scorer-output/valid-single.md"
CLAUDE
    chmod +x "${FAKE_BIN}/claude"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]

    # Verify isolation flags are present
    local args
    args=$(cat "$args_file")
    [[ "$args" == *"--bare"* ]]
    [[ "$args" == *"--tools"* ]]
    [[ "$args" == *"--disable-slash-commands"* ]]
    [[ "$args" == *"--strict-mcp-config"* ]]
    # Must NOT contain --dangerously-skip-permissions
    [[ "$args" != *"--dangerously-skip-permissions"* ]]
}

@test "scorer model is passed via --model flag and recorded in manifest" {
    create_result_diff "$RESULTS_DIR" "s01"

    local args_file="${TEST_TEMP}/claude_args"
    cat > "${FAKE_BIN}/claude" << CLAUDE
#!/bin/bash
cat >/dev/null 2>&1 || true
printf '%s\n' "\$@" > "${args_file}"
cat "${FIXTURES_DIR}/scorer-output/valid-single.md"
CLAUDE
    chmod +x "${FAKE_BIN}/claude"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model "claude-sonnet-5-5"
    echo "$output"
    [ "$status" -eq 0 ]

    local args
    args=$(cat "$args_file")
    [[ "$args" == *"--model"* ]]
    [[ "$args" == *"claude-sonnet-5-5"* ]]

    # Model recorded in manifest
    [ -f "${RESULTS_DIR}/manifest.json" ]
    local scorer_model
    scorer_model=$(jq -r '.scorer.model' "${RESULTS_DIR}/manifest.json")
    [ "$scorer_model" = "claude-sonnet-5-5" ]
}

@test "scorer receives input via stdin (not command-line argument)" {
    create_result_diff "$RESULTS_DIR" "s01"

    # Create a fake claude that checks stdin is non-empty
    local stdin_file="${TEST_TEMP}/claude_stdin"
    cat > "${FAKE_BIN}/claude" << CLAUDE
#!/bin/bash
cat > "${stdin_file}"
cat "${FIXTURES_DIR}/scorer-output/valid-single.md"
CLAUDE
    chmod +x "${FAKE_BIN}/claude"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]

    # stdin must have been non-empty (contains the scoring input)
    [ -f "$stdin_file" ]
    local stdin_lines
    stdin_lines=$(wc -l < "$stdin_file" | tr -d ' ')
    [ "$stdin_lines" -gt 10 ]
}

@test "large scoring input is passed via stdin without truncation" {
    # Create 50 task results to generate a large input
    for i in $(seq -w 1 7); do
        create_result_diff "$RESULTS_DIR" "s0${i}"
    done
    # Need task files for s02-s07 (resolver expects task-0N-*.md pattern)
    for i in 02 03 04 05 06 07; do
        cp "${FIXTURES_DIR}/task-files/s01.md" "${TEST_BENCH_ROOT}/tasks/synthetic/task-${i}-test.md"
    done

    # Create scorer output that covers all 7 tasks
    local big_scorer="${TEST_TEMP}/big-scorer.md"
    {
        for i in $(seq -w 1 7); do
            cat << EOF
## Task s0${i}: Test Task ${i}

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 8/10 | Works |
| Robustness | 7/10 | Good |
| Readability | 8/10 | Clear |
| Architecture | 7/10 | Clean |
| Domain Correctness | 7/10 | Correct |
| Test Quality | 8/10 | Good |
| **Task Total** | **45/60** | |

EOF
        done
        echo "## Final Score"
        echo "**unity-gamedev-bench score: 75% (315/420)**"
    } > "$big_scorer"

    local stdin_file="${TEST_TEMP}/claude_stdin"
    cat > "${FAKE_BIN}/claude" << CLAUDE
#!/bin/bash
cat > "${stdin_file}"
cat "${big_scorer}"
CLAUDE
    chmod +x "${FAKE_BIN}/claude"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]

    # Verify stdin contains all 7 task blocks
    local task_count
    task_count=$(grep -c "^## Task s0" "$stdin_file")
    [ "$task_count" -eq 7 ]
}

@test "scorer works with relative results directory path" {
    # Create results in a subdirectory of TEST_BENCH_ROOT
    mkdir -p "${TEST_BENCH_ROOT}/results/run"
    create_result_diff "${TEST_BENCH_ROOT}/results/run" "s01"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/valid-single.md"

    # Run from BENCH_ROOT using a relative path (the documented usage pattern)
    run zsh -c "cd '${TEST_BENCH_ROOT}' && zsh scripts/score.sh results/run --auto"
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"75%"* ]]
    # Manifest must exist at the absolute path
    [ -f "${TEST_BENCH_ROOT}/results/run/manifest.json" ]
}
