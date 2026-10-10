<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 3a6945f2270afe310ef3e99b7c034907f633bfca
reference_pr: 4082
reference_merge_sha: caaf7e1bc19763326c82ad70472423388d86033a
merge_date: 2026-01-12
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: ThreadLog Capturing Logs From All Threads Instead of Mirror Threads

**Source:** MirrorNetworking/Mirror PR #4082
**Category:** Bug Fix
**Difficulty:** Medium
**Size:** Medium (98 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** 3a6945f2270afe310ef3e99b7c034907f633bfca
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4082

## Prompt

> The `ThreadLog` class captures ALL log messages from ANY thread via `Application.logMessageReceivedThreaded`, including logs from user application code that have nothing to do with Mirror. This causes user debug/error messages to appear with "Mirror" at the bottom of their stack trace, which is confusing and misleading. ThreadLog should only capture logs originating from threads that Mirror manages, not from arbitrary application threads.

## What It Exercises

- Architecture (thread identification, filtering at the right layer)
- Correctness (only capturing Mirror-managed thread logs)
- Test Quality (testing thread registration/unregistration, concurrent access)
- Robustness (thread-safe data structures, cleanup on thread exit)

## Reference Solution

4 files changed, 98 additions. Key changes:
- ThreadLog: Added ConcurrentDictionary for tracking Mirror thread IDs
- WorkerThread: Register/unregister thread ID on start/stop
- OnLog: Filter by checking if current thread ID is in the Mirror threads set
- Tests for registration, unregistration, and filtering

## Scoring Notes

- Must use thread-safe data structure (ConcurrentDictionary or similar) — not a plain Dictionary
- Registration must happen in the worker thread itself (not the caller), since that's where the thread ID is valid
- Unregistration must happen even if the thread throws (cleanup in finally or equivalent)
- Tests should verify filtering actually works — non-Mirror thread logs are ignored
