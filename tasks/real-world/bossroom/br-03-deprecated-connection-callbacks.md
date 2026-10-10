<!--
repo: https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop.git
base_sha: a7426d8f7d5a13d7a597eea0e2b4efadb6ba900f
reference_pr: 907
reference_merge_sha: 279e348965912dd3a616d11210668d146e44a699
merge_date: 2025-04-07
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Replace Deprecated Connection Callbacks

**Source:** com.unity.multiplayer.samples.coop PR #907
**Category:** Refactor
**Difficulty:** Medium
**Size:** Medium (106 additions)
**Repo:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop
**Base Commit:** a7426d8f7d5a13d7a597eea0e2b4efadb6ba900f
**Reference PR:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop/pull/907

## Prompt

> The project uses the deprecated `OnClientConnected` and `OnClientDisconnected` callbacks from Netcode for GameObjects. These have been replaced by the unified `OnConnectionEvent` callback in newer versions. Migrate all usages across the project and its Utilities package to use the new `OnConnectionEvent` API. Also remove any unnecessary `Despawn` invocations on NetworkObjects that are already marked to despawn with their owner.

## What It Exercises

- Correctness: all connection/disconnection handling must work identically after migration
- Architecture: the migration touches connection management, game state, character selection, message channels, and scene loading — tests cross-system refactoring ability
- Domain Correctness: understanding of the OnConnectionEvent API (ConnectionEventData, EventType), and the difference between the old per-event callbacks and the unified event
- Readability: the new code should be cleaner than the old pattern

## Reference Solution

- Files changed: 6 C# files (+106 -72 lines)
- Core change: replace `OnClientConnected += handler` / `OnClientDisconnected += handler` with `OnConnectionEvent += handler` using `ConnectionEventData.EventType` to distinguish connect/disconnect
- Also removes a redundant `Despawn` call

## Scoring Notes

- This is a straightforward API migration but tests the agent's ability to find all usages across a multi-project solution
- The agent should not miss any usage — grep for `OnClientConnected` and `OnClientDisconnected`
- The redundant Despawn removal is a secondary fix that tests whether the agent notices unnecessary code
