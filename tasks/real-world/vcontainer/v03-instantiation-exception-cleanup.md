<!--
repo: https://github.com/hadashiA/VContainer.git
base_sha: 897c47f6f113ec93d59aaca365fd49162b8ef78b
reference_pr: 660
reference_merge_sha: bfc5e58d34b822bb10d41f67d69924b38f9a2d51
merge_date: 2024-04-28
rubrics: correctness,robustness,readability,architecture,test_quality
-->

# Task: Exception-Safe Cleanup During Component Instantiation

**Source:** hadashiA/VContainer PR #660
**Category:** Bug Fix
**Difficulty:** Medium
**Size:** Medium (61 additions)
**Repo:** https://github.com/hadashiA/VContainer
**Base Commit:** 897c47f6f113ec93d59aaca365fd49162b8ef78b
**Reference PR:** https://github.com/hadashiA/VContainer/pull/660

## Prompt

> When VContainer instantiates a GameObject and one of its MonoBehaviour components throws an exception during injection (e.g., in `Awake` or during property injection), the partially-created GameObject is left in the scene with an inconsistent state. The container doesn't clean up the failed instantiation — the broken GameObject remains, and subsequent resolution attempts may interact with it. The instantiation should be atomic: if any component fails during injection, the entire GameObject should be destroyed and the exception propagated.

## Prompt Variant: Diagnostic

> Instantiating a prefab through VContainer where a component throws during injection leaves a broken GameObject in the scene. No cleanup occurs. Expected: failed instantiation should not leave partial objects.

## What It Exercises

- Robustness (try/finally cleanup pattern, atomic operations)
- Correctness (no partial state left on failure)
- Architecture (exception safety in object lifecycle management)
- Test Quality (test with a deliberately-crashing MonoBehaviour)

## Reference Solution

4 files changed, 61 additions, 8 deletions. A try/catch in `ObjectResolverUnityExtensions` wraps the instantiation and injection, destroying the GameObject on failure. Test added with a `CrashingSampleMonoBehaviour` fixture.

## Rubric Applicability

- Domain Correctness: N/A (DI container logic, no Unity runtime APIs)

## Scoring Notes

The agent should wrap the instantiate-then-inject sequence in try/catch, with `Object.Destroy(gameObject)` in the catch block before rethrowing. Look for the test fixture — a MonoBehaviour that throws in Awake or during injection to verify cleanup.
