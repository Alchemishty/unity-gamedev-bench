# Task: NetworkList Changes Applied Twice on Newly Synchronized Client

**Source:** com.unity.netcode.gameobjects Issue #4179
**Category:** Bug Fix
**Difficulty:** Hard
**Repo:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects
**Base Commit:** N/A (open issue, no merged fix yet)
**Reference PR:** None — open issue

## Prompt

> When a client connects while a `NetworkList<T>` on an already-spawned object still has unsent changes from the current tick, that client applies those changes twice: once from the synchronization snapshot and again from the next tick's delta. Since Add, Insert, Remove, RemoveAt, and Clear aren't idempotent, the client's list ends up with duplicate entries, and every subsequent index-based event fires with the wrong element on that client. Clients that were already connected are unaffected. This only happens when changes are made between a client's synchronization and the next network tick.

## What It Exercises

- Correctness: the fix must prevent double-application without losing the changes
- Domain Correctness: understanding of NetworkList's synchronization model (snapshot + delta), tick boundaries, and the distinction between initial sync and ongoing deltas
- Architecture: the fix should be at the synchronization boundary, not in every list operation
- Test Quality: test must simulate the exact timing — changes made between client connect and next tick

## Scoring Notes

- This is an open issue with no reference solution — the agent must design the fix
- The root cause is that the snapshot includes the pending changes AND the delta also includes them
- A correct fix either marks changes as already included in the snapshot or skips the delta for the first tick
- This exercises deep understanding of Netcode's variable synchronization pipeline
