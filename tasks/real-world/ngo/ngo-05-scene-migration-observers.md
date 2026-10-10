<!--
repo: https://github.com/Unity-Technologies/com.unity.netcode.gameobjects.git
base_sha: fdadb7dac5dfd610f28e8146c23e4797d5440d48
reference_pr: 4185
reference_merge_sha: 5982716597b79c879505befb3ed72a31eb116764
merge_date: 2026-10-06
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Scene Migration Messages Sent to Non-Observers

**Source:** com.unity.netcode.gameobjects PR #4185
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Large (279 additions)
**Repo:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects
**Base Commit:** fdadb7dac5dfd610f28e8146c23e4797d5440d48
**Reference PR:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects/pull/4185

## Prompt

> Two issues with scene migration for hidden NetworkObjects: (1) When a NetworkObject that is hidden from some clients moves to another scene, those clients log an error about receiving a migration message for an object they don't know about. (2) When a hidden NetworkObject is later shown to a client, it spawns in the wrong scene — it appears in the default scene instead of the scene the authority moved it to. Both issues affect client-server and distributed authority modes.

## What It Exercises

- Correctness: fix both the error-on-migration and the wrong-scene-on-show issues
- Domain Correctness: understanding of observer patterns, NetworkObject visibility (ShowObjectToClient/HideObjectFromClient), scene migration messaging, and CreateObjectMessage
- Architecture: the fix should cleanly separate observer-aware migration from spawn messages
- Robustness: clients that can't see an object should silently skip its migration, not error

## Reference Solution

- Files changed: `CreateObjectMessage.cs`, `NetworkSceneManager.cs`, `SceneEventData.cs`, `NetworkObjectSceneMigrationObserverTests.cs`
- +279 -25 lines
- Core fix: migration messages only sent to observers; CreateObjectMessage includes scene info for late-shown objects

## Scoring Notes

- Two distinct but related bugs — the agent should fix both
- The observer check must happen at message-send time, not receive time
- Test should verify that hidden objects don't generate client errors and show in the correct scene when revealed
