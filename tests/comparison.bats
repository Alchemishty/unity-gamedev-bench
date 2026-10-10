#!/usr/bin/env bats

load test_helper/common

setup() {
    setup_common
    RESULTS_A="${TEST_TEMP}/results/run-a"
    RESULTS_B="${TEST_TEMP}/results/run-b"
    mkdir -p "$RESULTS_A" "$RESULTS_B"
}

teardown() {
    teardown_common
}

# Helper: create per-task meta.json
create_meta() {
    local dir="$1" id="$2" docker="$3" network="$4" pmode="$5" model="$6"
    cat > "${dir}/${id}.meta.json" << EOF
{
  "task_id": "${id}",
  "docker": ${docker},
  "network": "${network}",
  "prompt_mode": "${pmode}",
  "model": "${model}"
}
EOF
}

@test "incompatible comparison tracks rejected (docker mismatch)" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    create_meta "$RESULTS_A" "s01" "true" "disabled" "guided" "modelA"
    create_meta "$RESULTS_B" "s01" "false" "disabled" "guided" "modelB"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"incompatible"* ]] || [[ "$output" == *"Incompatible"* ]]
}

@test "incompatible comparison tracks rejected (network mismatch)" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    create_meta "$RESULTS_A" "s01" "true" "disabled" "guided" "modelA"
    create_meta "$RESULTS_B" "s01" "true" "enabled" "guided" "modelB"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"incompatible"* ]] || [[ "$output" == *"Incompatible"* ]]
}

@test "incompatible comparison tracks rejected (prompt_mode mismatch)" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    create_meta "$RESULTS_A" "s01" "true" "disabled" "guided" "modelA"
    create_meta "$RESULTS_B" "s01" "true" "disabled" "diagnostic" "modelB"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"incompatible"* ]] || [[ "$output" == *"Incompatible"* ]]
}

@test "compatible comparison tracks accepted (models may differ)" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    create_meta "$RESULTS_A" "s01" "true" "disabled" "guided" "claude-opus-4-6"
    create_meta "$RESULTS_B" "s01" "true" "disabled" "guided" "claude-sonnet-5-5"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -eq 0 ]
}

@test "inconsistent track within A rejected" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_A" "s02"
    create_result_diff "$RESULTS_B" "s01"
    create_result_diff "$RESULTS_B" "s02"
    cp "${FIXTURES_DIR}/task-files/s01.md" "${TEST_BENCH_ROOT}/tasks/synthetic/task-02-test.md"
    create_meta "$RESULTS_A" "s01" "true" "disabled" "guided" "modelA"
    create_meta "$RESULTS_A" "s02" "false" "enabled" "guided" "modelA"
    create_meta "$RESULTS_B" "s01" "true" "disabled" "guided" "modelB"
    create_meta "$RESULTS_B" "s02" "true" "disabled" "guided" "modelB"

    local scorer="${TEST_TEMP}/two-task-comparison.md"
    cat > "$scorer" << 'EOF'
## Task s01: Test Inventory System

### Output X

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 8/10 | Good |
| Robustness | 7/10 | Good |
| Readability | 8/10 | Clear |
| Architecture | 7/10 | Clean |
| Domain Correctness | 7/10 | Correct |
| Test Quality | 8/10 | Good |

### Output Y

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 5/10 | OK |
| Robustness | 4/10 | Weak |
| Readability | 5/10 | OK |
| Architecture | 4/10 | Messy |
| Domain Correctness | 4/10 | Issues |
| Test Quality | 3/10 | Minimal |

## Task s02: Test Task 2

### Output X

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 8/10 | Good |
| Robustness | 7/10 | Good |
| Readability | 8/10 | Clear |
| Architecture | 7/10 | Clean |
| Domain Correctness | 7/10 | Correct |
| Test Quality | 8/10 | Good |

### Output Y

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 5/10 | OK |
| Robustness | 4/10 | Weak |
| Readability | 5/10 | OK |
| Architecture | 4/10 | Messy |
| Domain Correctness | 4/10 | Issues |
| Test Quality | 3/10 | Minimal |
EOF
    create_fake_claude "$scorer"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"inconsistent"* ]] || [[ "$output" == *"Inconsistent"* ]]
}

@test "comparison rejects extra rubric not in task metadata" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    create_meta "$RESULTS_A" "s01" "true" "disabled" "guided" "modelA"
    create_meta "$RESULTS_B" "s01" "true" "disabled" "guided" "modelB"

    # Use s01 with only correctness,test_quality rubrics
    cat > "${TEST_BENCH_ROOT}/tasks/synthetic/task-01-test.md" << 'EOF'
<!--
rubrics: correctness,test_quality
-->
# Task: Test

**Category:** Feature

## Prompt

> Do the thing.
EOF

    # Scorer output with extra rubric (Robustness not declared)
    local scorer="${TEST_TEMP}/extra-rubric.md"
    cat > "$scorer" << 'EOF'
## Task s01: Test

### Output X

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 8/10 | Good |
| Robustness | 7/10 | Good |
| Test Quality | 8/10 | Good |

### Output Y

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 5/10 | OK |
| Test Quality | 3/10 | Minimal |
EOF
    create_fake_claude "$scorer"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"unexpected Robustness"* ]] || [[ "$output" == *"INVALID"* ]]
}

@test "comparison rejects results with no track evidence" {
    # Diffs but no .meta.json and no run-request.json track info
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"no track metadata"* ]] || [[ "$output" == *"track evidence"* ]]
}

@test "comparison accepts run-request.json track as fallback" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    # No .meta.json, but run-request.json has track info
    cat > "${RESULTS_A}/run-request.json" << 'EOF'
{"requested_tasks": 1, "task_ids": ["s01"], "track": {"docker": true, "network": "disabled", "prompt_mode": "guided", "model": "modelA"}}
EOF
    cat > "${RESULTS_B}/run-request.json" << 'EOF'
{"requested_tasks": 1, "task_ids": ["s01"], "track": {"docker": true, "network": "disabled", "prompt_mode": "guided", "model": "modelB"}}
EOF
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -eq 0 ]
}

@test "comparison rejects when run-request tracks are incompatible" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    cat > "${RESULTS_A}/run-request.json" << 'EOF'
{"requested_tasks": 1, "task_ids": ["s01"], "track": {"docker": true, "network": "disabled", "prompt_mode": "guided", "model": "modelA"}}
EOF
    cat > "${RESULTS_B}/run-request.json" << 'EOF'
{"requested_tasks": 1, "task_ids": ["s01"], "track": {"docker": false, "network": "enabled", "prompt_mode": "guided", "model": "modelB"}}
EOF
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"incompatible"* ]] || [[ "$output" == *"Incompatible"* ]]
}
