<!--
repo: https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop.git
base_sha: 971daefcc5242b62354abb28f2d710ad553e13e6
reference_pr: 922
reference_merge_sha: 7336b3e94d917e751ddd1b30e31ad3c47f6b1a8f
merge_date: 2025-07-28
rubrics: correctness,robustness,readability,domain_correctness
-->
# Task: Name Generation Off-By-One

**Source:** com.unity.multiplayer.samples.coop PR #922
**Category:** Bug Fix
**Difficulty:** Easy
**Size:** Trivial (3 lines changed)
**Repo:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop
**Base Commit:** 971daefcc5242b62354abb28f2d710ad553e13e6
**Reference PR:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop/pull/922

## Prompt

> Player name generation never uses the last entry in the first-name and last-name arrays. The random range is exclusive of the upper bound, but the arrays use `.Length` which is already one past the last valid index — except the code is using `.Length - 1` as the upper bound, making it exclude the last valid item. The last name in each array is never selected.

## Prompt Variant: Diagnostic

> QA noticed that certain player names never appear in the game. After hundreds of test sessions, the last entry in both the first-name and last-name lists has never been randomly selected. All other names appear with roughly equal frequency.

## What It Exercises

- Correctness: all names in the arrays should have equal probability of selection
- Readability: the fix should be clear about inclusive vs exclusive bounds

## Reference Solution

- Files changed: 1 C# file (`NameGenerationData.cs`, +3 -3 lines)
- Core fix: change `Random.Range(0, array.Length - 1)` to `Random.Range(0, array.Length)`

## Rubric Applicability

- Architecture: N/A (one-line bounds fix)
- Test Quality: N/A (trivial fix, scoring notes specify not to over-engineer)

## Scoring Notes

- This is a trivial off-by-one — tests whether the agent can identify and fix the simplest possible bug quickly
- The agent should NOT over-engineer this (no refactoring, no added tests for a 3-line fix)
- `Random.Range(int, int)` in Unity is exclusive of the upper bound — the agent must know this
