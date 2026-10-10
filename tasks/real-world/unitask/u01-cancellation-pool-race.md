<!--
repo: https://github.com/Cysharp/UniTask.git
base_sha: 01c8fada1f4d48465f7ef31b46b150d4f6e428aa
reference_pr: 557
reference_merge_sha: b724a2aa84640975ce48c4505b1b0a64c79585ef
merge_date: 2024-03-28
rubrics: correctness,robustness,readability,test_quality
-->

# Task: Cancellation Race with Pooled Delay Objects

**Source:** Cysharp/UniTask PR #557
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Large (257 additions)
**Repo:** https://github.com/Cysharp/UniTask
**Base Commit:** 01c8fada1f4d48465f7ef31b46b150d4f6e428aa
**Reference PR:** https://github.com/Cysharp/UniTask/pull/557

## Prompt

> I'm using `UniTask.Delay` with `cancelImmediately: true`. When I cancel one delay and immediately start another delay in the same frame, the second delay sometimes completes instantly (in the same frame) instead of waiting the specified duration. The behavior is non-deterministic and appears related to object pooling — the newly created delay seems to reuse a pooled object that was just cancelled, inheriting its completed state. This causes downstream timing issues: operations that should take 2 seconds complete instantly.

## Prompt Variant: Diagnostic

> `UniTask.Delay` with `cancelImmediately: true` exhibits incorrect timing. After cancelling one delay and starting another in the same frame, the second delay sometimes completes instantly. The bug is intermittent and timing-dependent.

## What It Exercises

- Correctness (pool object lifecycle, state reset on reuse)
- Robustness (race condition between cancellation and pool return)
- Architecture (understanding Unity's PlayerLoop and pooled async primitives)
- Domain Correctness (Unity async patterns, cancellation token lifecycle)

## Reference Solution

7 files changed, 257 additions, 146 deletions. The fix ensures pooled objects are fully reset before being returned to the pool, and that `cancelImmediately` properly sequences the cancellation callback relative to pool return.

## Rubric Applicability

- Domain Correctness: N/A (async/pooling library internals)

## Scoring Notes

This is one of the hardest tasks in the benchmark. The agent must understand: UniTask's pooling mechanism, Unity's PlayerLoop timing, the relationship between `cancelImmediately` and pool lifecycle, and same-frame reuse hazards. A partial fix (e.g., fixing only `UniTask.Delay` but not `WaitUntil` or `AsyncGPUReadback`) should score lower on correctness. Architecture should not be scored — this is N/A as the fix works within established patterns.
