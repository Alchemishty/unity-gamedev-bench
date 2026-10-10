<!--
repo: https://github.com/Alchemishty/ugb-starter.git
base_sha: c74a25490ef57dab555cea586a301202c93a7a93
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task 3: Fix Silent Rendering Bug

**Category:** Bug Fix
**Difficulty:** Medium

## Prompt

> Players report their avatar sometimes doesn't render items after joining a match. The bug is intermittent — it happens more often when joining late. The game doesn't crash, items just don't appear.

## What It Exercises

- Diagnosing a Netcode lifecycle bug from a symptom description
- Understanding OnValueChanged behavior — it does NOT fire for the initial value
- Knowing the correct fix: move subscription to OnNetworkSpawn, read initial value explicitly
- Proper base method calls (base.OnNetworkSpawn, base.OnNetworkDespawn)
- Event cleanup — matching subscribe/unsubscribe lifecycle pairs

## Expected Touchpoints

- Modified: `Player/PlayerController.cs` — move subscription from Awake to OnNetworkSpawn, add initial value read, move unsubscribe from OnDestroy to OnNetworkDespawn

## Landmine Map

- **Landmine #4** (OnValueChanged in Awake): This IS the root cause. The subscription is in Awake instead of OnNetworkSpawn, causing late joiners to miss the initial value.
- **Landmine #1** (ItemRegistry silent null return): Secondary — may compound the issue if the agent investigates the full render path and encounters the silent null.

## Scoring Notes

- Correctness: All three aspects must be fixed: (1) move subscription to OnNetworkSpawn, (2) read initial value explicitly, (3) move unsubscribe to OnNetworkDespawn
- Domain Correctness: `base.OnNetworkSpawn()` must be called before subscription. `base.OnNetworkDespawn()` must be called after unsubscription. Omitting these is a Netcode lifecycle violation.
- Robustness: Unconditional initial value read (handles all cases) scores higher than conditional read (fragile, misses edge cases like owner reconnection)
- Architecture: Targeted fix scores higher than over-scoping. The task is a bug fix, not a refactor.
