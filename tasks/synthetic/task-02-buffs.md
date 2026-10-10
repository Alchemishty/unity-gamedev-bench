<!--
repo: https://github.com/Alchemishty/ugb-starter.git
base_sha: c74a25490ef57dab555cea586a301202c93a7a93
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task 2: Add Buff/Debuff System

**Category:** Feature
**Difficulty:** Hard

## Prompt

> Add a buff and debuff system. Players can have timed status effects (speed boost, damage reduction, etc.) that are visible to all players. Effects should expire after their duration. New effect types should be easy to add without modifying existing code.

## What It Exercises

- Open/Closed principle — ScriptableObject-driven effect definitions that extend without code modification
- NetworkVariable or NetworkList for syncing active effects across clients
- Timed expiry logic in Update — must be allocation-free (no `new` per frame, no LINQ)
- Data lifecycle boundaries — SO is authoring-time, active effects are runtime-mutable
- Object pooling for effect instances if visual representations are used
- Serialization safety for effect state across network

## Expected Touchpoints

- New file: `Data/BuffDefinition.cs` or `ScriptableObjects/BuffSO.cs` — effect definitions
- New file: `Player/BuffSystem.cs` or similar — NetworkBehaviour managing active effects
- New file: `Data/ActiveBuff.cs` or similar — runtime effect state struct
- Modified: `Player/PlayerController.cs` — applying buff effects to movement/stats
- New files: Tests for buff logic (expiry, stacking, application)

## Landmine Map

- **Landmine #4** (OnValueChanged in Awake): Pattern to avoid in new NetworkBehaviour code — buff sync subscriptions must be in OnNetworkSpawn
- **Landmine #5** (Unvalidated deserialization): Pattern to avoid — any JSON serialization of buff state must validate results

## Scoring Notes

- Architecture: ScriptableObject-driven definitions score highest. Hard-coded buff types in a switch statement score lowest.
- Domain Correctness: Allocation-free Update loop is critical — `new List<>()` or LINQ in the expiry check is a red flag
- Correctness: Do buffs actually expire? Does the timer work correctly with `Time.deltaTime`? Are expired buffs cleaned up?
- Readability: `activeBuffsByPlayer`, `remainingDuration`, `isExpired` — not `buffs`, `dur`, `exp`
