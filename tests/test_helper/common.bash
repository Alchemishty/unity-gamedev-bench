#!/usr/bin/env bash
# Shared test helpers for unity-gamedev-bench Bats test suite

REAL_BENCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURES_DIR="${REAL_BENCH_ROOT}/tests/fixtures"

setup_common() {
    TEST_TEMP=$(mktemp -d)
    export TEST_TEMP

    export TEST_BENCH_ROOT="${TEST_TEMP}/bench"
    mkdir -p "${TEST_BENCH_ROOT}/tasks/synthetic"
    mkdir -p "${TEST_BENCH_ROOT}/scripts"
    mkdir -p "${TEST_BENCH_ROOT}/scoring"
    mkdir -p "${TEST_BENCH_ROOT}/rubrics"
    mkdir -p "${TEST_BENCH_ROOT}/suites"

    # Copy real scripts and config
    cp "${REAL_BENCH_ROOT}/scripts/score.sh" "${TEST_BENCH_ROOT}/scripts/"
    cp "${REAL_BENCH_ROOT}/scripts/run-task.sh" "${TEST_BENCH_ROOT}/scripts/"
    cp "${REAL_BENCH_ROOT}/scripts/run-all.sh" "${TEST_BENCH_ROOT}/scripts/"
    [[ -f "${REAL_BENCH_ROOT}/scripts/list-tasks.sh" ]] && cp "${REAL_BENCH_ROOT}/scripts/list-tasks.sh" "${TEST_BENCH_ROOT}/scripts/"
    [[ -f "${REAL_BENCH_ROOT}/scripts/compare.sh" ]] && cp "${REAL_BENCH_ROOT}/scripts/compare.sh" "${TEST_BENCH_ROOT}/scripts/" && chmod +x "${TEST_BENCH_ROOT}/scripts/compare.sh"
    cp "${REAL_BENCH_ROOT}/scoring/scoring-agent-prompt.md" "${TEST_BENCH_ROOT}/scoring/"
    cp "${REAL_BENCH_ROOT}"/rubrics/0*.md "${TEST_BENCH_ROOT}/rubrics/" 2>/dev/null || true
    cp "${REAL_BENCH_ROOT}"/suites/*.json "${TEST_BENCH_ROOT}/suites/" 2>/dev/null || true

    # Create a local git repo for synthetic task tests
    local TEST_STARTER="${TEST_TEMP}/ugb-starter-repo"
    mkdir -p "${TEST_STARTER}/Assets"
    echo "// starter" > "${TEST_STARTER}/Assets/Starter.cs"
    (cd "$TEST_STARTER" && git init -q && git add -A && \
     git -c user.name="Test" -c user.email="test@invalid" commit -q -m "initial" 2>/dev/null)
    TEST_STARTER_SHA=$(cd "$TEST_STARTER" && git rev-parse HEAD)

    mkdir -p "${TEST_BENCH_ROOT}/.cache/repos"
    cp -R "${TEST_STARTER}/." "${TEST_BENCH_ROOT}/.cache/repos/Alchemishty_ugb-starter"

    # Fixture task file with repo/sha and rubrics
    cat > "${TEST_BENCH_ROOT}/tasks/synthetic/task-01-test.md" << TASKEOF
<!--
repo: https://github.com/Alchemishty/ugb-starter.git
base_sha: ${TEST_STARTER_SHA}
difficulty: medium
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Test Inventory System

**Category:** Feature
**Difficulty:** Medium

## Prompt

> Add an inventory system to the player for testing purposes.

## Scoring Notes

All rubrics apply.
TASKEOF

    export FAKE_BIN="${TEST_TEMP}/bin"
    mkdir -p "$FAKE_BIN"
    export PATH="${FAKE_BIN}:${PATH}"
}

teardown_common() {
    rm -rf "$TEST_TEMP"
}

# Create a fake agent that writes a file and exits with given code
create_fake_agent() {
    local exit_code="${1:-0}"
    local write_file="${2:-true}"
    cat > "${FAKE_BIN}/test-agent" << AGENT
#!/bin/bash
if [[ "${write_file}" == "true" ]]; then
    mkdir -p Assets
    echo "// agent was here" > Assets/AgentOutput.cs
fi
exit ${exit_code}
AGENT
    chmod +x "${FAKE_BIN}/test-agent"
}

# Create a fake claude that reads stdin and outputs a fixture file
create_fake_claude() {
    local fixture_path="$1"
    local exit_code="${2:-0}"
    cat > "${FAKE_BIN}/claude" << CLAUDE
#!/bin/bash
cat >/dev/null 2>&1 || true
if [[ "${exit_code}" -ne 0 ]]; then
    exit ${exit_code}
fi
cat "${fixture_path}"
CLAUDE
    chmod +x "${FAKE_BIN}/claude"
}

# Create a fake claude that outputs inline JSON scorer results
# Usage: create_fake_json_scorer <json_lines_string>
create_fake_json_scorer() {
    local json_content="$1"
    local exit_code="${2:-0}"
    local json_file="${TEST_TEMP}/scorer-output.json"
    echo "$json_content" > "$json_file"
    cat > "${FAKE_BIN}/claude" << CLAUDE
#!/bin/bash
cat >/dev/null 2>&1 || true
if [[ "${exit_code}" -ne 0 ]]; then
    exit ${exit_code}
fi
cat "${json_file}"
CLAUDE
    chmod +x "${FAKE_BIN}/claude"
}

# Standard JSON scorer output for s01 with all 6 rubrics scored 7-8
# task_score = mean(8,7,8,7,8,6) * 10 = 7.33 * 10 = 73
S01_VALID_JSON='{"task":"s01","scores":{"correctness":8,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8,"test_quality":6},"violations":[]}'

# Create a results directory with a .diff file for a task
create_result_diff() {
    local dir="$1" id="$2" content="${3:-}"
    mkdir -p "$dir"
    if [[ -n "$content" ]]; then
        echo "$content" > "${dir}/${id}.diff"
    else
        cat > "${dir}/${id}.diff" << 'DIFF'
diff --git a/Assets/Test.cs b/Assets/Test.cs
new file mode 100644
--- /dev/null
+++ b/Assets/Test.cs
@@ -0,0 +1,3 @@
+public class Test {
+    public void Run() {}
+}
DIFF
    fi
}

# Create a .failed marker
create_result_failed() {
    local dir="$1" id="$2" reason="${3:-AGENT_FAILURE:1}"
    mkdir -p "$dir"
    echo "$reason" > "${dir}/${id}.failed"
}

# Create a run-request.json (v0.1 format)
create_run_request() {
    local dir="$1"
    shift
    local task_ids=("$@")
    local count=${#task_ids[@]}
    mkdir -p "$dir"
    local ids_json=$(printf '"%s",' "${task_ids[@]}" | sed 's/,$//')
    cat > "${dir}/run-request.json" << EOF
{
  "timestamp": "2026-10-10T00:00:00Z",
  "suite": "custom",
  "suite_version": "custom",
  "requested_tasks": ${count},
  "task_ids": [${ids_json}],
  "agent": "test-agent",
  "label": "test",
  "model": "test",
  "prompt_mode": "guided",
  "docker": false,
  "network": "enabled"
}
EOF
}

# Install additional synthetic task files (s02, s03, etc.) using the same fixture
install_task_file() {
    local id="$1"
    local num="${id#s}"
    num=$(printf '%02d' "$num")
    cp "${TEST_BENCH_ROOT}/tasks/synthetic/task-01-test.md" "${TEST_BENCH_ROOT}/tasks/synthetic/task-${num}-test.md"
}
