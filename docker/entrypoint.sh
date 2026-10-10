#!/bin/bash
set -euo pipefail

# Entrypoint for the benchmark sandbox container.
# Expects:
#   /workspace/       — scrubbed project (mounted by host)
#   /results/         — output directory (mounted by host)
#   BENCH_AGENT_CMD   — agent CLI command
#   BENCH_PROMPT      — task prompt text

cd /workspace

# Run setup if provided
if [[ -f /setup/install.sh ]]; then
    echo "Running setup script..."
    SETUP_EXIT=0
    bash /setup/install.sh || SETUP_EXIT=$?
    if [[ "$SETUP_EXIT" -ne 0 ]]; then
        echo "SETUP_FAILURE:${SETUP_EXIT}" > /results/task.failed
        echo "Setup script failed with exit code ${SETUP_EXIT}" >&2
        exit "$SETUP_EXIT"
    fi
    git add -A && git -c user.name="Benchmark" -c user.email="benchmark@invalid" commit -q -m "setup" 2>/dev/null || true
fi

# Run baseline verification before agent (establishes ground truth)
if [[ -x /verify-unity.sh ]] && command -v unity-editor &>/dev/null; then
    echo "Running baseline verification..."
    /verify-unity.sh /workspace /results baseline-verification.json || true
fi

# Run agent
AGENT_EXIT=0
echo "Running agent: ${BENCH_AGENT_CMD:-no agent specified}"
if [[ -n "${BENCH_AGENT_CMD:-}" && -n "${BENCH_PROMPT:-}" ]]; then
    # Use bash -c with $1 to pass the prompt safely (avoids eval re-parsing quotes in prompt text)
    bash -c "${BENCH_AGENT_CMD} \"\$1\"" -- "${BENCH_PROMPT}" 2>&1 | tee /results/agent.log || AGENT_EXIT=$?
    echo "Agent exit code: ${AGENT_EXIT}" >> /results/agent.log
else
    echo "Error: BENCH_AGENT_CMD and BENCH_PROMPT must be set" >&2
    echo "MISSING_ENV" > /results/task.failed
    exit 1
fi

# Collect diff
git add -A
git diff --cached --binary -- . ':!Library/' ':!Temp/' ':!Logs/' ':!obj/' > /results/task.diff 2>/dev/null || true

DIFF_LINES=$(wc -l < /results/task.diff 2>/dev/null | tr -d ' ')

if [[ "$AGENT_EXIT" -ne 0 ]]; then
    echo "AGENT_FAILURE:${AGENT_EXIT}:diff_lines=${DIFF_LINES}" > /results/task.failed
elif [[ "$DIFF_LINES" -eq 0 ]]; then
    echo "NO_CHANGES" > /results/task.failed
fi

# Run post-agent Unity verification if available
if [[ -x /verify-unity.sh ]] && command -v unity-editor &>/dev/null; then
    echo "Running post-agent verification..."
    /verify-unity.sh /workspace /results verification.json || true
fi

echo "Done. Diff: ${DIFF_LINES} lines, exit: ${AGENT_EXIT}"

# Exit with the agent's exit code so the host can detect failure
exit $AGENT_EXIT
