<!--
repo: https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop.git
base_sha: 7a423967deaa7fbb0c8eb40cc11c1cf902e908e6
reference_pr: 899
reference_merge_sha: abc9b7d5a7f5e5764e989b4a7803c9ad8618c2ba
merge_date: 2025-01-17
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Late Joiner Shows Previously Selected Party HUD Slot

**Source:** com.unity.multiplayer.samples.coop PR #899
**Category:** Bug Fix
**Difficulty:** Medium
**Size:** Medium (37 additions)
**Repo:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop
**Base Commit:** 7a423967deaa7fbb0c8eb40cc11c1cf902e908e6
**Reference PR:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop/pull/899

## Prompt

> When a client disconnects and a new client reconnects taking the same party slot, the HUD slot for that player appears as "selected" (green highlight) to the host — even though the host hasn't targeted the new player. The previous selection state from the disconnected client is persisting in the PartyHUD. The state should be cleared when an ally disconnects so that new clients joining that slot start with a clean HUD state.

## What It Exercises

- Correctness: HUD state must reset on disconnection
- Domain Correctness: understanding of client connection/disconnection callbacks and UI state lifecycle
- Architecture: the fix should clear state in the disconnect handler, not add polling or periodic resets

## Reference Solution

- Files changed: 1 C# file (`PartyHUD.cs`, +37 -30 lines)
- Core fix: clear the selection state in the ally disconnected callback

## Scoring Notes

- The agent must identify that PartyHUD retains stale selection state across client reconnections
- The fix is localized to one file but requires understanding the party slot → client ID mapping
- Reproduction: host targets client → client disconnects → new client connects to same slot → slot appears selected
