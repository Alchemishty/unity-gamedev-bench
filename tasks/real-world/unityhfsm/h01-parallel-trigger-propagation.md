<!--
repo: https://github.com/Inspiaaa/UnityHFSM.git
base_sha: beb58daf989ec3b095a4c6ff627a58da736f8b81
reference_pr: 54
reference_merge_sha: d1f47dd4e6f24730ec774ababb71da3169b92b84
merge_date: 2025-03-21
rubrics: correctness,robustness,readability,architecture,test_quality
-->

# Task: ParallelStates Trigger Propagation

**Source:** Inspiaaa/UnityHFSM PR #54
**Category:** Bug Fix
**Difficulty:** Medium
**Size:** Small (32 additions)
**Repo:** https://github.com/Inspiaaa/UnityHFSM
**Base Commit:** beb58daf989ec3b095a4c6ff627a58da736f8b81
**Reference PR:** https://github.com/Inspiaaa/UnityHFSM/pull/54

## Prompt

> I have two state machines running in parallel via `ParallelStates`. Each sub-machine has trigger transitions defined (e.g., trigger "T" transitions A→B in one machine, C→D in the other). When I call `Trigger("T")` on the root state machine, neither parallel sub-machine reacts — the transitions don't fire. This makes `ParallelStates` unusable with trigger-based transitions. The same triggers work correctly when the machines are not wrapped in `ParallelStates`.

## Prompt Variant: Diagnostic

> Calling `Trigger("T")` on a root state machine that contains a `ParallelStates` node has no effect. The parallel sub-machines don't transition. Non-parallel configurations work fine with the same triggers.

## What It Exercises

- Architecture (implementing an interface to propagate behavior through a composite pattern)
- Correctness (trigger propagation through nested/parallel state machines)
- Test Quality (regression test for the fix)
- Readability (clean integration with existing interface hierarchy)

## Reference Solution

2 files changed, 32 additions, 1 deletion. `ParallelStates` implements `ITriggerable` and forwards triggers to all sub-machines. Test added to verify propagation.

## Rubric Applicability

- Domain Correctness: N/A (pure C# state machine logic, no Unity API usage in the fix)

## Scoring Notes

The key architectural insight: `ParallelStates` needs to implement `ITriggerable` to participate in the trigger dispatch chain. A correct fix should also handle the edge case where a sub-machine's guard checks the active state of a sibling machine.
