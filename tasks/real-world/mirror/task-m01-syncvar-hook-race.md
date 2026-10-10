<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 81d53df55a9569c996f41ba25c5aa5c872bf62a7
reference_pr: 4084
reference_merge_sha: 263bf966811e3e0d191da19bbc7848b63c89c5c4
merge_date: 2026-01-14
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: SyncVar Hook Race Condition on Spawn

**Source:** MirrorNetworking/Mirror PR #4084
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Large (407 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** 81d53df55a9569c996f41ba25c5aa5c872bf62a7
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4084

## Prompt

> During initial spawn on pure clients, SyncVar hooks fire during deserialization before all objects are in the spawned dictionary. This causes race conditions when hooks try to access cross-referenced objects — for example, a player's SyncVar hook tries to look up a team object that hasn't been spawned yet, resulting in null references. Host mode works fine because all objects are already present. The issue only affects pure clients during the initial batch spawn.

## What It Exercises

- Domain Correctness (networking lifecycle ordering, spawn sequencing)
- Architecture (deferred execution pattern, queue management)
- Robustness (handling cross-object references during spawn)
- Test Quality (testing race conditions, host vs client mode differences)

## Reference Solution

4 files changed, 407 additions, 4 deletions. Key changes:
- Added deferred hook queue to NetworkBehaviour
- Modified GeneratedSyncVarDeserialize methods to defer hooks during initial spawn
- Modified NetworkClient.OnObjectSpawnFinished to invoke deferred hooks
- Added comprehensive test coverage for cross-object references

## Scoring Notes

- The core insight is deferring hook execution until after all objects are spawned — any solution that fires hooks during deserialization is incorrect
- Host mode must remain unchanged (hooks fire immediately)
- Post-spawn SyncVar updates must also fire immediately
- Test coverage should verify cross-object references work after deferral
