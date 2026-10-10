<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 3a6945f2270afe310ef3e99b7c034907f633bfca
reference_pr: 4081
reference_merge_sha: b4083a51fdfd6321dbd460158fbed9b4cf8c1842
merge_date: 2026-01-11
rubrics: correctness,robustness,readability,domain_correctness,test_quality
-->

# Task: NullReferenceException After Failed StartHost

**Source:** MirrorNetworking/Mirror PR #4081
**Category:** Bug Fix
**Difficulty:** Easy
**Size:** Trivial (36 lines changed)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** 3a6945f2270afe310ef3e99b7c034907f633bfca
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4081

## Prompt

> When `StartHost()` fails during server setup (e.g., the port is already in use), subsequent calls to `StopHost()` or `StopClient()` throw a `NullReferenceException`. The application gets stuck in an inconsistent state — it thinks it's in Host mode but has no valid local connection. Restarting the host requires restarting the application entirely.

## Prompt Variant: Diagnostic

> After a failed `StartHost()` (port conflict), calling `StopHost()` crashes with a NullReferenceException. The NetworkManager cannot recover from a failed host start without restarting the application.

## What It Exercises

- Robustness (null guard on connection object after failed initialization)
- Correctness (proper cleanup path when startup fails)
- Test Quality (regression test for the failure-then-cleanup sequence)

## Reference Solution

2 files changed, 36 additions, 1 deletion. Null check added before accessing `localConnection` in `StopClient`. Editor test added for the failure sequence.

## Rubric Applicability

- Architecture: N/A (small targeted null-guard fix)

## Scoring Notes

Architecture is N/A — this is a small targeted fix. The fix is straightforward but the agent should also add a regression test that reproduces the failure-then-cleanup sequence. Look for whether the agent addresses both `StopHost()` and `StopClient()` paths.
