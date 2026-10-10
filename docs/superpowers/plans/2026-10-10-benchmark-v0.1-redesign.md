# unity-gamedev-bench v0.1 Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a compact benchmark that scores an agent 0–100 on 10 fixed Unity tasks within 40 minutes, with cost reporting, verification coverage, and historical comparison.

**Architecture:** Fixed 10-task standard suite. Task score = mean of applicable rubric scores × 10. Benchmark score = mean of 10 task scores. Parallel execution (default 3). Immutable snapshot preparation before parallel workers. Verification is opportunistic — coverage reported as N/10, no task labelled verified without data. Historical deltas require exact digest match over suite+rubrics+scorer prompt+scorer model+formula.

**Tech Stack:** Zsh scripts, Bats tests, jq, Claude CLI.

**Spec:** User specification from 2026-10-10 conversation + review corrections.

## Global Constraints

- Zsh for all scripts (verify-unity.sh is Bash for Docker compat)
- JSON via jq when available, heredoc fallback
- No dependencies beyond: git, jq, claude CLI, bats (tests only)
- results/ gitignored
- No comparison mode, no cutoff, no allow-partial
- Infrastructure failure = run invalid. Agent failure = task scores 0. Never average over <10 tasks.
- Scorer output: only declared rubrics, no nulls, integers 0–10 only

## Review Focus

1. **Scorer gives N/A for a declared rubric** — validation rejects the run.
2. **Infrastructure failure vs agent failure** — setup/checkout/Docker/scorer failure invalidates run; agent crash or empty diff scores 0.
3. **Parallel workers mutating shared cache** — workers copy from immutable snapshots prepared serially; never fetch.
4. **Score generation digest mismatch** — different digest = side-by-side only, never a delta table.
5. **Architecture rubric rewarding overengineering** — anchors must value "appropriate for the size of the change" not "must have interfaces."

---

### Task 1: Suite Configuration and Task Metadata

**Files:**
- Create: `suites/standard.json`
- Create: `suites/smoke.json`
- Modify: 10 task files — add `difficulty:` to metadata
- Delete: `rubrics/07-efficiency.md`

**Produces:** Suite JSON files consumed by run-all.sh. Format: `{"name":"standard","version":"v1","tasks":["s01",...],"task_count":10}`

- [ ] Create `suites/standard.json` with 10 tasks: s01, s03, s05, s07, m01, m02, m04, m08, m11, m13
- [ ] Create `suites/smoke.json` with 3 tasks: s01, m04, m13
- [ ] Add `difficulty: easy|medium|hard` to metadata block of each standard task (from existing `**Difficulty:**` lines)
- [ ] Delete `rubrics/07-efficiency.md`
- [ ] Commit: `"Define standard and smoke suites, add difficulty metadata"`

---

### Task 2: Rewrite Rubric Anchors

**Files:**
- Modify: `rubrics/01-correctness.md` through `rubrics/06-test-quality.md`

**Produces:** Rubric definitions with even-number anchors (0/2/4/6/8/10), framework-neutral language. Architecture values "appropriate for size of change." Domain correctness is framework-neutral — framework-specific expectations go in per-task scorer notes.

- [ ] Rewrite all 6 rubrics with concrete observable-evidence anchors at 0/2/4/6/8/10
- [ ] Architecture 10 = "Correct separation for the scope. No unnecessary abstractions. Dependencies point in the right direction."
- [ ] Domain Correctness = framework-neutral: "Correct lifecycle, framework, serialization, threading, networking, and performance behavior relevant to this task."
- [ ] Correctness includes verification override note: compile failure → cap 2, test regression → cap 4
- [ ] Commit: `"Rewrite rubric anchors with concrete 0/2/4/6/8/10 thresholds"`

---

### Task 3: Rewrite Scoring Agent Prompt

**Files:**
- Rewrite: `scoring/scoring-agent-prompt.md`

**Produces:** Scorer prompt that embeds rubric anchors, requests JSON output (one line per task), includes anti-injection preamble. No comparison mode.

Scorer output format — only declared rubrics, no nulls:
```json
{"task":"s01","scores":{"correctness":8,"robustness":7,"readability":8,"architecture":7,"domain_correctness":8,"test_quality":6},"violations":["file.cs:12 — description"]}
```

- [ ] Write new scorer prompt with embedded anchor tables, JSON output spec, anti-injection rules
- [ ] Instruct: score ONLY declared rubrics, no nulls, integers 0–10, missing/extra/null = invalid
- [ ] Include per-task scorer notes section for framework-specific guidance
- [ ] Commit: `"Rewrite scorer prompt: JSON output, embedded anchors, strict rubric enforcement"`

---

### Task 4: Rewrite run-task.sh

**Files:**
- Rewrite: `scripts/run-task.sh`

**Produces:** Per-task outputs: `.diff`, `.meta.json`, `.log`. Clean isolation: delete .git, init fresh, assert one commit + no remote.

Key changes:
- No IS_SYNTHETIC special case (already removed)
- Isolation: copy from immutable snapshot (prepared by run-all.sh), delete .git, init, commit
- Extract only prompt blockquotes — never pass scoring notes, landmine maps, reference SHAs
- Record timing in meta.json
- Token parsing: best-effort from Claude CLI output, null if unavailable
- Accepts `--snapshot-dir` flag (prepared snapshot path from run-all.sh) to skip clone/fetch

- [ ] Write new run-task.sh with snapshot-based isolation
- [ ] Meta.json includes: task_id, difficulty, timestamp, duration_seconds, agent_cmd, model, prompt_mode, docker, network, agent_exit_code, diff_lines, status, tokens_in (nullable), tokens_out (nullable)
- [ ] Commit: `"Rewrite run-task.sh: snapshot isolation, token tracking"`

---

### Task 5: Rewrite run-all.sh

**Files:**
- Rewrite: `scripts/run-all.sh`

**Produces:** `results/<label>/` with all task outputs + `run-request.json`

Interface:
```
./scripts/run-all.sh --agent <cmd> --label <name> --suite standard [--parallel 3] [options]
./scripts/run-all.sh --agent <cmd> --label <name> --suite smoke --parallel 1
./scripts/run-all.sh --agent <cmd> --label <name> s01 m01  # explicit IDs
```

Key design:
1. **Serial preparation phase:** for each unique repo+SHA, fetch into cache and copy to an immutable snapshot dir. Workers never fetch.
2. **Parallel execution:** launch up to N background jobs with PID tracking. Collect individual exit codes.
3. **`--parallel <n>`** flag, default 3. `--parallel 1` for sequential.
4. Stale result rejection (existing .diff/.failed)
5. run-request.json records: suite version, parallel count, all environment metadata, track info

- [ ] Write serial snapshot preparation (unique repo+SHA dedup)
- [ ] Write parallel execution with PID-to-task mapping and exit status collection
- [ ] Write run-request.json with full environment recording
- [ ] Commit: `"Rewrite run-all.sh: suite support, snapshot prep, parallel execution"`

---

### Task 6: Rewrite score.sh

**Files:**
- Rewrite: `scripts/score.sh`

**Produces:** `manifest.json`, `scoring-report.md`, `scoring-output-1.json`

Scoring math:
```
task_score = (sum of rubric scores / count of rubrics) × 10    → 0–100
benchmark_score = sum of 10 task scores / 10                    → 0–100
```

- All 10 tasks must be present or run is invalid
- Agent failure/empty diff = task scores 0
- Infrastructure failure (setup, checkout, scorer) = run invalid
- Verification caps apply to correctness before task score computation
- Verification coverage reported as N/10
- Score generation = digest of: suite JSON + rubric files + scorer prompt + scorer model + scoring formula version
- Tokens/cost: report when available, null otherwise. Dollar estimate only with explicit pricing_version.

Scorer invocation: `--bare --tools "" --disable-slash-commands --strict-mcp-config`, input via stdin, JSON output.

Parse scorer JSON: one line per task. Validate: only declared rubrics, integers 0–10, no missing, no extra.

- [ ] Write scoring input assembly (prompt + diffs + per-task declared rubrics + task-specific scorer notes)
- [ ] Write scorer invocation and JSON output parsing
- [ ] Write score computation (equal-weight mean)
- [ ] Write verification cap application
- [ ] Write manifest generation with score_generation digest, timing, cost, verification coverage
- [ ] Write scoring-report.md (human-readable summary)
- [ ] Commit: `"Rewrite score.sh: 0-100 model, JSON parsing, generation digest, cost reporting"`

---

### Task 7: Historical Comparison

**Files:**
- Create: `scripts/compare.sh`
- Modify: `scripts/score.sh` — auto-invoke compare after scoring

**Produces:** Delta table on stdout, `comparison.json` in results dir.

Rules:
- Exact score_generation digest match → comparable delta with interpretation guidance
- Different digest → side-by-side display only, labelled "non-comparable (different generation)"
- Agent model is allowed to differ (that's what's being measured)
- Auto-find: walk results/*/manifest.json for most recent with matching digest

Delta display:
```
                        previous → current    Δ
Overall                     72.8 → 76.1    +3.3
Correctness                 74.0 → 79.0    +5.0
...
Compile pass                8/10 → 9/10
Verified                    3/10 → 3/10
Median task time             181s → 166s
Tokens                       94k → 101k

Interpretation: <2 pts = unchanged, 2-5 = directional, >5 = material
```

- [ ] Write compare.sh with digest matching and delta formatting
- [ ] Write auto-find logic for latest compatible previous run
- [ ] Integrate into score.sh post-scoring
- [ ] Commit: `"Add historical comparison with generation digest matching"`

---

### Task 8: Scorer Calibration Fixtures

**Files:**
- Create: `tests/fixtures/calibration/` — 5 frozen scoring inputs
- Create: `tests/calibration.bats` — schema tests with fake scorer
- Create: `scripts/calibrate.sh` — manual real-scorer stability test (env-gated)

Two calibration operations:
1. **CI (Bats):** fake-scorer tests for JSON schema validation and score math
2. **Manual (`calibrate.sh`):** score each fixture 3× with real scorer, report spread. Gated behind `UGB_CALIBRATE=1`.

- [ ] Create 5 fixtures: empty-diff, broken-compile, partial-correct, strong-solution, irrelevant-diff
- [ ] Write Bats tests using fake scorer for schema/math validation
- [ ] Write calibrate.sh for manual 3× stability measurement
- [ ] Commit: `"Add scorer calibration: CI schema tests + manual stability script"`

---

### Task 9: Migrate Test Suite

**Files:**
- Modify: `tests/test_helper/common.bash`
- Delete: tests for removed features (comparison, cutoff, partial)
- Adapt: tests for changed features (scoring model, manifest format)
- Create: new tests for suites, parallel, history, 0–100 scoring

Approach: migrate incrementally, not delete-and-rewrite.

**Delete:** comparison.bats, cutoff.bats (features removed)
**Adapt:** score.bats (new scoring model), completeness.bats (10-or-invalid), verification.bats (cap math), scorer-isolation.bats (JSON output), rubric-metadata.bats (standard suite only)
**Keep as-is:** stale-reuse.bats, run-task.bats, task-validation.bats, track-validation.bats (still valid), classification.bats
**Create:** suite-config.bats, parallel.bats, history.bats, scoring-model.bats

- [ ] Delete comparison.bats, cutoff.bats
- [ ] Adapt score.bats for JSON parsing and 0–100 model
- [ ] Adapt completeness.bats for 10-or-invalid rule
- [ ] Adapt scorer-isolation.bats for JSON output and stdin
- [ ] Adapt rubric-metadata.bats for standard suite tasks
- [ ] Update test_helper/common.bash for new fixture format
- [ ] Create suite-config.bats (suite loading, task count, resolution)
- [ ] Create scoring-model.bats (equal-weight mean, cap math, infrastructure invalidity)
- [ ] Create history.bats (digest matching, delta formatting)
- [ ] Verify all tests pass
- [ ] Commit: `"Migrate test suite: adapt existing, add suite/scoring/history tests"`

---

### Task 10: README and Docs

**Files:**
- Rewrite: `README.md`
- Delete: stale docs (`docs/architecture.md`, `docs/conventions.md`, `docs/domain.md`, `docs/testing.md`, stale READMEs in subdirs)
- Keep: `scoring/scoring-agent-prompt.md`, `scripts/ISOLATION.md` (update)

- [ ] Write new README: one-paragraph description, quick start (5 commands), what it measures, interpreting results, contamination statement, contributing (more tasks + verification)
- [ ] Delete stale docs
- [ ] Update ISOLATION.md for new shallow-clone + snapshot approach
- [ ] Commit: `"Update README and docs for v0.1"`

---

### Task 11: End-to-End Verification

No files — validates the complete pipeline.

- [ ] `bats tests/` — all tests pass
- [ ] Smoke run: `./scripts/run-all.sh --agent "claude -p --dangerously-skip-permissions" --label smoke-v01 --suite smoke --parallel 1` then `./scripts/score.sh results/smoke-v01 --auto`
- [ ] Standard run: `./scripts/run-all.sh --agent "claude -p --dangerously-skip-permissions" --label standard-v01 --suite standard` then `./scripts/score.sh results/standard-v01 --auto`
- [ ] Second run to verify historical comparison produces delta table
- [ ] Push
