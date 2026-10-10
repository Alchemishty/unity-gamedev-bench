# Task: OnValueChanged Not Fired for Initial Value on Spawn

**Source:** com.unity.netcode.gameobjects Issue #3186
**Category:** Feature / Design
**Difficulty:** Medium
**Repo:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects
**Base Commit:** N/A (open issue)
**Reference PR:** None — open feature request

## Prompt

> When a NetworkObject spawns and its NetworkVariables are synchronized with the server's current values, `OnValueChanged` is not called even though the value differs from the default. This forces every NetworkBehaviour to manually read the initial value in `OnNetworkSpawn` after subscribing to `OnValueChanged`, leading to duplicated initialization logic. Design and implement a mechanism to optionally fire `OnValueChanged` for the initial synchronized value during spawn, so that a single `OnValueChanged` handler can cover both initial sync and runtime updates.

## What It Exercises

- Architecture: designing a clean API extension (opt-in behavior, backward compatible)
- Domain Correctness: understanding of NetworkVariable synchronization timing, OnNetworkSpawn ordering, and the difference between default values and server-synchronized values
- Correctness: the solution must not break existing code that relies on the current behavior (no initial callback)
- Test Quality: tests covering both opt-in and default behavior, late-joining clients, and multiple NetworkVariables

## Scoring Notes

- This is a design task, not just a bug fix — the agent must propose an API
- Common approaches: a flag on NetworkVariable (e.g., `FireOnValueChangedOnSpawn`), a separate `OnInitialValueSynced` event, or changing the default behavior with a breaking-change flag
- The agent should consider backward compatibility — existing code relies on OnValueChanged NOT firing on spawn
- The agent should handle the edge case where the synchronized value equals the default (should the callback fire?)
