# unity-gamedev-bench v0.1 Release Design

Date: 2026-10-09

## Overview

Ship unity-gamedev-bench as a credible public v0.1 benchmark. Seven implementation items that make scores trustworthy, runs complete, failures distinguishable, and every known bug caught by automated tests.

## Release Gates

The harness is ready for public benchmark runs when:

- All 39 tasks can be prepared successfully (smoke test passes)
- All regression tests pass in CI
- Closed-book Docker execution completes end-to-end for at least one synthetic and one real-world task
- A valid scorer fixture produces an exact expected score
- Malformed scorer fixtures always fail
- Partial runs cannot masquerade as full runs
- Repeated judging excludes invalid evaluator runs
- Unity verification is clearly marked as verified, skipped, or unavailable
- A result directory alone is sufficient to reproduce and audit the reported score

## Item 1: Restore Real-World Execution

### Problem

`cp -R "${CACHED_REPO}" "${WORK_DIR}"` copies the directory as a child instead of copying contents.

### Fix

```bash
cp -R "${CACHED_REPO}/." "${WORK_DIR}/"
```

### Smoke Test

New `scripts/smoke-test.sh`:
- Iterates all task files (or a specified subset via positional args)
- For each real-world task: resolve task file, extract repo + base_sha, clone/cache, checkout, scrub git, verify:
  - Base commit exists in clone
  - Checkout succeeds
  - Fresh baseline commit succeeds
  - No remotes present afterward (`git remote` returns nothing)
  - Exactly 1 commit in history
- For synthetic tasks: copy project, verify baseline commit
- Reports pass/fail per task, exits nonzero if any fail
- Does NOT invoke an agent

## Item 2: Disable Reference Match for v0.1

### Rationale

Reference Match is optional analytics that must not break benchmark runs. Implementing it safely requires evaluator-only directories, sort -u for Jaccard, clamping, and graceful "unavailable" on failure — work that doesn't contribute to release gates.

### Changes

- Remove reference diff generation block from `run-task.sh`
- Remove `compute_reference_match()`, `REF_MATCH` typeset, call sites, manifest integration, and console output from `score.sh`
- Keep `reference_merge_sha` in task file metadata (data preserved for post-v0.1 re-enablement)
- Update README to say Reference Match is planned for a future release

## Item 3: Machine-Readable Rubric Applicability

### Metadata Format

Add `rubrics:` line to each task file's HTML comment block:

```
<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 81d53df55a9569c996f41ba25c5aa5c872bf62a7
reference_merge_sha: 263bf966811e3e0d191da19bbc7848b63c89c5c4
merge_date: 2026-01-14
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
```

Comma-separated slugs. Omitted rubrics are N/A. No YAML parser needed.

### Slug Mapping

| Slug | Display Name |
|---|---|
| correctness | Correctness |
| robustness | Robustness |
| readability | Readability |
| architecture | Architecture |
| domain_correctness | Domain Correctness |
| test_quality | Test Quality |

### Parser Changes (score.sh)

- New `extract_task_rubrics()`: reads `rubrics:` metadata from task file, returns applicable rubric slugs
- Global `typeset -A TASK_RUBRICS` keyed by task_id
- `parse_scores()` validation becomes exact:
  - Each task must have exactly one score per applicable rubric
  - Scores for N/A rubrics are rejected
  - Duplicate rubric rows are rejected
  - Unknown rubric names are rejected
  - Return 1 on any violation
- Failed tasks get deterministic zeros for all their applicable rubrics
- The >= 3 minimum check is replaced by per-task applicability check

### Migration

All 46 task files (39 real-world + 7 synthetic) need `rubrics:` lines. Tasks with no Scoring Notes exclusions get all 6. Tasks with explicit N/A notes get the appropriate subset.

## Item 4: Enforce Run Completeness

### Three Modes

| Condition | Mode | Behavior |
|---|---|---|
| `run-request.json` exists, all tasks present | `full` | Score normally |
| `run-request.json` exists, tasks missing, no `--allow-partial` | `full` (incomplete) | Exit nonzero, print missing tasks, suggest --allow-partial |
| `run-request.json` exists, tasks missing, `--allow-partial` | `partial` | Score with label: `PARTIAL 38/39` |
| No `run-request.json` | `ad_hoc` | Score normally, label as ad_hoc |

### Manifest Fields

```json
{
  "run_type": "full",
  "completeness": {
    "requested_tasks": 39,
    "observed_tasks": 39,
    "missing_ids": [],
    "complete": true
  }
}
```

### New Flag

`--allow-partial` added to `score.sh` argument parsing.

## Item 5: Separate Evaluator Failure from Agent Score

### Invalid Runs Don't Contribute

Invalid/crashed scorer runs are not pushed into ALL_POINTS/ALL_SLOTS/ALL_PCTS. They are tracked separately.

### Minimum Valid Judgments

`min_valid = max(1, ceil(SCORER_RUNS / 2))`

If fewer than min_valid judgments are valid, exit nonzero:
```
ERROR: Only 1/3 scorer runs produced valid output (minimum 2 required).
```

### Output

```
unity-gamedev-bench score: 74% (+-2%, 2 valid judgments of 3 attempts)
```

### Manifest

```json
"scorer": {
  "runs_attempted": 3,
  "runs_valid": 2,
  "runs_invalid": 1,
  "points": [...],
  "slots": [...],
  ...
}
```

## Item 6: Comparison as Distinct Report Type

### No Single Headline Score

Comparison mode does not print `unity-gamedev-bench score: XX%`. The comparison results block is the headline.

### Manifest Structure

```json
{
  "mode": "comparison",
  "agent_a": {"dir": "...", "total_pct": 72, "points": 216, "slots": 300},
  "agent_b": {"dir": "...", "total_pct": 65, "points": 195, "slots": 300},
  "wins": {"A": 5, "B": 3, "tie": 1},
  "per_task": [...]
}
```

Replace `"compare": true/false` with `"mode": "single" | "comparison"`.

### Per-Agent Variance

Separate `ALL_A_PCTS` and `ALL_B_PCTS` arrays. Mean/std computed independently:
```
Agent A: 72% (+-1%, 3 runs)
Agent B: 65% (+-2%, 3 runs)
```

## Item 7: Regression Suite + CI

### Framework

Bats (Bash Automated Testing System). TAP output, setup/teardown, assertions.

### Structure

```
tests/
  test_helper/
    common.bash
  fixtures/
    scorer-output/
      valid-single.md
      valid-multi.md
      incomplete.md
      unknown-task.md
      duplicate-rubric.md
      missing-task.md
      comparison-xy.md
    task-files/
      s01.md
      m01.md
    verification/
      compile-fail.json
      test-regression.json
      baseline-pass.json
      runner-crash.json
  run-task.bats
  score.bats
  smoke.bats
  comparison.bats
  completeness.bats
  verification.bats
```

### Test Categories

**run-task.bats:** Successful agent with diff, agent no-op, agent exit with partial diff, setup failure, Docker failure categories (mock docker), prompt variant isolation, real-world cached checkout (tiny fixture repo).

**score.bats:** Valid scorer -> exact expected score, incomplete scorer output -> fails, unknown task IDs -> excluded, duplicate rubric -> fails, missing task -> fails, N/A rubric handling, deterministic zeros for failed tasks, scorer process failure -> nonzero exit, mixed valid/invalid repeated judgments.

**comparison.bats:** Randomization reversal correctness, separate X/Y totals, comparison manifest format, per-agent variance.

**completeness.bats:** Interrupted run -> nonzero without --allow-partial, --allow-partial -> labeled partial score, no request manifest -> ad_hoc, run-request.json written before execution.

**verification.bats:** Compile failure -> cap 2, test regression -> cap 4, baseline also failed -> no cap, runner crash -> cap 4, no verification.json -> uncapped, jq missing -> warning.

**smoke.bats:** Synthetic task preparation succeeds, real-world task preparation, no remotes after scrubbing, single baseline commit.

### Fake Executables

- `fake-agent.sh` — configurable: write diff + exit 0, or exit N, or no changes
- `fake-claude.sh` — output fixture scorer file, or exit nonzero, or garbage
- `fake-docker.sh` — simulate container: write markers to results dir

### CI

`.github/workflows/test.yml`:
```yaml
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: bats-core/bats-action@2.0.0
      - run: bats tests/
```

## Contamination Improvements (Woven Throughout)

These are metadata and labeling changes, not new infrastructure:

- Closed-book and open-book tracks: already enforced by `--closed-book` flag and `network` field in metadata
- Benchmark commit, model/version, prompt mode, network mode, task dates: already recorded in per-task metadata and manifests
- Post-cutoff report: add `--post-cutoff <date>` flag to score.sh that filters to tasks with `merge_date` after the given date
- Label public suite as development benchmark: README update
- Never describe reference similarity as proof of memorization: already in README
- Reference solutions outside agent workspace: already enforced by ISOLATION.md design (agent sees only scrubbed /workspace)
- Private task overlays: task file resolver already supports arbitrary paths; no runner changes needed

## Files Changed

| File | Changes |
|---|---|
| `scripts/run-task.sh` | Fix cp -R, remove reference diff generation |
| `scripts/run-all.sh` | No changes (already writes run-request.json) |
| `scripts/score.sh` | Remove reference match, add rubric validation, run completeness, evaluator failure separation, comparison report type, --allow-partial, --post-cutoff |
| `scripts/smoke-test.sh` | New: task preparation validator |
| `scripts/verify-unity.sh` | No changes |
| `docker/entrypoint.sh` | No changes |
| `tasks/**/*.md` | Add `rubrics:` metadata to all 46 task files |
| `README.md` | Development benchmark label, reference match planned, post-cutoff mention |
| `tests/**` | New: full Bats regression suite |
| `.github/workflows/test.yml` | New: CI workflow |
