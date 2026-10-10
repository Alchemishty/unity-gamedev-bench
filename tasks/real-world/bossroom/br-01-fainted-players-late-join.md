<!--
repo: https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop.git
base_sha: f27526c2c6ca0a94d0efbb1ff514afcea7904dbe
reference_pr: 925
reference_merge_sha: b3def0249aa485f4a33ee660e3cc6a00954f86fb
merge_date: 2025-10-02
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Fainted Players Not Syncing on Late Join

**Source:** com.unity.multiplayer.samples.coop PR #925
**Category:** Bug Fix (Multi-File)
**Difficulty:** Hard
**Size:** Large (411 additions across 15 files)
**Repo:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop
**Base Commit:** f27526c2c6ca0a94d0efbb1ff514afcea7904dbe
**Reference PR:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop/pull/925

## Prompt

> When a client joins a game in progress, any players who are currently fainted (downed) appear alive to the joining client — they're standing up with idle animations instead of showing the fainted state. The fainted state is tracked on the server and synced via NetworkVariables, but the visual behavior (fainted animation, disabling movement) is not applied on late-joining clients. The root cause appears to be that visual state setup happens at spawn time before all NetworkVariables have been synchronized.

## What It Exercises

- Correctness: late-joining clients must see the correct visual state for all players
- Domain Correctness: understanding of OnNetworkSpawn vs OnNetworkPostSpawn timing, NetworkVariable synchronization order, and animator state management
- Architecture: visual behavior should be deferred to after all network state is synchronized (15 C# files changed in reference)
- Robustness: all possible life states (alive, fainted, dead) must be handled on late join

## Reference Solution

- Files changed: 15 C# files (+411 -229 lines)
- Core fix: defer visual behavior to `OnNetworkPostSpawn` (available in newer NGO), ensuring all NetworkVariables are synced before visual setup
- Involves changes across character, animation, and game state systems

## Scoring Notes

This is a large multi-file change (15 files, 640 lines). Architecture rubric is especially relevant — does the agent organize changes across files coherently?

- This is a large-scope fix — tests the agent's ability to trace a cross-system bug
- The agent must understand the timing difference between OnNetworkSpawn and OnNetworkPostSpawn
- Simply re-reading the NetworkVariable in OnNetworkSpawn is insufficient — the variable may not be synced yet
- The fix touches animation, character state, and server state systems
