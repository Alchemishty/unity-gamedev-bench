<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 3a6945f2270afe310ef3e99b7c034907f633bfca
reference_pr: 4079
reference_merge_sha: 81d53df55a9569c996f41ba25c5aa5c872bf62a7
merge_date: 2026-01-12
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Host Client SyncVar Hooks Ignoring AOI Visibility

**Source:** MirrorNetworking/Mirror PR #4079
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Medium (70 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** 3a6945f2270afe310ef3e99b7c034907f633bfca
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4079

## Prompt

> When using Area of Interest (AOI) with a host client, two problems occur: (1) SyncVar hooks fire for ALL objects at spawn, even objects that should be outside the player's AOI range — the host client sees state changes for objects it shouldn't know about. (2) When objects later enter AOI range and become visible, no SyncVar hooks fire for them — the client misses the state transition. This only affects host mode; pure clients with AOI work correctly. The result is that host players see "ghost" state updates from far-away objects but miss updates when objects actually come into range.

## What It Exercises

- Domain Correctness (AOI system interaction with host mode, SyncVar lifecycle)
- Architecture (multi-component fix across NetworkBehaviour, NetworkClient, NetworkIdentity)
- Correctness (handling the asymmetry between host and pure client paths)

## Reference Solution

3 files changed, 70 additions, 13 deletions. Key changes:
- NetworkBehaviour: Added spawned-dictionary check to SyncVar setters
- NetworkIdentity + NetworkClient: Added hostInitialSpawn flag for AOI-aware spawning

## Scoring Notes

- Both problems must be fixed — suppressing hooks for out-of-range objects AND firing hooks when objects enter range
- The fix spans three files — solutions that only touch one file likely miss part of the problem
- Host mode vs pure client distinction must be preserved (pure client behavior unchanged)
