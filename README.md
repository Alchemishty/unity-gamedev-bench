# unity-gamedev-bench

A public, contamination-aware development benchmark for evaluating AI coding agents on Unity game development tasks.

I was building an agent harness for a Unity multiplayer project and needed to measure if it actually helped. Couldn't find a benchmark for Unity or game engine development, so I made one. 39 scored tasks from 10 open-source projects + 4 challenge tasks, 6 rubrics, a score out of 100%.

## Prerequisites

- **Zsh** (macOS default; `apt install zsh` on Linux)
- **Git** and **jq**
- **Your agent CLI** — any command that accepts a prompt string as an argument
- **Claude CLI** — for automatic scoring with `--auto` (optional; you can score manually)
- **Docker** — for sandboxed execution with `--docker` or `--closed-book` (optional)

## How It Works

Run your agent on the tasks. Score the output. Get a percentage.

```bash
git clone https://github.com/Alchemishty/unity-gamedev-bench.git
cd unity-gamedev-bench

# Run the benchmark
./scripts/run-all.sh --agent "claude -p" --label my-agent

# Assemble scoring input (does not score automatically)
./scripts/score.sh results/my-agent/

# Auto-score with an LLM judge
./scripts/score.sh results/my-agent/ --auto

# Or score manually: copy scoring-input.md content to your LLM
```

## Tasks

39 scored tasks across 10 open-source Unity projects + 4 unscored challenge tasks.

### Real-World Tasks (32)

Extracted from merged PRs in production Unity projects. Each task has a base commit (the state before the fix) and a reference solution (the PR diff).

**[Mirror](https://github.com/MirrorNetworking/Mirror)** — 12 tasks (MIT license, 6.3K stars)
The most popular Unity networking library.

| # | Task | Category | Difficulty |
|---|---|---|---|
| M01 | [SyncVar Hook Race Condition](tasks/real-world/mirror/task-m01-syncvar-hook-race.md) | Bug Fix | Hard |
| M02 | [HashSet/Unbatcher Security](tasks/real-world/mirror/task-m02-security-hashset-overflow.md) | Security | Medium |
| M03 | [NetworkTransform Reset Bug](tasks/real-world/mirror/task-m03-networktransform-reset.md) | Bug Fix | Medium |
| M04 | [NetworkStartPosition Tests](tasks/real-world/mirror/task-m04-test-networkstartposition.md) | Test | Easy |
| M06 | [SyncVar AOI Visibility](tasks/real-world/mirror/task-m06-syncvar-aoi-visibility.md) | Bug Fix | Hard |
| M07 | [Command Null Sender](tasks/real-world/mirror/task-m07-command-null-sender.md) | Bug Fix | Medium |
| M08 | [Unbatcher Queue Growth](tasks/real-world/mirror/task-m08-unbatcher-queue-growth.md) | Security | Hard |
| M09 | [ThreadLog Filtering](tasks/real-world/mirror/task-m09-threadlog-filtering.md) | Bug Fix | Medium |
| M10 | [NetworkAnimator Trigger](tasks/real-world/mirror/task-m10-networkanimator-trigger.md) | Bug Fix | Easy |
| M11 | [Command Host Immediate](tasks/real-world/mirror/task-m11-command-host-immediate.md) | Bug Fix | Hard |
| M12 | [NetworkName Component](tasks/real-world/mirror/task-m12-networkname-component.md) | Feature | Easy |
| M13 | [StartHost Cleanup Null](tasks/real-world/mirror/task-m13-starthost-cleanup-null.md) | Bug Fix | Easy |

**[Netcode for GameObjects](https://github.com/Unity-Technologies/com.unity.netcode.gameobjects)** — 5 scored tasks (Unity Companion License, 2.3K stars)
Unity's official networking package.

| # | Task | Category | Difficulty |
|---|---|---|---|
| N01 | [Lerp Smoothing Frame Rate](tasks/real-world/ngo/ngo-01-lerp-smoothing-framerate.md) | Bug Fix | Hard |
| N02 | [Interpolation Render Time](tasks/real-world/ngo/ngo-02-interpolation-render-time.md) | Bug Fix | Hard |
| N03 | [Scene Handle Tracking](tasks/real-world/ngo/ngo-03-scene-handle-tracking.md) | Bug Fix | Medium |
| N04 | [Mixed Authority NetworkTransform](tasks/real-world/ngo/ngo-04-mixed-authority-networktransform.md) | Bug Fix | Hard |
| N05 | [Scene Migration to Non-Observers](tasks/real-world/ngo/ngo-05-scene-migration-observers.md) | Bug Fix | Hard |
### Challenge Tasks (Unscored)

3 NGO tasks without verified reference solutions. In `tasks/challenges/ngo/`.

| # | Task | Category | Status |
|---|---|---|---|
| N06 | [NetworkList Double Apply](tasks/challenges/ngo/ngo-06-networklist-double-apply.md) | Bug Fix | Open issue, no merged fix |
| N07 | [IsOwner During ConnectionApproval](tasks/challenges/ngo/ngo-07-isowner-connection-approval.md) | Bug Fix | Open issue, no merged fix |
| N08 | [OnValueChanged Initial Value](tasks/challenges/ngo/ngo-08-onvaluechanged-initial-spawn.md) | Feature | Open issue, multiple valid approaches |

**[Boss Room](https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop)** — 7 tasks (Unity Companion License, 2K stars)
Unity's official multiplayer sample game.

| # | Task | Category | Difficulty |
|---|---|---|---|
| B01 | [Fainted Players Late Join](tasks/real-world/bossroom/br-01-fainted-players-late-join.md) | Bug Fix | Hard |
| B02 | [Breakable Null Reference](tasks/real-world/bossroom/br-02-breakable-null-reference.md) | Bug Fix | Medium |
| B03 | [Deprecated Connection Callbacks](tasks/real-world/bossroom/br-03-deprecated-connection-callbacks.md) | Refactor | Medium |
| B04 | [Null on Session Removal](tasks/real-world/bossroom/br-04-null-on-session-removal.md) | Bug Fix | Easy |
| B05 | [Late Joiner Party HUD](tasks/real-world/bossroom/br-05-late-joiner-party-hud.md) | Bug Fix | Medium |
| B06 | [Healer Ability Broken](tasks/real-world/bossroom/br-06-healer-ability-broken.md) | Bug Fix | Medium |
| B07 | [Name Generation Bounds](tasks/real-world/bossroom/br-07-name-generation-bounds.md) | Bug Fix | Easy |

**[UnityHFSM](https://github.com/Inspiaaa/UnityHFSM)** — 1 task (MIT, state machines)

| # | Task | Category | Difficulty |
|---|---|---|---|
| H01 | [Parallel Trigger Propagation](tasks/real-world/unityhfsm/h01-parallel-trigger-propagation.md) | Bug Fix | Medium |

**[VContainer](https://github.com/hadashiA/VContainer)** — 3 tasks (MIT, dependency injection)

| # | Task | Category | Difficulty |
|---|---|---|---|
| V01 | [Singleton Collection Resolution](tasks/real-world/vcontainer/v01-singleton-collection-resolution.md) | Bug Fix | Hard |
| V02 | [Startable Repeated Execution](tasks/real-world/vcontainer/v02-startable-repeated-execution.md) | Bug Fix | Medium |
| V03 | [Instantiation Exception Cleanup](tasks/real-world/vcontainer/v03-instantiation-exception-cleanup.md) | Bug Fix | Medium |

**[LitMotion](https://github.com/annulusgames/LitMotion)** — 1 task (MIT, tweening)

| # | Task | Category | Difficulty |
|---|---|---|---|
| L01 | [Completion Callback Recursion](tasks/real-world/litmotion/l01-completion-callback-recursion.md) | Bug Fix | Hard |

**[UniTask](https://github.com/Cysharp/UniTask)** — 1 task (MIT, async)

| # | Task | Category | Difficulty |
|---|---|---|---|
| U01 | [Cancellation Pool Race](tasks/real-world/unitask/u01-cancellation-pool-race.md) | Bug Fix | Hard |

**[Input System](https://github.com/Unity-Technologies/InputSystem)** — 1 task (Unity Companion License, editor tooling)

| # | Task | Category | Difficulty |
|---|---|---|---|
| I01 | [Generated Code Overwrites User File](tasks/real-world/inputsystem/i01-generated-code-overwrite.md) | Bug Fix | Medium |

**[Crest](https://github.com/wave-harmonic/crest)** — 1 task (MIT, rendering/shaders)

| # | Task | Category | Difficulty |
|---|---|---|---|
| C01 | [Foam Negative Floating Origin](tasks/real-world/crest/c01-foam-negative-floating-origin.md) | Bug Fix | Hard |

### Synthetic Tasks (7)

Custom starter project with planted anti-patterns. See [tasks/synthetic/](tasks/synthetic/).

| # | Task | Category | Difficulty |
|---|---|---|---|
| S01 | [Add Inventory System](tasks/synthetic/task-01-inventory.md) | Feature | Medium |
| S02 | [Add Buff/Debuff System](tasks/synthetic/task-02-buffs.md) | Feature | Hard |
| S03 | [Fix Silent Rendering Bug](tasks/synthetic/task-03-rendering-bug.md) | Bug Fix | Medium |
| S04 | [Fix Mysterious Null Reference](tasks/synthetic/task-04-null-reference.md) | Bug Fix | Medium |
| S05 | [Clean Up Messy Script](tasks/synthetic/task-05-refactor.md) | Refactor | Medium |
| S06 | [Extract Testable Logic](tasks/synthetic/task-06-extract-tests.md) | Refactor | Medium |
| S07 | [Three-Feature Sprint](tasks/synthetic/task-07-sprint.md) | Multi-Step | Hard |

## Scoring

Up to 6 rubrics per task (0-10 each). Not all rubrics apply to every task — a one-line bounds fix isn't scored on Architecture. Reported as a percentage of applicable points.

| Rubric | What It Tests |
|---|---|
| **Correctness** | Does the code do what was asked? |
| **Robustness** | Defensive programming, error handling, null safety |
| **Readability** | Self-documenting code, naming, structure |
| **Architecture** | Separation of concerns, dependency direction |
| **Domain Correctness** | Unity/Netcode-specific knowledge |
| **Test Quality** | Coverage, tier classification, meaningful assertions |

Real-world tasks include `reference_merge_sha` metadata pointing to the actual merged PR. **Reference Match** analysis (comparing agent diffs to reference solutions) is planned for a future release.

The breakdown shows where to focus:

```
unity-gamedev-bench score: 81% (389/480)

Per-rubric averages (out of 10):
  Correctness:        8.3
  Robustness:         8.4
  Readability:        8.1
  Architecture:       7.9
  Domain Correctness: 7.8  ← weakest
  Test Quality:       8.3
```

The max depends on which tasks you run and how many rubrics apply (some tasks mark rubrics as N/A). The percentage always reflects applicable points only.

## Task Types

Across 39 scored tasks:

| Category | Count | Description |
|---|---|---|
| Bug Fix | 29 | Diagnose and fix from a symptom description |
| Feature | 3 | Build new functionality |
| Refactor | 3 | Improve structure, extract logic |
| Security | 2 | Fix vulnerability |
| Test | 1 | Add test coverage |
| Multi-Step | 1 | Multiple features in sequence |

4 challenge tasks (unscored) in `tasks/challenges/` — 3 NGO issues without reference solutions, 1 cross-session task requiring multi-session orchestration.

### Domain Coverage

| Domain | Tasks | Sources |
|---|---|---|
| Networking/Multiplayer | 24 | Mirror, NGO, Boss Room |
| Dependency Injection | 3 | VContainer |
| State Machines | 1 | UnityHFSM |
| Async/Pooling | 1 | UniTask |
| Tweening | 1 | LitMotion |
| Editor Tooling | 1 | Input System |
| Rendering/Shaders | 1 | Crest |
| General Unity (synthetic) | 7 | Custom starter project |

## Running With Any Agent

```bash
# Run all scored tasks
./scripts/run-all.sh --agent "claude -p" --label my-agent

# Run only synthetic tasks (quick — uses local starter project)
./scripts/run-all.sh --synthetic --agent "claude -p" --label quick-test

# Run only a specific source's tasks
./scripts/run-all.sh --source mirror --agent "claude -p" --label mirror-test

# Run a single task by ID
./scripts/run-task.sh m01 --agent "claude -p" --label test

# Manual mode for GUI agents
./scripts/run-all.sh --agent manual --label cursor
```

Real-world tasks clone the source repo at the base commit specified in the task file before running the agent. Synthetic tasks use the local starter project in `project/`.

## Evaluation Integrity

### Sandbox Isolation

The runner scrubs git history from the agent sandbox — the agent sees only the source code at the base commit, not the reference solution. The Docker runner (`--docker`) enforces filesystem isolation — the agent cannot access benchmark metadata. For closed-book evaluation (`--closed-book`), network access is also disabled.

### Closed-Book vs Open-Book

| Track | Network | What It Measures |
|---|---|---|
| Closed-book | Disabled | Pure reasoning from code + prompt |
| Open-book | Enabled | Tool-assisted resolution (search, docs, browsing) |

Results must be labeled by track. Never mix tracks on a leaderboard.

### Scorer Variance

LLM judges are stochastic. Use `--runs 3` on score.sh to run the scorer multiple times and report mean ± std. High variance (std > 3%) warrants additional runs.

### Contamination & Integrity

unity-gamedev-bench is a **public, contamination-aware development benchmark** — not contamination-proof. Models may have encountered the source repositories, issues, patches, or discussions during training.

**What we do about it:**

- **Closed-book execution** (`--closed-book`) is the preferred leaderboard track — no network access means the agent cannot look up the answer at runtime
- **Task provenance** — every real-world task records its source repo, PR number, and merge date
- **Post-cutoff filtering** — use `--post-cutoff 2026-01-01` on score.sh to include only tasks merged after a given date, enabling per-model contamination windows
- **Reference isolation** — agents never see task files, scoring prompts, rubrics, or reference solutions during execution
- **No memorization claims** — a close match to a reference solution is not proof of memorization; many small fixes have only one natural implementation

**What you should report:**

- Model name and version
- Training cutoff date (if known)
- Open-book or closed-book track
- Whether the agent had repository or web access
- Benchmark commit hash (`git rev-parse --short HEAD`)

**What would make this stronger** (contributions welcome):

- Private holdout tasks that have never been public
- Tasks from repositories not in common training sets
- Diverse task sources beyond the current 10 projects
- Empirical contamination measurement using pre/post-cutoff solve rate comparisons

See [scripts/ISOLATION.md](scripts/ISOLATION.md) for the full isolation model.

## Results

Pilot results from early development. Run your own for current numbers.

| Run | Tasks | Score | Commit | Notes |
|---|---|---|---|---|
| Harness v3 (synthetic) | 8 of 7 synthetic | **81%** | pre-`c6058b3` | Pilot run, scorer v1 |
| Baseline (synthetic) | 3 of 7 synthetic | 53% | pre-`c6058b3` | Partial run |

These are historical pilot results from before the benchmark was open-sourced. They used an earlier scorer prompt and task set. For reproducible results, always include the benchmark commit (`git rev-parse --short HEAD`) in your reports.

When reporting results, break down by source repository — repositories with more tasks (Mirror: 12) weight the headline score more than single-task sources (Crest: 1). The scorer output includes per-source breakdowns.

Full results in [results/](results/).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT (benchmark framework). Individual tasks reference code under their source repo's license:
- **MIT:** Mirror, UnityHFSM, VContainer, LitMotion, UniTask, Crest
- **Unity Companion License:** NGO, Boss Room, Input System
