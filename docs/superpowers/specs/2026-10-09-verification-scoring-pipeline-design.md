# Verification & Scoring Pipeline Design

Date: 2026-10-09

## Overview

Three features that complete the verification-scoring pipeline:
1. **Comparison scoring** — parse separate X/Y scores, reverse randomization, compute wins/ties
2. **Correctness caps** — host-enforced score capping based on Unity verification results
3. **Pre-agent baseline verification** — establish ground truth before the agent runs

## Feature 1: Comparison Scoring

### Problem

`--compare --assemble-only` correctly produces randomized X/Y scoring input. But `parse_scores()` combines all rubric rows into one aggregate — it doesn't distinguish X from Y, doesn't reverse randomization, and doesn't compute per-agent totals or wins.

### Parser State Machine

```
IDLE → "## Task s01" → IN_TASK (task=s01)
IN_TASK → "### Output X" → IN_OUTPUT (output=X)
IN_OUTPUT → rubric row → accumulate score for (task, output)
IN_OUTPUT → "### Output Y" → IN_OUTPUT (output=Y)
IN_OUTPUT → "## Task s02" → flush task, IN_TASK (task=s02)
IN_OUTPUT → "### Comparison" → IN_COMPARISON (skip — host computes its own)
```

### Data Structure

Associative array keyed by `"${task_id}:${output_label}"` with accumulated points and slots.

### Randomization Reversal

After parsing:
1. Read randomization file to build mapping: `task_id → {X=A|B, Y=A|B}`
2. For each task, map X/Y scores back to A/B
3. Compute per-task winner (higher percentage wins; tie if equal)
4. Compute aggregate: total A points/slots, total B points/slots, win/tie counts

### Validation

- Both result directories must contain identical task ID sets (checked before assembly)
- Each task must have scores for both X and Y (parse error if one is missing)

### Output

`comparison-summary.json` in RESULTS_A:
```json
{
  "agent_a": {"dir": "results/opus", "total_pct": 72, "points": 216, "slots": 300},
  "agent_b": {"dir": "results/sonnet", "total_pct": 65, "points": 195, "slots": 300},
  "per_task": [
    {"task": "s01", "a_pct": 80, "b_pct": 70, "winner": "A"}
  ],
  "wins": {"A": 5, "B": 3, "tie": 1},
  "randomization_reversed": true
}
```

Separate reports: `scoring-report-A.md`, `scoring-report-B.md`.

## Feature 2: Correctness Caps

### Problem

The LLM scorer judges correctness purely from the diff. Code that doesn't compile can still receive high Correctness scores because the diff "looks correct." The host must enforce mechanical caps.

### Cap Rules (Absolute — No Baseline)

| Verification result | Correctness cap |
|---|---|
| Compile failure | 2/10 |
| No verification.json | Uncapped (verification wasn't run) |
| Compile success | Uncapped |

### Cap Rules (With Baseline — Feature 3 Enabled)

| Condition | Correctness cap |
|---|---|
| Baseline compiles, post-agent doesn't | 2/10 |
| Baseline has N test failures, post-agent has N+M (M > 0) | 4/10 |
| Baseline has N test failures, post-agent has ≤ N | Uncapped |
| Baseline verification errored | Uncapped (no reliable baseline) |

### Implementation

New function `apply_verification_caps()` in `score.sh`:
1. Runs after `parse_scores()` (or after `parse_comparison_scores()` in compare mode)
2. For each task, reads verification JSON files
3. If baseline exists, computes delta
4. Clamps Correctness score if it exceeds the cap
5. Returns adjusted totals and logs overrides

### Per-Rubric Score Tracking

The current `parse_scores()` returns only aggregate points/slots. To cap Correctness specifically, the parser must return per-task, per-rubric scores. Data structure:

```
SCORES[task_id:rubric_name] = score_value
SLOTS[task_id:rubric_name] = 10 (or 0 for N/A)
```

After capping, re-aggregate for totals.

### Comparison Mode

Caps applied independently to A and B after randomization reversal. Each agent's verification data lives in its own results directory.

### Auditability

Manifest includes per-task: `verification_cap_applied`, `original_correctness`, `capped_correctness`.

## Feature 3: Pre-Agent Baseline Verification

### Problem

Verification runs only after the agent. If the base commit has pre-existing compile errors or test failures, those are attributed to the agent.

### Sequence (Docker Entrypoint)

```
1. cd /workspace
2. Run setup script (if mounted)
3. Commit setup changes
4. Run baseline verification → /results/baseline-verification.json
5. Run agent
6. Collect diff
7. Run post-agent verification → /results/verification.json
8. Exit
```

Step 4 is new.

### verify-unity.sh Change

Accept optional output filename parameter:
```
verify-unity.sh <project_path> <results_path> [output_name]
# default: verification.json
```

### Host-Side Collection (run-task.sh)

```bash
[[ -f "${TASK_RESULTS_DIR}/baseline-verification.json" ]] && \
    mv ... "${RESULTS_DIR}/${TASK_SUFFIX}.baseline-verification.json"
```

### Scoring Input

Both JSONs included in scorer's task block for reference.

### Failure Modes

- Baseline Unity crashes: Record `{"verification": "error", ...}`. Post-agent verification still runs. Caps not applied.
- Baseline compiles, post-agent crashes: Cap 2/10.
- Baseline has test failures: Only new failures count against agent.

### Scope

Docker pipeline only. Local non-Docker runs skip verification entirely (no Unity in PATH).

## Cross-Cutting: Script Consolidation

`docker/verify-unity.sh` is an outdated copy of `scripts/verify-unity.sh`. The Dockerfile should COPY the canonical scripts/ version. Delete `docker/verify-unity.sh`.

## Manifest Additions

```json
{
  "baseline_verified": true,
  "per_task_verification": {
    "s01": {
      "baseline_compiles": true,
      "baseline_test_failures": 0,
      "post_compiles": true,
      "post_test_failures": 0,
      "cap_applied": false
    }
  }
}
```

## Files Changed

| File | Changes |
|---|---|
| `scripts/score.sh` | New `parse_comparison_scores()`, `apply_verification_caps()`, comparison summary output, per-rubric tracking |
| `scripts/verify-unity.sh` | Accept optional output filename parameter |
| `docker/entrypoint.sh` | Add baseline verification step before agent |
| `docker/verify-unity.sh` | Delete — use scripts/ canonical copy |
| `docker/Dockerfile.unity` | COPY from scripts/verify-unity.sh instead of docker/ |
| `scripts/run-task.sh` | Collect baseline-verification.json from Docker |
| `scripts/run-all.sh` | Pass `--docker-image` through to run-task.sh |
