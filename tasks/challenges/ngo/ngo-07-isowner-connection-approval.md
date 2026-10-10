# Task: IsOwner False During ConnectionApproval Spawn

**Source:** com.unity.netcode.gameobjects Issue #3802
**Category:** Bug Fix
**Difficulty:** Hard
**Repo:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects
**Base Commit:** N/A (open issue)
**Reference PR:** None — open issue

## Prompt

> When spawning a player object and a player-owned object during ConnectionApproval, the NetworkBehaviours on the client's GameObjects report `IsOwner` as `false`, even though the NetworkObject itself reports `IsOwner` as `true`. Investigation suggests the client receives the `CreateObjectMessage` for their player and owned objects before the `ConnectionApproved` message, so the client doesn't have an assigned clientId when the NetworkBehaviours initialize. This causes `IsOwner` checks in `OnNetworkSpawn` to fail, breaking any owner-conditional initialization logic.

## What It Exercises

- Correctness: fix the ordering so IsOwner is accurate during OnNetworkSpawn
- Domain Correctness: understanding of the connection approval flow, message ordering (CreateObject vs ConnectionApproved), clientId assignment, and the NetworkBehaviour initialization sequence
- Architecture: the fix should ensure correct ordering without breaking the approval flow for non-owner clients
- Robustness: the fix should handle edge cases (approval rejection, timeout, multiple owned objects)

## Scoring Notes

- This is an open issue — the agent must design the fix
- The core tension is between message ordering (server sends spawn + approval) and client state (clientId not yet assigned)
- Possible approaches: defer NetworkBehaviour initialization until after approval, or send approval before spawns
- The agent should explain the tradeoff between approaches
