<!--
repo: https://github.com/Alchemishty/ugb-starter.git
base_sha: c74a25490ef57dab555cea586a301202c93a7a93
difficulty: medium
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task 1: Add Inventory System

**Category:** Feature
**Difficulty:** Medium

## Prompt

> Add an inventory system to the player. Players should be able to hold items by ID with a maximum capacity. The inventory needs to work in multiplayer — all players should see each other's held items.

## What It Exercises

- Choosing appropriate data structures (dictionary, hashset, list) for ID-based storage with capacity
- Deciding between pure C# class vs MonoBehaviour for inventory logic
- NetworkVariable or RPC-based multiplayer sync for inventory state
- Null safety — what happens on capacity overflow, invalid item IDs, uninitialized dependencies
- SOLID — is inventory logic separated from player movement/rendering?
- Test tier classification — EditMode for pure logic, PlayMode for network sync
- Serialization — inventory state across the network

## Expected Touchpoints

- New file: `Data/` or similar — inventory data class (pure C#)
- Modified: `Player/PlayerController.cs` — integration with NetworkVariable sync
- New files: `Tests/EditMode/` — inventory logic tests
- New files: `Tests/PlayMode/` — network sync tests (optional but ideal)

## Landmine Map

- **Landmine #1** (ItemRegistry silent null return): May surface if the agent queries the registry for item validation. Does the agent notice and handle the silent null?
- **Landmine #4** (OnValueChanged in Awake): The existing PlayerController has this bug. When adding inventory sync, does the agent follow the same broken pattern or use OnNetworkSpawn correctly?

## Scoring Notes

- Robustness: Check if `TryAddItem` or equivalent throws/returns meaningful error on null/empty item ID vs silently accepting it
- Architecture: Pure C# inventory class in Data layer scores higher than inventory logic embedded in PlayerController
- Domain Correctness: New NetworkVariable subscriptions must be in OnNetworkSpawn with base calls, not Awake
- Test Quality: Tests should exercise the inventory class directly, not test Unity standard library types
