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

@test "valid JSON scorer output produces correct 0-100 score" {
    create_result_diff "$RESULTS_DIR" "s01"
    # scores: 8+7+8+7+8+6 = 44, count=6, mean=7.333, task_score=73
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"73"* ]]
    [[ "$output" == *"/ 100"* ]]
}

@test "scorer process failure exits nonzero" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_json_scorer "$S01_VALID_JSON" 55

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Scorer exited"* ]]
}

@test "missing required rubric in JSON fails validation" {
    create_result_diff "$RESULTS_DIR" "s01"
    # Missing test_quality (required by s01)
    local json='{"task":"s01","scores":{"correctness":8,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8},"violations":[]}'
    create_fake_json_scorer "$json"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"missing required rubric"* ]]
}

@test "extra undeclared rubric in JSON fails validation" {
    create_result_diff "$RESULTS_DIR" "s01"
    local json='{"task":"s01","scores":{"correctness":8,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8,"test_quality":6,"bonus":9},"violations":[]}'
    create_fake_json_scorer "$json"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"unexpected rubric"* ]]
}

@test "out-of-range score fails validation" {
    create_result_diff "$RESULTS_DIR" "s01"
    local json='{"task":"s01","scores":{"correctness":11,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8,"test_quality":6},"violations":[]}'
    create_fake_json_scorer "$json"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"invalid score"* ]]
}

@test "failed task with .failed marker auto-zeroes all rubrics" {
    create_result_diff "$RESULTS_DIR" "s01" ""
    create_result_failed "$RESULTS_DIR" "s01" "AGENT_FAILURE:1"
    # Scorer output doesn't mention s01 — auto-zero kicks in
    create_fake_json_scorer ""

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"0"* ]]
    [[ "$output" == *"/ 100"* ]]
}

@test "infrastructure failure invalidates the run" {
    create_result_diff "$RESULTS_DIR" "s01" ""
    create_result_failed "$RESULTS_DIR" "s01" "SETUP_FAILURE:127"
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Infrastructure failure"* ]]
}

@test "manifest contains score_generation digest" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    echo "$output"
    [ "$status" -eq 0 ]
    [ -f "${RESULTS_DIR}/manifest.json" ]
    local gen
    gen=$(jq -r '.score_generation' "${RESULTS_DIR}/manifest.json")
    [[ "$gen" == ugb-v1/* ]]
}

@test "manifest contains benchmark_score and task_scores" {
    create_result_diff "$RESULTS_DIR" "s01"
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto
    [ "$status" -eq 0 ]
    [ -f "${RESULTS_DIR}/manifest.json" ]
    local score
    score=$(jq -r '.benchmark_score' "${RESULTS_DIR}/manifest.json")
    [ "$score" -eq 73 ]
    local task_score
    task_score=$(jq -r '.task_scores.s01.score' "${RESULTS_DIR}/manifest.json")
    [ "$task_score" -eq 73 ]
}
