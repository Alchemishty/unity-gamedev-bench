<!--
repo: https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop.git
base_sha: 9a1ca643590caab854af6d9fa6dcd26520efbbe1
reference_pr: 893
reference_merge_sha: 31c3c3f34d0babe3b62a35d5430438c5e61dee60
merge_date: 2024-12-12
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Healer Ability Doesn't Work

**Source:** com.unity.multiplayer.samples.coop PR #893
**Category:** Bug Fix (Compound)
**Difficulty:** Medium
**Size:** Large (98 additions across 8 files)
**Repo:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop
**Base Commit:** 9a1ca643590caab854af6d9fa6dcd26520efbbe1
**Reference PR:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop/pull/893

## Prompt

> The Healer character class's healing ability doesn't work. When the Healer uses their ability, nothing happens — no healing is applied to the target. Additionally, there's a secondary bug: when a skill is triggered and the target is at almost the same position as the character, the character's orientation flips unexpectedly. The healing action system needs to be debugged and fixed, and the orientation issue needs to be addressed in the input handling.

## What It Exercises

- Correctness: healing must actually apply to the target
- Architecture: the fix spans input handling, action system, damage/heal pipeline, and character targeting (8 C# files)
- Domain Correctness: understanding of the action system, IDamageable interface, and server-authoritative ability execution
- Robustness: edge case handling for same-position targeting

## Reference Solution

- Files changed: 8 C# files (+98 -19 lines)
- Three distinct fixes: (1) healing action targeting logic, (2) character orientation when target ≈ current position, (3) IDamageable interface updates for heal support

## Scoring Notes

This task bundles three related fixes (healing logic, orientation check, interface implementation). The agent must identify all three issues from the single symptom description. Partial fixes score partial credit on Correctness.

- The agent must identify multiple root causes (healing targeting + orientation flip)
- The fix touches the action system broadly — MeleeAction, DashAttackAction, Breakable, ServerCharacter, DamageReceiver, IDamageable, ClientInputSender, ActionUtils
- A partial fix (only healing, not orientation) should score lower on correctness
