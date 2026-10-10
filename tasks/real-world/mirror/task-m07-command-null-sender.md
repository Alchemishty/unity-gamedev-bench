<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 97cd4704f01f8af0a217098ac499afe5985c5b7b
reference_pr: 4072
reference_merge_sha: 8e2a331ecededc146939bff3277fbb26282058aa
merge_date: 2026-01-08
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Host Command Has Null Sender Connection for Server-Owned Objects

**Source:** MirrorNetworking/Mirror PR #4072
**Category:** Bug Fix
**Difficulty:** Medium
**Size:** Small (34 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** 97cd4704f01f8af0a217098ac499afe5985c5b7b
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4072

## Prompt

> When calling a `[Command]` on a server-owned object from the host, the `NetworkConnectionToClient sender` parameter is null. This crashes any command handler that accesses `sender` properties. The bug only occurs in host mode when the server owns the object — commands on player-owned objects work fine because `connectionToClient` is set. A previous fix (PR #4063) partially addressed this for player-owned objects but missed the server-owned case.

## Prompt Variant: Diagnostic

> Commands on certain NetworkBehaviours crash with NullReferenceException in host mode. The `sender` parameter in the command handler is null. It doesn't happen for all objects — only some. Player-owned objects work fine. The crash started appearing after a recent command routing fix.

## What It Exercises

- Correctness (handling the server-owned edge case in host mode)
- Domain Correctness (understanding Command routing, connectionToClient vs localConnection)
- Test Quality (testing the specific edge case that was missed)
- Robustness (not leaving null sender for valid command calls)

## Reference Solution

3 files changed, 34 additions, 7 deletions. Key changes:
- CommandProcessor: Use NetworkServer.localConnection instead of this.connectionToClient for host-mode commands
- Added test verifying non-null sender for server-owned host commands

## Scoring Notes

- The fix should use `NetworkServer.localConnection` as the sender fallback in host mode, not add a null check to every command handler
- The agent should recognize this is a weaver-level fix (IL post-processing), not a runtime fix
- Test must specifically verify the server-owned-object + host-mode scenario
