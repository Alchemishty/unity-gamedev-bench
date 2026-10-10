<!--
repo: https://github.com/Alchemishty/ugb-starter.git
base_sha: c74a25490ef57dab555cea586a301202c93a7a93
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task 4: Fix Mysterious Null Reference

**Category:** Bug Fix
**Difficulty:** Medium

## Prompt

> We're getting occasional NullReferenceException in ShopController but can't reproduce it consistently. Stack trace points to the line where we access the item catalog. It seems to happen more in builds than in the editor.

## What It Exercises

- Diagnosing a null propagation bug from a symptom description
- Understanding singleton initialization ordering
- Choosing the right fix: throw at the point of absence vs add another null check downstream
- Root cause analysis vs symptom patching

## Expected Touchpoints

- Modified: `Registry/ItemRegistry.cs` — replace silent null return with throw
- Potentially modified: `UI/ShopController.cs` — fix the call site if needed
- Potentially modified: `API/GameAPI.cs` — fix unvalidated deserialization if the agent investigates the full chain

## Landmine Map

- **Landmine #1** (ItemRegistry silent null return): This IS the root cause. `GetItem()` returns null when `Instance` is null instead of throwing, causing downstream NullReferenceException far from the actual problem.
- **Landmine #5** (Unvalidated deserialization): Secondary — compounds the issue. If API response parsing fails silently, the item lookup chain has two silent null sources.

## Scoring Notes

- Robustness: The root cause fix is replacing `if (Instance == null) return null;` with a throw. Adding a null check in ShopController is patching the symptom and scores lower.
- Correctness: "Happens more in builds" hints at initialization ordering differences between editor and builds. The agent should recognize this.
- Architecture: Fixing the singleton to throw preserves the correct abstraction — callers shouldn't have to defensively check every singleton call.
- Domain Correctness: Understanding that Unity editor may hide timing issues that surface in builds (different script execution order, different initialization timing).
