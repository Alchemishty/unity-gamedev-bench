<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: bbcb417bdfeffb181abd0dfaaab19a15ceb78b66
reference_pr: 4090
reference_merge_sha: 5a77135250489feaa8283f7ed2d7d27760b2e202
merge_date: 2026-02-06
rubrics: correctness,test_quality
-->
# Task: Add EditMode Tests for NetworkStartPosition

**Source:** MirrorNetworking/Mirror PR #4090
**Category:** Test
**Difficulty:** Easy
**Size:** Small (41 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** bbcb417bdfeffb181abd0dfaaab19a15ceb78b66
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4090

## Prompt

> `NetworkStartPosition` currently has zero test coverage. Write EditMode tests to reach full coverage. The component manages spawn positions for players — it registers itself in `Awake`, unregisters in `OnDestroy`, and maintains a static list of available positions. Test the full lifecycle: registration, unregistration, duplicate handling, and the static list state.

## What It Exercises

- Test Quality (achieving full coverage, testing lifecycle, static state management)
- Domain Correctness (understanding MonoBehaviour lifecycle in test context)
- Readability (descriptive test names, AAA pattern)

## Reference Solution

1 file changed, 41 additions. Pure test file added.

## Rubric Applicability

- Robustness: N/A (test-only task, no production code changes)
- Readability: N/A (test-only task)
- Architecture: N/A (test-only task)
- Domain Correctness: N/A (test-only task)

Only Correctness and Test Quality are scored.

## Scoring Notes

- Tests must be EditMode (NetworkStartPosition uses Awake/OnDestroy, testable without Play mode via direct method calls or GameObject lifecycle)
- Should test: Awake adds to static list, OnDestroy removes from static list, duplicate registration handling, list state after multiple registrations/unregistrations
- Tests should be behavioral — assert the state of the static positions list, not internal implementation details
