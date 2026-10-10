# Agent Sandbox Isolation

The benchmark runner isolates the agent from answer-leaking information.

## What the agent sees

The agent's working directory contains only:
- The source code at the pinned base commit (the state before the fix)
- A fresh `.git` with a single "baseline" commit and no remotes
- Optionally: harness/framework files injected by `--setup`

## What the agent does NOT see

- **Git history**: the original `.git` is deleted and replaced with a clean repo. The agent cannot `git log --all`, `git show <merge_sha>`, or `git diff HEAD origin/master` to find the reference solution.
- **Benchmark metadata**: task files (contain PR numbers, merge SHAs, solution descriptions), scoring prompts, rubrics, and results are not in the agent's filesystem. The prompt is extracted before the agent starts and passed as a string argument.
- **Remotes**: no `origin` or upstream remotes exist. `git fetch` and `git pull` have nothing to reach.

## How it works

For real-world tasks:
1. Clone the source repo
2. Checkout the pinned base commit
3. Delete `.git` entirely
4. `git init` a fresh repository
5. `git add -A && git commit -m "baseline"` — single commit, no history
6. Run the agent in this scrubbed directory

For synthetic tasks:
1. Copy the starter project
2. `git init` with a single baseline commit
3. Run the agent

## Closed-book vs Open-book

The script prevents answer leakage from local git history. It does NOT block network access.

- **Closed-book**: block network access externally (Docker, firewall, `--network none`). The agent cannot search for the issue or PR online.
- **Open-book**: network access allowed. The agent can search, read docs, find related issues. Measures tool-assisted resolution.

Report which mode was used. Do not compare closed-book and open-book results on the same leaderboard.

## Benchmark repo visibility

The benchmark repository itself should not be on the agent's filesystem during evaluation. It contains:
- Task files with PR numbers, merge SHAs, and scoring notes
- Reference solution descriptions
- Scorer hints

The runner extracts the prompt string before the agent starts. The agent receives only the prompt, not the file it came from.

For strict evaluation, run the agent inside a Docker container or sandbox that mounts only the scrubbed project directory.

## Docker Enforcement

When running with `--docker`:
1. Agent runs inside a container with only `/workspace` mounted
2. The benchmark repository is not accessible
3. With `--closed-book`, network is disabled via `--network none`
4. Agent cannot inspect parent directories or other filesystems

## Unity Build Verification

When running with `--unity-verify`:
1. The base commit is compiled BEFORE the agent runs (baseline health check)
2. After the agent finishes, the project is compiled again in Unity batch mode
3. EditMode and PlayMode tests are executed if test assemblies exist
4. Results (compile pass/fail, test counts, broken tests) are recorded in manifest.json
5. Compilation failure caps the Correctness rubric score regardless of judge opinion

## Contamination Tracking

Each real-world task includes `merge_date` in its metadata block. Compare against the evaluated model's training cutoff to assess contamination risk.

- Tasks merged before the cutoff may have been seen during training
- Tasks merged after the cutoff are likely unseen
- Report both sets separately when making evaluation claims
- A close match to the reference is not proof of memorization — small correct fixes often have only one natural implementation

## Docker Sandbox

For enforced isolation, use the Docker sandbox:

```bash
# Build the sandbox image (from repository root)
docker build -t ugb-sandbox -f docker/Dockerfile.sandbox .

# Run a task in closed-book mode (no network)
./scripts/run-task.sh m01 --agent "claude -p" --label test --docker --closed-book

# Build with Unity verification (from repository root)
docker build -t ugb-unity --build-arg UNITY_VERSION=2022.3.33f1 -f docker/Dockerfile.unity .
./scripts/run-task.sh m01 --agent "claude -p" --label test --docker --docker-image ugb-unity --closed-book
```

The Docker sandbox:
1. Mounts only the scrubbed project into /workspace
2. Mounts the results directory into /results
3. With `--closed-book`, disables all network access (`--network none`)
4. The benchmark repository is NOT mounted — the agent cannot read task files, scoring prompts, or rubrics
5. Git history is scrubbed before mounting

For Unity build verification, the `unity` service extends the sandbox with a Unity Editor (via game-ci images). It compiles the project and runs EditMode/PlayMode tests, writing results to `verification.json`.

### Unity License

game-ci images require Unity license activation. Set the `UNITY_LICENSE` environment variable to a base64-encoded .ulf file:

```bash
export UNITY_LICENSE=$(base64 -i ~/Unity_v2022.x.ulf)
```

See https://game.ci/docs/docker/docker-images for details.
