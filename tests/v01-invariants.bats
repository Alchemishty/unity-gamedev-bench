#!/usr/bin/env bats

# Tests for v0.1 invariants: completeness, verification labelling,
# generation digests, condition compatibility, JSON parsing robustness.

load test_helper/common

setup() {
    setup_common
    RESULTS_DIR="${TEST_TEMP}/results/test"
    mkdir -p "$RESULTS_DIR"
}

teardown() {
    teardown_common
}

# ---- Completeness: exact task set match ----

@test "missing requested task invalidates a run" {
    create_result_diff "$RESULTS_DIR" "s01"
    # run-request says s01 + s03, but only s01 has results
    install_task_file s03
    create_run_request "$RESULTS_DIR" s01 s03
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Missing task results"* ]]
}

@test "extra task invalidates a run" {
    create_result_diff "$RESULTS_DIR" "s01"
    install_task_file s03
    create_result_diff "$RESULTS_DIR" "s03"
    # run-request only lists s01
    create_run_request "$RESULTS_DIR" s01
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unexpected task results"* ]]
}

# ---- Stale artifacts ----

@test "stale verification file rejects label reuse" {
    RESULTS_DIR="${TEST_BENCH_ROOT}/results/stale-verif"
    mkdir -p "$RESULTS_DIR"
    echo '{"verification":"completed"}' > "${RESULTS_DIR}/s01.verification.json"
    create_fake_agent 0 true

    run zsh "${TEST_BENCH_ROOT}/scripts/run-all.sh" \
        --agent "test-agent" --label stale-verif s01
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already contains benchmark artifacts"* ]]
}

@test "stale manifest file rejects label reuse" {
    RESULTS_DIR="${TEST_BENCH_ROOT}/results/stale-manifest"
    mkdir -p "$RESULTS_DIR"
    echo '{}' > "${RESULTS_DIR}/manifest.json"
    create_fake_agent 0 true

    run zsh "${TEST_BENCH_ROOT}/scripts/run-all.sh" \
        --agent "test-agent" --label stale-manifest s01
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already contains benchmark artifacts"* ]]
}

# ---- Verification labelling ----

@test "skipped verification is displayed as unverified" {
    create_result_diff "$RESULTS_DIR" "s01"
    echo '{"verification":"skipped","reason":"unity_not_found"}' > "${RESULTS_DIR}/s01.verification.json"
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Verification: 0/"* ]]
    # Per-task should not show ✓
    [[ "$output" != *"✓"* ]]
}

@test "infrastructure_error verification is displayed as unverified" {
    create_result_diff "$RESULTS_DIR" "s01"
    cp "${FIXTURES_DIR}/verification/infra-error.json" "${RESULTS_DIR}/s01.verification.json"
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Verification: 0/"* ]]
}

# ---- Generation digests ----

@test "smoke and standard produce different generation digests" {
    # Create results for smoke suite
    local SMOKE_DIR="${TEST_TEMP}/results/smoke"
    mkdir -p "$SMOKE_DIR"
    create_result_diff "$SMOKE_DIR" "s01"
    cat > "${SMOKE_DIR}/run-request.json" << 'EOF'
{"suite":"smoke","suite_version":"v1","task_ids":["s01"],"model":"test","prompt_mode":"guided","docker":false,"network":"enabled"}
EOF
    create_fake_json_scorer "$S01_VALID_JSON"
    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$SMOKE_DIR" --auto --model test
    [ "$status" -eq 0 ]
    local smoke_gen
    smoke_gen=$(jq -r '.score_generation' "${SMOKE_DIR}/manifest.json")

    # Create results for standard suite (same task, different suite)
    local STD_DIR="${TEST_TEMP}/results/standard"
    mkdir -p "$STD_DIR"
    create_result_diff "$STD_DIR" "s01"
    cat > "${STD_DIR}/run-request.json" << 'EOF'
{"suite":"standard","suite_version":"v1","task_ids":["s01"],"model":"test","prompt_mode":"guided","docker":false,"network":"enabled"}
EOF
    create_fake_json_scorer "$S01_VALID_JSON"
    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$STD_DIR" --auto --model test
    [ "$status" -eq 0 ]
    local std_gen
    std_gen=$(jq -r '.score_generation' "${STD_DIR}/manifest.json")

    echo "smoke: $smoke_gen"
    echo "standard: $std_gen"
    [ "$smoke_gen" != "$std_gen" ]
}

# ---- JSON parsing robustness ----

@test "JSON with whitespace parses successfully" {
    create_result_diff "$RESULTS_DIR" "s01"
    # Pretty-printed JSON with spaces around colons
    local SPACED_JSON='{ "task": "s01", "scores": { "correctness": 8, "robustness": 7, "readability": 8, "architecture": 7, "domain_correctness": 8, "test_quality": 6 }, "violations": [] }'
    create_fake_json_scorer "$SPACED_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"73"* ]]
}

@test "duplicate scorer task entries fail validation" {
    create_result_diff "$RESULTS_DIR" "s01"
    local DUP_JSON='{"task":"s01","scores":{"correctness":8,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8,"test_quality":6},"violations":[]}
{"task":"s01","scores":{"correctness":9,"robustness":8,"readability":9,"architecture":8,"domain_correctness":9,"test_quality":7},"violations":[]}'
    create_fake_json_scorer "$DUP_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"duplicate"* ]]
}

@test "unknown scorer task entry is ignored without failing" {
    create_result_diff "$RESULTS_DIR" "s01"
    # z99 is not a requested task — should be ignored, s01 should parse fine
    local EXTRA_JSON='{"task":"s01","scores":{"correctness":8,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8,"test_quality":6},"violations":[]}
{"task":"z99","scores":{"correctness":5},"violations":[]}'
    create_fake_json_scorer "$EXTRA_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"73"* ]]
}

@test "non-JSON prose lines in scorer output are skipped" {
    create_result_diff "$RESULTS_DIR" "s01"
    local NOISY_JSON='Here are my scores for the tasks:

{"task":"s01","scores":{"correctness":8,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8,"test_quality":6},"violations":[]}

Overall this was a good implementation.'
    create_fake_json_scorer "$NOISY_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"73"* ]]
}

# ---- Timing ----

# ---- Run condition compatibility ----

@test "different run conditions are non-comparable" {
    # Create two manifests with same generation but different docker setting
    local RUN_A="${TEST_TEMP}/results/run-a"
    local RUN_B="${TEST_TEMP}/results/run-b"
    mkdir -p "$RUN_A" "$RUN_B"

    local GEN="ugb-v1/abc123/test"
    cat > "${RUN_A}/manifest.json" << EOF
{"score_generation":"${GEN}","benchmark_score":70,"benchmark_score_precise":70.0,"task_scores":{"s01":{"score":70}},"rubric_averages":{},"summary":{},"timing":{"wall_seconds":100},"cost":{},"environment":{"prompt_mode":"guided","network":"enabled","docker":false}}
EOF
    cat > "${RUN_B}/manifest.json" << EOF
{"score_generation":"${GEN}","benchmark_score":75,"benchmark_score_precise":75.0,"task_scores":{"s01":{"score":75}},"rubric_averages":{},"summary":{},"timing":{"wall_seconds":120},"cost":{},"environment":{"prompt_mode":"guided","network":"disabled","docker":true}}
EOF

    # Should fail without --force
    run zsh "${TEST_BENCH_ROOT}/scripts/compare.sh" "$RUN_A" "$RUN_B"
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"conditions differ"* ]] || [[ "$output" == *"not comparable"* ]]
}

# ---- Timing ----

@test "manifest records wall_seconds and summed_task_seconds" {
    create_result_diff "$RESULTS_DIR" "s01"
    # Create a meta.json with duration
    mkdir -p "$RESULTS_DIR"
    echo '{"duration_seconds":42}' > "${RESULTS_DIR}/s01.meta.json"
    # Create run-request with wall time
    cat > "${RESULTS_DIR}/run-request.json" << 'EOF'
{"suite":"custom","suite_version":"custom","task_ids":["s01"],"model":"test","prompt_mode":"guided","docker":false,"network":"enabled","wall_seconds":50,"summed_task_seconds":42}
EOF
    create_fake_json_scorer "$S01_VALID_JSON"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_DIR" --auto --model test
    echo "$output"
    [ "$status" -eq 0 ]

    local wall summed
    wall=$(jq -r '.timing.wall_seconds' "${RESULTS_DIR}/manifest.json")
    summed=$(jq -r '.timing.summed_task_seconds' "${RESULTS_DIR}/manifest.json")
    [ "$wall" -eq 50 ]
    [ "$summed" -eq 42 ]
}
