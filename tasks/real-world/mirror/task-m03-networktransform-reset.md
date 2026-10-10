<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 652ccba23a39dcc9692e2d221d765132f736959a
reference_pr: 4088
reference_merge_sha: a7f91abc8a7da3ff54aeecea9e49effac41b1240
merge_date: 2026-02-02
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: NetworkTransform Reset Initializes With Zeros Instead of Actual Values

**Source:** MirrorNetworking/Mirror PR #4088
**Category:** Bug Fix
**Difficulty:** Medium
**Size:** Small (34 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** 652ccba23a39dcc9692e2d221d765132f736959a
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4088

## Prompt

> When a host client spawns a NetworkTransform object, the object's position gets doubled. For example, an object at position (5, 0, 0) ends up at (10, 0, 0) after spawn. This happens because `ResetState` initializes the `last` position/rotation/scale values to zeros instead of the object's actual transform values. When the client sends its first update to the server, it computes a delta from zero, which the host applies as if it were a real movement — effectively adding the position twice. Pure server or pure client spawns work correctly; it's only the host client path that breaks.

## Prompt Variant: Diagnostic

> When running as a host, spawned NetworkTransform objects end up at double their intended position. An object placed at (5, 0, 0) in the scene appears at (10, 0, 0) after spawn. Dedicated server and client-only modes work correctly. The issue only reproduces when the same process is both server and client.

## What It Exercises

- Domain Correctness (NetworkTransform lifecycle, spawn initialization)
- Correctness (understanding delta-based sync and initialization)
- Architecture (consistent fix across Reliable and Hybrid variants)

## Reference Solution

2 files changed, 34 additions, 17 deletions. Key changes:
- NetworkTransformReliable.ResetState: initialize `last` values from actual transform instead of zeros
- NetworkTransformHybrid.ResetState: same fix applied consistently

## Scoring Notes

- The fix must be applied to BOTH NetworkTransformReliable and NetworkTransformHybrid — fixing only one is incomplete
- The root cause is initialization from zero, not the delta computation — a fix that special-cases the first update is a symptom fix
- The agent should understand why host mode specifically triggers this (server and client share the transform)
