<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 987acda6bce3816cb209e704c2a2caaad41fe389
reference_pr: 4053
reference_merge_sha: 1b165d56c0724b8ea8e2cd104eced78c373ff037
merge_date: 2025-09-09
rubrics: correctness,robustness,readability,domain_correctness
-->
# Task: NetworkAnimator SetTrigger Double-Fires on Host

**Source:** MirrorNetworking/Mirror PR #4053
**Category:** Bug Fix
**Difficulty:** Easy
**Size:** Trivial (10 lines changed)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** 987acda6bce3816cb209e704c2a2caaad41fe389
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4053

## Prompt

> When using `NetworkAnimator.SetTrigger()` in host mode, animation triggers fire twice — once locally and once from the network broadcast. This causes animations to stutter or play double on the host player. The issue doesn't happen on pure clients. The `ClientRpc` that broadcasts the trigger is being sent back to the originating host client, and the host also runs it locally, resulting in a duplicate.

## What It Exercises

- Domain Correctness (host mode behavior, ClientRpc routing)
- Correctness (preventing double execution in host mode)

## Reference Solution

1 file changed, 10 additions, 8 deletions. Key changes:
- Removed `includeOwner = false` from ClientRpc attributes
- Added isServer + authority check to prevent double trigger

## Rubric Applicability

- Architecture: N/A (trivial attribute parameter change)
- Test Quality: N/A (one-line fix)

## Scoring Notes

- The fix involves understanding ClientRpc routing in host mode — `includeOwner = false` was the wrong approach
- The correct solution ensures the host doesn't apply the trigger twice while still broadcasting to other clients
- This is a small, focused fix — overengineering it (e.g., adding queuing or deduplication) is wrong
