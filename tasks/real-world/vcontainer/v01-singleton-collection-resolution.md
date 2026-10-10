<!--
repo: https://github.com/hadashiA/VContainer.git
base_sha: e743c1059bdc3faf797b04a91ec36dc829bedeb8
reference_pr: 698
reference_merge_sha: fbd23f3d6b06f2172230bafe705fb009d75468c4
merge_date: 2024-08-11
rubrics: correctness,robustness,readability,architecture,test_quality
-->

# Task: Singleton Collection Resolution Across Scopes

**Source:** hadashiA/VContainer PR #698
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Medium (73 additions)
**Repo:** https://github.com/hadashiA/VContainer
**Base Commit:** eb3fbce376225ac221c75b06ea0dd45bc32f4bf6
**Reference PR:** https://github.com/hadashiA/VContainer/pull/698

## Prompt

> I have a parent `LifetimeScope` that registers `A` as a singleton. A child `LifetimeScope` resolves `IEnumerable<A>`. The problem: the child creates a new instance of `A` instead of reusing the singleton from the parent scope. The parent's `A` has `instanceId=0`, but the child's collection contains an `A` with `instanceId=1`. The singleton should be resolved from the parent, not re-created.

## Prompt Variant: Diagnostic

> When resolving a collection type (`IEnumerable<T>`) in a child DI scope, singleton instances registered in the parent scope are not reused. New instances are created instead, violating the singleton lifetime guarantee.

## What It Exercises

- Architecture (DI container scope hierarchy, instance provider chain)
- Correctness (singleton lifetime must be respected across parent/child scopes)
- Robustness (collection resolution must check existing instances before creating new ones)
- Test Quality (scope hierarchy tests)

## Reference Solution

5 files changed, 73 additions, 44 deletions. The `CollectionInstanceProvider` now checks for existing instances in parent containers before creating new ones.

## Rubric Applicability

- Domain Correctness: N/A (DI container logic, no Unity runtime APIs)

## Scoring Notes

This is a hard architecture + DI semantics task. The agent must understand container scoping, instance provider chains, and the difference between registration and resolution. A correct fix ensures `Lifetime.Singleton` is truly global across the scope hierarchy for collection resolution.
