<!--
repo: https://github.com/annulusgames/LitMotion.git
base_sha: bd384ad672ca7a4338ecb65568c0336b361a7e9c
reference_pr: 9
reference_merge_sha: 862b349d3a862527eb0c063900932bd0af7e7d0c
merge_date: 2023-12-27
rubrics: correctness,robustness,readability,architecture,test_quality
-->

# Task: Completion Callback Recursion Stack Overflow

**Source:** annulusgames/LitMotion PR #9
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Medium (91 additions)
**Repo:** https://github.com/annulusgames/LitMotion
**Base Commit:** bd384ad672ca7a4338ecb65568c0336b361a7e9c
**Reference PR:** https://github.com/annulusgames/LitMotion/pull/9

## Prompt

> When I call `Complete()` on a motion handle inside its own `OnComplete` callback, the application crashes with a `StackOverflowException` due to infinite recursion. Additionally, if I call `Complete()` on a *different* motion handle from within an `OnComplete` callback, that other motion's `OnComplete` fires twice. Both scenarios should be handled gracefully — completing a motion inside a callback should not recurse, and completing a different motion should fire its callback exactly once.

## Prompt Variant: Diagnostic

> Calling `Complete()` on any motion handle from within an `OnComplete` callback causes either a stack overflow (self-completion) or duplicate callback invocation (completing another motion). The application crashes or exhibits double-fire behavior depending on which handle is completed.

## What It Exercises

- Correctness (re-entrant completion must be safe)
- Robustness (guard against recursive invocation, prevent double-fire)
- Architecture (callback scheduling vs immediate invocation)
- Test Quality (runtime tests for re-entrant completion scenarios)

## Reference Solution

3 files changed, 91 additions, 3 deletions. Adds a re-entrancy guard to the completion path and defers nested completions. Runtime tests added for both self-completion and cross-completion scenarios.

## Rubric Applicability

- Domain Correctness: N/A (tween library internals, no direct Unity API in the fix)

## Scoring Notes

The core challenge is re-entrancy safety in a hot-path animation system. The fix must not allocate (this is a performance-critical tweening library). Look for: a re-entrancy flag/counter, deferred completion queue or post-completion pass, and tests covering both the self-complete and cross-complete cases.
