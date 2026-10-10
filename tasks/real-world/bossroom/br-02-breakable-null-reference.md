<!--
repo: https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop.git
base_sha: 279e348965912dd3a616d11210668d146e44a699
reference_pr: 908
reference_merge_sha: 2fc8c1f895cd22b61ce72ddb193b71634361c668
merge_date: 2025-04-28
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: NullReference When Hitting Breakable Objects

**Source:** com.unity.multiplayer.samples.coop PR #908
**Category:** Bug Fix
**Difficulty:** Medium
**Size:** Large (298 additions across 12 files)
**Repo:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop
**Base Commit:** 279e348965912dd3a616d11210668d146e44a699
**Reference PR:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop/pull/908

## Prompt

> When a player strikes a breakable object (like a barrel or crate) with a melee attack, a NullReferenceException is logged. The game doesn't crash but the breakable doesn't take damage correctly. Investigation suggests that some in-scene breakable prefabs are missing their Health NetworkVariable initialization — the Health component exists but its NetworkVariable fields aren't properly configured on the prefab.

## What It Exercises

- Correctness: breakable objects must take damage without errors
- Robustness: missing NetworkVariable initialization should be caught explicitly, not cause a NullRef
- Domain Correctness: understanding of in-scene NetworkObject prefab configuration, NetworkVariable initialization requirements
- Architecture: the fix should handle the root cause (missing prefab config) and add defensive checks in the damage pipeline

## Reference Solution

- Files changed: 12 C# files (+298 -111 lines)
- Core fix: generate Health NetworkVariables and max HP values for breakable prefabs; add null checks in the action/damage pipeline
- Affects action system (AOE, Dash, Melee, Projectile, Trample), breakable objects, and damage receivers

## Scoring Notes

This task requires both code changes and prefab/asset configuration. A code-only solution is incomplete. Architecture rubric evaluates whether defensive changes are systematic vs ad-hoc.

- The agent should identify that the NullRef is from missing prefab configuration, not a code logic error
- A good fix addresses both the prefab data AND adds defensive checks in the damage code path
- The fix spans multiple action types — the agent should fix all paths that interact with breakables, not just melee
