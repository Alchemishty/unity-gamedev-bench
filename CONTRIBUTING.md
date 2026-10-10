# Contributing to unity-gamedev-bench

## Directory Structure

```
tasks/
├── synthetic/                  # Custom starter project tasks (s01-s07)
│   └── task-01-inventory.md
├── real-world/                 # Tasks extracted from open-source repos
│   ├── mirror/                 # MirrorNetworking/Mirror (m01-m04, m06-m13)
│   │   └── task-m01-syncvar-hook-race.md
│   ├── ngo/                    # Unity Netcode for GameObjects (n01-n05)
│   │   └── ngo-01-lerp-smoothing-framerate.md
│   └── bossroom/               # Unity Boss Room sample (b01-b07)
│       └── br-01-fainted-players-late-join.md
└── challenges/                 # Unscored tasks (no reference solution yet)
    └── ngo/
        └── ngo-06-networklist-double-apply.md
```

## Task ID Format

| Source | Prefix | Example |
|---|---|---|
| Synthetic | `s` | s01, s02 |
| Mirror | `m` | m01, m02 |
| Netcode for GameObjects | `n` | n01, n02 |
| Boss Room | `b` | b01, b02 |

## Adding Synthetic Tasks

Synthetic tasks use the custom starter project in `project/`.

### File Format

```markdown
# Task: [Short Title]

**Category:** Feature / Bug Fix / Refactor / Multi-Step / Cross-Session
**Difficulty:** Easy / Medium / Hard

## Prompt

> The exact natural-language prompt given to the agent.
> No hints about expected patterns or solutions.

## What It Exercises

- [rubric 1]
- [rubric 2]

## Expected Touchpoints

- Files likely created or modified
- Patterns the solution should use

## Landmine Map

Which planted anti-patterns in the starter code are relevant.

## Scoring Notes

Task-specific scoring guidance. Specify if any rubric is N/A.
```

### Steps

1. Create `tasks/synthetic/task-NN-slug.md`
2. Add it to the task table in `README.md`
3. If the task requires new landmines, add them to `project/` and document in README

## Adding Real-World Tasks

Real-world tasks are extracted from merged PRs in open-source Unity repos.

### File Format

```markdown
# Task: [Short Title]

**Source:** [Org/Repo] PR #XXXX
**Category:** Bug Fix / Feature / Refactor / Security / Test
**Difficulty:** Easy / Medium / Hard
**Repo:** https://github.com/[org]/[repo]
**Base Commit:** [full SHA — the commit before the fix]
**Reference PR:** https://github.com/[org]/[repo]/pull/XXXX
**Reference Merge SHA:** [full SHA of the merge commit]

## Prompt

> Natural-language description of the problem.
> Describe symptoms, not solutions.

## Prompt Variant: Diagnostic (optional)

> Symptoms-only version with no root-cause hints.

## What It Exercises

- [rubrics exercised]

## Reference Solution

[Number of files changed, additions, deletions]

## Scoring Notes

Task-specific scorer guidance. Specify N/A rubrics if applicable.
```

### Structured Metadata

The `Base Commit` must be a directly checkable SHA — not "Parent of X". The runner clones the repo at this exact commit before handing it to the agent.

### Steps

1. Find a merged PR with a clear bug description and self-contained fix
2. Resolve the base commit: `gh api repos/[org]/[repo]/pulls/[number] --jq '.base.sha'`
3. Get the merge SHA: `gh api repos/[org]/[repo]/pulls/[number] --jq '.merge_commit_sha'`
4. Write the task file in `tasks/real-world/[source]/`
5. Add it to the README task table

### Adding a New Source Repo

1. Create `tasks/real-world/[source-name]/`
2. Choose a prefix letter (unique, not already used)
3. Extract tasks from merged PRs using the format above
4. Ensure the repo license permits use (MIT, Apache, Unity Companion)
5. Add the source to the README with star count and license

## Adding Challenge Tasks

Challenge tasks are unresolved issues without a verified solution. They go in `tasks/challenges/[source]/` and are NOT included in the scored benchmark set.

Requirements to promote a challenge to the scored set:
- A pinned base commit
- A reference solution (merged PR or verified fix)
- Acceptance criteria that can be checked

## Adding Domain Modules

The benchmark's core (rubrics 1-4, 6) is engine-agnostic. Rubric 5 (Domain Correctness) is Unity-specific.

### Swapping Rubric 5

1. Create `rubrics/domain-correctness-[engine].md`
2. Define 0-10 scale with engine-specific checks
3. Update `scoring/scoring-agent-prompt.md` to reference the new rubric

### Swapping the Starter Project

1. Create `project-[engine]/` with equivalent landmines
2. Create corresponding tasks in `tasks/synthetic/`
3. Document landmines in the project directory

## Submitting Results

### Result Format

Each run produces a directory under `results/[label]/`:
- `[id].diff` — code diff per task
- `[id].log` — agent conversation log (if available)
- `[id].meta.json` — per-task metadata (duration, exit code, model, track)
- `[id].failed` — failure marker with category (if task failed)
- `run-request.json` — intended task list from run-all.sh
- `scoring-input.md` — assembled input for the LLM scorer
- `scoring-output-N.md` — raw scorer output per run
- `scoring-report.md` — primary scored results
- `manifest.json` — run metadata, scores, completeness, track info

### How to Submit

1. Run the benchmark
2. Score the results
3. Fork this repo, add your results directory
4. Open a PR

## Improving Rubrics

### Proposing Changes

1. Open an issue with the proposed change and rationale
2. Include before/after scoring criteria
3. Explain impact on existing results

### Backward Compatibility

- Increment version number in rubric file when changing criteria
- Note which version each result set was scored under
- Adding sub-components is non-breaking
