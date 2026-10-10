<!--
repo: https://github.com/hadashiA/VContainer.git
base_sha: 7d839caeb73b6b97d996688333e26ed534f55aad
reference_pr: 734
reference_merge_sha: e74d88225f8162b95ef682e86834938d46b6ef97
merge_date: 2024-12-20
rubrics: correctness,robustness,readability,architecture,test_quality
-->

# Task: IStartable.Start Called Repeatedly After Exception

**Source:** hadashiA/VContainer PR #734
**Category:** Bug Fix
**Difficulty:** Medium
**Size:** Medium (97 additions)
**Repo:** https://github.com/hadashiA/VContainer
**Base Commit:** 7d839caeb73b6b97d996688333e26ed534f55aad
**Reference PR:** https://github.com/hadashiA/VContainer/pull/734

## Prompt

> When a class implementing `IStartable` throws an exception in its `Start()` method, VContainer calls `Start()` again on every subsequent frame instead of just once. The exception causes the player loop item to remain in the "not started" state, so the framework keeps retrying indefinitely. This floods the console with repeated exceptions and can cause performance issues. `IStartable.Start()` should execute exactly once regardless of whether it throws.

## Prompt Variant: Diagnostic

> An `IStartable` implementation that throws in `Start()` causes the method to be called repeatedly every frame, flooding the console with exceptions. Expected: `Start()` should fire exactly once, even if it throws.

## What It Exercises

- Correctness (exactly-once execution semantics)
- Robustness (exception safety in lifecycle dispatch)
- Architecture (player loop item state management)
- Test Quality (test that verifies single invocation despite exception)

## Reference Solution

4 files changed, 97 additions, 76 deletions. The `EntryPointDispatcher` marks the startable as completed before invoking it, ensuring exceptions don't cause retry. Excludes `UserSettings/Layouts/default-2021.dwlt` (unrelated editor layout file in the PR).

## Rubric Applicability

- Domain Correctness: N/A (DI container logic, no Unity runtime APIs)

## Scoring Notes

Ignore any `.dwlt` or editor layout file changes — those are unrelated to the fix. The key insight: mark-as-started must happen *before* the invocation, not after. If the agent marks after invocation, the exception still causes retry.
