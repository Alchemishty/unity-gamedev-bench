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

@test "malformed meta.json with empty fields is rejected" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    echo '{}' > "${RESULTS_A}/s01.meta.json"
    create_meta "$RESULTS_B" "s01" "true" "disabled" "guided" "modelB"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"malformed"* ]] || [[ "$output" == *"must be"* ]]
}

@test "meta.json with null docker value is rejected" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    echo '{"docker": null, "network": "disabled", "prompt_mode": "guided", "model": "test"}' > "${RESULTS_A}/s01.meta.json"
    create_meta "$RESULTS_B" "s01" "true" "disabled" "guided" "modelB"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"docker must be true or false"* ]]
}

@test "meta.json with invalid network value is rejected" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    create_meta "$RESULTS_A" "s01" "true" "maybe" "guided" "modelA"
    create_meta "$RESULTS_B" "s01" "true" "disabled" "guided" "modelB"
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"network must be"* ]]
}

@test "per-task meta contradicting run-request.json is rejected" {
    create_result_diff "$RESULTS_A" "s01"
    create_result_diff "$RESULTS_B" "s01"
    # Meta says docker=true, run-request says docker=false
    create_meta "$RESULTS_A" "s01" "true" "disabled" "guided" "modelA"
    cat > "${RESULTS_A}/run-request.json" << 'EOF'
{"requested_tasks": 1, "task_ids": ["s01"], "track": {"docker": false, "network": "disabled", "prompt_mode": "guided", "model": "modelA"}}
EOF
    create_meta "$RESULTS_B" "s01" "true" "disabled" "guided" "modelB"
    cat > "${RESULTS_B}/run-request.json" << 'EOF'
{"requested_tasks": 1, "task_ids": ["s01"], "track": {"docker": true, "network": "disabled", "prompt_mode": "guided", "model": "modelB"}}
EOF
    create_fake_claude "${FIXTURES_DIR}/scorer-output/comparison-xy.md"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -ne 0 ]
    [[ "$output" == *"conflicts with run-request"* ]]
}

@test "all-failed comparison with run-request fallback retains tracks in manifest" {
    # Both sides have only .failed markers, no .meta.json
    create_result_failed "$RESULTS_A" "s01" "AGENT_FAILURE:1"
    create_result_failed "$RESULTS_B" "s01" "AGENT_FAILURE:1"
    cat > "${RESULTS_A}/run-request.json" << 'EOF'
{"requested_tasks": 1, "task_ids": ["s01"], "track": {"docker": true, "network": "disabled", "prompt_mode": "guided", "model": "modelA"}}
EOF
    cat > "${RESULTS_B}/run-request.json" << 'EOF'
{"requested_tasks": 1, "task_ids": ["s01"], "track": {"docker": true, "network": "disabled", "prompt_mode": "guided", "model": "modelB"}}
EOF

    # Scorer output with zeros for the failed task
    local scorer="${TEST_TEMP}/failed-comparison.md"
    cat > "$scorer" << 'EOF'
## Task s01: Test Inventory System

### Output X

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 0/10 | Failed |
| Robustness | 0/10 | Failed |
| Readability | 0/10 | Failed |
| Architecture | 0/10 | Failed |
| Domain Correctness | 0/10 | Failed |
| Test Quality | 0/10 | Failed |

### Output Y

| Rubric | Score | Justification |
|---|---|---|
| Correctness | 0/10 | Failed |
| Robustness | 0/10 | Failed |
| Readability | 0/10 | Failed |
| Architecture | 0/10 | Failed |
| Domain Correctness | 0/10 | Failed |
| Test Quality | 0/10 | Failed |
EOF
    create_fake_claude "$scorer"

    run zsh "${TEST_BENCH_ROOT}/scripts/score.sh" "$RESULTS_A" "$RESULTS_B" --compare --auto
    echo "$output"
    [ "$status" -eq 0 ]

    # Manifest must have complete track and comparison_tracks
    [ -f "${RESULTS_A}/manifest.json" ]
    local track_docker comp_a_model comp_b_model
    track_docker=$(jq -r '.track.docker' "${RESULTS_A}/manifest.json")
    [ "$track_docker" = "true" ]
    comp_a_model=$(jq -r '.comparison_tracks.track_a.model' "${RESULTS_A}/manifest.json")
    [ "$comp_a_model" = "modelA" ]
    comp_b_model=$(jq -r '.comparison_tracks.track_b.model' "${RESULTS_A}/manifest.json")
    [ "$comp_b_model" = "modelB" ]
    # comparison_tracks must include docker, network, prompt_mode
    local comp_a_docker comp_b_net
    comp_a_docker=$(jq -r '.comparison_tracks.track_a.docker' "${RESULTS_A}/manifest.json")
    [ "$comp_a_docker" = "true" ]
    comp_b_net=$(jq -r '.comparison_tracks.track_b.network' "${RESULTS_A}/manifest.json")
    [ "$comp_b_net" = "disabled" ]
}
