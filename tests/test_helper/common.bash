#!/usr/bin/env bash
# Shared test helpers for unity-gamedev-bench Bats test suite

REAL_BENCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURES_DIR="${REAL_BENCH_ROOT}/tests/fixtures"

setup_common() {
    TEST_TEMP=$(mktemp -d)
    export TEST_TEMP

    # Create a minimal BENCH_ROOT structure for tests that need task resolution
    export TEST_BENCH_ROOT="${TEST_TEMP}/bench"
    mkdir -p "${TEST_BENCH_ROOT}/tasks/synthetic"
    mkdir -p "${TEST_BENCH_ROOT}/scripts"
    mkdir -p "${TEST_BENCH_ROOT}/scoring"

    # Copy real scripts
    cp "${REAL_BENCH_ROOT}/scripts/score.sh" "${TEST_BENCH_ROOT}/scripts/"
    cp "${REAL_BENCH_ROOT}/scripts/run-task.sh" "${TEST_BENCH_ROOT}/scripts/"
    cp "${REAL_BENCH_ROOT}/scripts/run-all.sh" "${TEST_BENCH_ROOT}/scripts/"
    cp "${REAL_BENCH_ROOT}/scripts/list-tasks.sh" "${TEST_BENCH_ROOT}/scripts/"
    cp "${REAL_BENCH_ROOT}/scoring/scoring-agent-prompt.md" "${TEST_BENCH_ROOT}/scoring/"

    # Create a local git repo to serve as the starter project for synthetic task tests
    local TEST_STARTER="${TEST_TEMP}/ugb-starter-repo"
    mkdir -p "${TEST_STARTER}/Assets"
    echo "// starter" > "${TEST_STARTER}/Assets/Starter.cs"
    (cd "$TEST_STARTER" && git init -q && git add -A && \
     git -c user.name="Test" -c user.email="test@invalid" commit -q -m "initial" 2>/dev/null)
    TEST_STARTER_SHA=$(cd "$TEST_STARTER" && git rev-parse HEAD)

    # Pre-populate the clone cache so tests don't need network access
    mkdir -p "${TEST_BENCH_ROOT}/.cache/repos"
    cp -R "${TEST_STARTER}/." "${TEST_BENCH_ROOT}/.cache/repos/Alchemishty_ugb-starter"

    # Install fixture task file with repo/sha pointing to the local test repo
    mkdir -p "${TEST_BENCH_ROOT}/tasks/synthetic"
    cat > "${TEST_BENCH_ROOT}/tasks/synthetic/task-01-test.md" << TASKEOF
<!--
repo: https://github.com/Alchemishty/ugb-starter.git
base_sha: ${TEST_STARTER_SHA}
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Test Inventory System

**Category:** Feature

## Prompt

> Add an inventory system to the player for testing purposes.

## Scoring Notes

All rubrics apply.
TASKEOF

    # Prepend fake bin dir to PATH
    export FAKE_BIN="${TEST_TEMP}/bin"
    mkdir -p "$FAKE_BIN"
    export PATH="${FAKE_BIN}:${PATH}"
}

teardown_common() {
    rm -rf "$TEST_TEMP"
}

# Create a fake agent that writes a file and exits with given code
# Usage: create_fake_agent [exit_code] [write_file]
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

# Create a fake claude that outputs a fixture file
# Reads and discards stdin (real scorer receives input via stdin)
# Usage: create_fake_claude <fixture_path> [exit_code]
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

# Create a fake claude that cycles through fixture files (for multi-run tests)
# Usage: create_fake_claude_multi <fixture1> <fixture2> ... -- [fail_on_run_N]
create_fake_claude_multi() {
    local fixtures=()
    local fail_run=0
    local parsing_fixtures=true
    for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
            parsing_fixtures=false
            continue
        fi
        if $parsing_fixtures; then
            fixtures+=("$arg")
        else
            fail_run="$arg"
        fi
    done

    local counter_file="${TEST_TEMP}/claude_call_counter"
    echo "0" > "$counter_file"

    # Write all fixture paths to a file the fake claude can read
    local fixtures_file="${TEST_TEMP}/claude_fixtures"
    printf '%s\n' "${fixtures[@]}" > "$fixtures_file"

    cat > "${FAKE_BIN}/claude" << 'CLAUDE'
#!/bin/bash
cat >/dev/null 2>&1 || true
COUNTER_FILE="COUNTER_PLACEHOLDER"
FIXTURES_FILE="FIXTURES_PLACEHOLDER"
FAIL_RUN="FAIL_PLACEHOLDER"

count=$(cat "$COUNTER_FILE")
((count++))
echo "$count" > "$COUNTER_FILE"

if [[ "$FAIL_RUN" -gt 0 && "$count" -eq "$FAIL_RUN" ]]; then
    exit 55
fi

fixture=$(sed -n "${count}p" "$FIXTURES_FILE")
if [[ -n "$fixture" && -f "$fixture" ]]; then
    cat "$fixture"
else
    # Reuse last fixture if we run out
    tail -1 "$FIXTURES_FILE" | xargs cat
fi
CLAUDE
    # Use perl for in-place edit (portable across macOS and Linux, unlike sed -i)
    perl -pi -e "s|COUNTER_PLACEHOLDER|${counter_file}|" "${FAKE_BIN}/claude"
    perl -pi -e "s|FIXTURES_PLACEHOLDER|${fixtures_file}|" "${FAKE_BIN}/claude"
    perl -pi -e "s|FAIL_PLACEHOLDER|${fail_run}|" "${FAKE_BIN}/claude"
    chmod +x "${FAKE_BIN}/claude"
}

# Create a results directory with a .diff file for a task
# Usage: create_result_diff <results_dir> <task_id> [content]
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

# Create a run-request.json
create_run_request() {
    local dir="$1"
    shift
    local task_ids=("$@")
    local count=${#task_ids[@]}
    mkdir -p "$dir"
    local ids_json=$(printf '"%s",' "${task_ids[@]}" | sed 's/,$//')
    cat > "${dir}/run-request.json" << EOF
{
  "timestamp": "2026-10-09T00:00:00Z",
  "requested_tasks": ${count},
  "task_ids": [${ids_json}],
  "agent": "test-agent",
  "label": "test",
  "model": "test",
  "filter": "all"
}
EOF
}
