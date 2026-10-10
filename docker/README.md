# Docker Sandbox

Containerized runner for credible benchmark evaluation. Enforces filesystem isolation and optional network blocking.

## Two images

**`Dockerfile.sandbox`** — lightweight agent sandbox (no Unity). For tasks scored by judge only.

**`Dockerfile.unity`** — extends `game-ci/editor` with Unity for compilation and test verification. Requires a Unity license.

## Quick start

### Sandbox only (no Unity verification)

```bash
# Build (run from repository root)
docker build -t ugb-sandbox -f docker/Dockerfile.sandbox .

# Run a task
docker run --rm \
  -v /path/to/scrubbed-project:/workspace \
  -v /path/to/results:/results \
  -e BENCH_AGENT_CMD="claude -p --dangerously-skip-permissions" \
  -e BENCH_PROMPT="Fix the rendering bug..." \
  ugb-sandbox
```

### With Unity verification

```bash
# Build from repository root (specify Unity version from the task's ProjectVersion.txt)
docker build -t ugb-unity \
  --build-arg UNITY_VERSION=2022.3.33f1 \
  -f docker/Dockerfile.unity .

# Run with license
docker run --rm \
  -v /path/to/scrubbed-project:/workspace \
  -v /path/to/results:/results \
  -v /path/to/Unity_lic.ulf:/root/.local/share/unity3d/Unity/Unity_lic.ulf \
  -e BENCH_AGENT_CMD="claude -p --dangerously-skip-permissions" \
  -e BENCH_PROMPT="Fix the rendering bug..." \
  ugb-unity
```

### Closed-book (no network)

```bash
docker run --rm --network none \
  -v /path/to/scrubbed-project:/workspace \
  -v /path/to/results:/results \
  -e BENCH_AGENT_CMD="..." \
  -e BENCH_PROMPT="..." \
  ugb-sandbox
```

### With a harness/setup script

```bash
docker run --rm \
  -v /path/to/scrubbed-project:/workspace \
  -v /path/to/results:/results \
  -v /path/to/my-harness/install.sh:/setup/install.sh \
  -e BENCH_AGENT_CMD="..." \
  -e BENCH_PROMPT="..." \
  ugb-sandbox
```

## Using docker-compose

```bash
cd docker/

# Sandbox
WORKSPACE_PATH=/tmp/task-workspace \
RESULTS_PATH=/tmp/task-results \
BENCH_AGENT_CMD="claude -p" \
BENCH_PROMPT="Fix the bug..." \
docker compose run --rm sandbox

# Unity (with license)
WORKSPACE_PATH=/tmp/task-workspace \
RESULTS_PATH=/tmp/task-results \
UNITY_LICENSE_PATH=~/.unity/Unity_lic.ulf \
UNITY_VERSION=2022.3.33f1 \
BENCH_AGENT_CMD="claude -p" \
BENCH_PROMPT="Fix the bug..." \
docker compose run --rm unity
```

## What the agent sees

Inside the container:
- `/workspace/` — the scrubbed project (clean git, no upstream history)
- Agent CLI tools (must be installed in the image or mounted)
- Setup/harness files if `/setup/install.sh` was mounted

The agent does NOT see:
- The benchmark repository (task files, scoring prompts, rubrics)
- Other tasks' results
- Git history from the source repository
- Reference solutions

## Unity license

Unity requires activation. For CI/Docker:

1. Activate Unity on your machine and locate the license file:
   - macOS: `~/Library/Application Support/Unity/Unity_lic.ulf`
   - Linux: `~/.local/share/unity3d/Unity/Unity_lic.ulf`
   - Windows: `C:\ProgramData\Unity\Unity_lic.ulf`

2. Mount it into the container at `/root/.local/share/unity3d/Unity/Unity_lic.ulf`

For CI, store the license as a base64-encoded secret and decode at runtime.

## Verification results

When Unity is available, `verify-unity.sh` runs after the agent and produces:

- `compile.log` — Unity compilation output
- `editmode-results.xml` — NUnit test results (EditMode)
- `playmode-results.xml` — NUnit test results (PlayMode)
- `verification.json` — machine-readable summary

```json
{
  "compile": {"exit_code": 0, "pass": true},
  "editmode_tests": {"exit_code": 0, "pass": true},
  "playmode_tests": {"exit_code": 2, "pass": false}
}
```

Verification results feed into scoring:
- Compilation failure → Correctness capped at 2/10
- Existing tests broken → Correctness capped at 5/10
- All green → judge scores apply normally
