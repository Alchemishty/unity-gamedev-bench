<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: ee3bf25a8de9be96c328112a9226d911c5bc8575
reference_pr: 4045
reference_merge_sha: 66ce4f7b73eca81ebebf5de1d9c269e42e2b50bb
merge_date: 2025-08-02
rubrics: correctness,robustness,readability,architecture,domain_correctness
-->
# Task: Add NetworkName Component

**Source:** MirrorNetworking/Mirror PR #4045
**Category:** Feature
**Difficulty:** Easy
**Size:** Small (30 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** ee3bf25a8de9be96c328112a9226d911c5bc8575
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4045

## Prompt

> Add a `NetworkName` component that syncs a GameObject's name across the network. When the server changes an object's name, all clients should see the updated name. This is useful for debugging (seeing meaningful names in the hierarchy on clients instead of "Player(Clone)") and for display purposes. The component should use Mirror's SyncVar system and update the GameObject name whenever the synced value changes.

## What It Exercises

- Domain Correctness (SyncVar usage, hook pattern)
- Architecture (single-responsibility component, minimal footprint)
- Readability (clean, focused implementation)

## Reference Solution

1 file changed (plus .meta), 30 additions. A single focused component.

## Rubric Applicability

- Test Quality: N/A (feature task adding a simple display component)

## Scoring Notes

- This should be a very small, focused component — overengineering (adding UI, events, configuration) is wrong
- Must use SyncVar with a hook to update the GameObject name on change
- Should work for both initial spawn and runtime name changes
- The component should have no dependencies beyond Mirror's core
