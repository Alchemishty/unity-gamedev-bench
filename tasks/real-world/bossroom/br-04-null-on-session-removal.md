<!--
repo: https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop.git
base_sha: 911643faa6c5ecd00f69460d7ca2210dff24ec15
reference_pr: 905
reference_merge_sha: a7dab563e088f70597cd3c6f92b1c7b96cac2162
merge_date: 2025-04-02
rubrics: correctness,robustness,readability,domain_correctness
-->
# Task: NullReferenceException on Session Removal

**Source:** com.unity.multiplayer.samples.coop PR #905
**Category:** Bug Fix
**Difficulty:** Easy
**Size:** Trivial (5 lines changed)
**Repo:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop
**Base Commit:** 911643faa6c5ecd00f69460d7ca2210dff24ec15
**Reference PR:** https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop/pull/905

## Prompt

> A NullReferenceException is logged when a client is removed from a multiplayer session. The error occurs during the unsubscription from session events in `MultiplayerServicesFacade`. The facade is trying to unsubscribe from an event on an object that has already been disposed.

## Prompt Variant: Diagnostic

> Players occasionally see a NullReferenceException in the console when disconnecting from a multiplayer session. The error is in `MultiplayerServicesFacade` but doesn't crash the game — it just logs the error. Happens more often when the session ends abruptly rather than through a clean disconnect.

## What It Exercises

- Correctness: session removal should complete cleanly without errors
- Robustness: unsubscription must handle the case where the source object is already null/disposed
- Domain Correctness: understanding of session lifecycle and cleanup ordering

## Reference Solution

- Files changed: 1 C# file (+5 -4 lines)
- Core fix: null-check the event source before unsubscribing

## Rubric Applicability

- Architecture: N/A (small targeted null guard)

## Scoring Notes

- This is a small, focused fix — tests whether the agent can identify and fix a null-on-cleanup pattern quickly
- The fix is 5 lines — the agent should not over-engineer this
- The agent should add a null check, not restructure the cleanup flow
