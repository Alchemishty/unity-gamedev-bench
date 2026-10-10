<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: e5f664d7131dad88742e65139f66da4d8bf6a181
reference_pr: 4048
reference_merge_sha: b980ea4a62a8ee7b51de96e455df207b32b876c8
merge_date: 2025-08-05
difficulty: hard
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Commands Not Immediately Invoked in Host Mode

**Source:** MirrorNetworking/Mirror PR #4048
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Medium (91 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** e5f664d7131dad88742e65139f66da4d8bf6a181
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4048

## Prompt

> In host mode, `[Command]` methods are not invoked immediately — they go through the full serialize-deserialize-queue-process pipeline like a real network call. This causes race conditions and edge cases where code after a Command call doesn't see the Command's effects yet, even though both client and server are in the same process. For example, calling a Command that modifies a SyncVar and then immediately reading that SyncVar sees the old value. On a pure server, Commands would be processed before the next line of client code runs. Host mode should behave the same way for consistency.

## What It Exercises

- Domain Correctness (host mode optimization, Command execution path)
- Architecture (weaver-level changes, understanding IL post-processing)
- Correctness (ensuring immediate invocation doesn't break authority checks)
- Test Quality (testing timing-dependent behavior)

## Reference Solution

4 files changed, 91 additions, 9 deletions. Key changes:
- CommandProcessor (weaver): Direct invocation path for host mode
- Added NetworkConnectionToClient population for host commands
- Tests for immediate invocation and race condition prevention

## Scoring Notes

- This is a weaver (IL post-processing) change — the agent needs to understand Mirror's code generation pipeline
- The fix must preserve all existing Command validation (authority checks, channel selection)
- The NetworkConnectionToClient parameter must be correctly populated for host-mode commands
- Testing must verify that a Command's effects are visible immediately after the call in host mode
