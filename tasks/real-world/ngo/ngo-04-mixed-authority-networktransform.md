<!--
repo: https://github.com/Unity-Technologies/com.unity.netcode.gameobjects.git
base_sha: bd121632f3c7b311f3c0746b920d7d8621e63d6e
reference_pr: 4169
reference_merge_sha: fdadb7dac5dfd610f28e8146c23e4797d5440d48
merge_date: 2026-10-02
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Mixed Authority Nested NetworkTransform Stops Updating

**Source:** com.unity.netcode.gameobjects PR #4169
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Large (242 additions)
**Repo:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects
**Base Commit:** bd121632f3c7b311f3c0746b920d7d8621e63d6e
**Reference PR:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects/pull/4169

## Prompt

> On a NetworkObject with multiple nested NetworkTransform components that have different authority modes (some server-authoritative, some owner-authoritative), the non-authority child NetworkTransforms stop updating entirely. They freeze in place while the authority instance continues to work correctly. The issue appears to be related to how NetworkObjects are registered in the update groups — the first authority instance to initialize removes the entire NetworkObject from the non-authority update group, preventing its siblings from receiving updates.

## What It Exercises

- Correctness: fix must allow mixed authority modes on the same NetworkObject
- Domain Correctness: understanding of NetworkManager update registration, per-NetworkObject vs per-NetworkTransform authority, and the update group lifecycle
- Architecture: the update registration model assumes uniform authority per NetworkObject — the fix needs to handle the mixed case
- Test Quality: runtime tests for mixed authority motion models

## Reference Solution

- Files changed: `NetworkTransform.cs`, `NetworkTransformMixedAuthorityTests.cs`, `NetworkTransformMixedMotionModelTests.cs`, `NetcodeIntegrationTest.cs`
- +242 -52 lines
- Core fix: update registration tracks authority per-NetworkTransform, not per-NetworkObject

## Scoring Notes

- This is architecturally interesting — the agent must recognize that per-NetworkObject registration is the wrong granularity
- A workaround (re-registering after authority changes) would be fragile; the correct fix changes the registration model
- Tests should cover nested transforms with different authority modes updating simultaneously
