# unity-gamedev-bench

Benchmark for evaluating AI coding agents on Unity game development tasks. 10 fixed tasks from 2 repositories, 6 rubrics, scored 0–100. Runs in under 40 minutes.

## Quick Start

```bash
# Run the standard 10-task suite
./scripts/run-all.sh --agent "claude -p --dangerously-skip-permissions" \
    --label my-first-run --suite standard

# Score it
./scripts/score.sh results/my-first-run --auto --model claude-sonnet-5-5

# Run again and get an automatic comparison
./scripts/run-all.sh --agent "claude -p --dangerously-skip-permissions" \
    --label my-second-run --suite standard
./scripts/score.sh results/my-second-run --auto --model claude-sonnet-5-5
```

## What It Measures

**10 tasks** across feature implementation, bug fixing, refactoring, security, test authoring, and multi-step work. Easy through Hard difficulty. 4 synthetic tasks on a controlled Unity project, 6 real-world tasks from [Mirror Networking](https://github.com/MirrorNetworking/Mirror).

**6 rubrics** scored 0–10 each:
- **Correctness** — does it work?
- **Robustness** — does it handle bad input?
- **Readability** — can a human understand it?
- **Architecture** — is the structure appropriate?
- **Domain Correctness** — are Unity/networking patterns correct?
- **Test Quality** — are the tests meaningful?

**Scoring:** Each task score = mean of its applicable rubric scores × 10. Benchmark score = mean of 10 task scores. Equal weight per task.

## Suites

| Suite | Tasks | Purpose |
|---|---|---|
| `standard` | 10 | Official benchmark score. Use for comparisons. |
| `smoke` | 3 | Quick check that the pipeline works. |

```bash
# Smoke test (3 tasks, ~10 min)
./scripts/run-all.sh --agent <cmd> --label test --suite smoke --parallel 1

# Standard (10 tasks, ~15 min with 3 parallel)
./scripts/run-all.sh --agent <cmd> --label test --suite standard
```

## Options

```
--agent <cmd>       Agent command (receives prompt as argument)
--label <name>      Results directory name
--suite <name>      Task suite: standard, smoke
--parallel <n>      Concurrent tasks (default 3)
--setup <script>    Script to run before agent in each task workdir
--model <id>        Model identifier for metadata
--docker            Run in Docker sandbox
--closed-book       Docker + no network
```

## Interpreting Results

```
unity-gamedev-bench score: 77 / 100

Per-task scores:
    s01    74  medium
    s03    82  medium
    m01    68  hard
    ...

Rubric averages:
    Correctness              8.2/10  (10 tasks)
    Robustness               7.4/10  (10 tasks)
    ...
```

Score changes between runs:
- **<2 points:** effectively unchanged
- **2–5 points:** small directional change
- **>5 points:** likely material
- **New compile regression:** always investigate

## Verification

When Unity Editor is available, `verify-unity.sh` compiles the project and runs tests after the agent. Verification results feed into scoring:
- **Compile failure** → Correctness capped at 2/10
- **Test regression** → Correctness capped at 4/10
- **No verification data** → score is LLM-assessed only, labelled accordingly

Verification coverage is reported as N/10 in the manifest.

## Contamination

The agent receives only the task prompt. It does not see scoring notes, rubric definitions, reference solutions, or the benchmark repository. Git history in the workspace is scrubbed to a single baseline commit with no remote.

```
execution_contamination_controls: enforced
training_contamination: unknown
```

Open-book agents with internet access may discover task metadata or reference solutions. Closed-book Docker mode (`--closed-book`) prevents this.

## Historical Comparison

Every run produces a `manifest.json` with a score generation digest. When you score a new run, it automatically compares against the latest compatible previous run:

```
                        previous → current    Δ
Overall                     72.8 → 76.1    +3.3
Correctness                 74.0 → 79.0    +5.0
```

Comparisons require exact digest match (same suite, rubrics, scorer prompt, scorer model). Different scorer models produce a side-by-side view labelled non-comparable.

## Contributing

Two areas where contributions are most valuable:

1. **More real-world tasks** — from Unity open-source projects with public bug-fix PRs. Each task needs: repo URL, base SHA, prompt, rubric declaration, and difficulty rating.

2. **Verification support** — extending `verify-unity.sh` for additional Unity versions or project configurations.

## License

MIT
