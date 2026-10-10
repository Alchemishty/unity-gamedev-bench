<!--
repo: https://github.com/Unity-Technologies/com.unity.netcode.gameobjects.git
base_sha: 57f2ff63a3239963a833af75b0a1ff42e7740772
reference_pr: 4145
reference_merge_sha: 5493a5df817ef7b18165215eca5718529763ce13
merge_date: 2026-08-28
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Server Not Tracking Scene Handles for Pre-loaded Scenes

**Source:** com.unity.netcode.gameobjects PR #4145
**Category:** Bug Fix
**Difficulty:** Medium
**Size:** Small (35 additions)
**Repo:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects
**Base Commit:** 57f2ff63a3239963a833af75b0a1ff42e7740772
**Reference PR:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects/pull/4145

## Prompt

> When the server tries to unload a scene that was already loaded before the networking session started, an error is logged and the scene's entry in `ScenesLoaded` is never cleaned up. The scene does unload on all peers, but subsequent scene management operations may behave incorrectly because the stale entry remains. The issue is that pre-loaded scenes are added to `ScenesLoaded` but never registered in the server-to-client scene handle mapping tables.

## What It Exercises

- Correctness: ensuring pre-loaded scenes are registered in the handle mapping
- Robustness: the fix should prevent the stale entry without introducing new edge cases
- Domain Correctness: understanding of `NetworkSceneManager`, scene handle tracking, and the difference between dynamically loaded and pre-loaded scenes
- Architecture: small, targeted fix — should not restructure scene management

## Reference Solution

- Files changed: `NetworkSceneManager.cs`, `NetcodeIntegrationTestHelpers.cs`, `NetworkSceneManagerStartupTests.cs`
- +35 -2 lines
- Core fix: register pre-loaded scenes in the server-to-client handle table during startup

## Scoring Notes

- This is a small fix (35 lines added) but requires understanding the scene management internals
- The agent should identify that the registration step is missing, not add a workaround
- Test should verify that pre-loaded scenes can be cleanly unloaded without stale entries
