<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 535101b0587dfb767b3fe47a082b7dd11528e99e
reference_pr: 4113
reference_merge_sha: 9491a0cdbf1305be84115713d99d162bda7f605b
merge_date: 2026-06-17
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Malformed Batch Queue Growth Vulnerability

**Source:** MirrorNetworking/Mirror PR #4113
**Category:** Security
**Difficulty:** Hard
**Size:** Large (203 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** 535101b0587dfb767b3fe47a082b7dd11528e99e
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4113

## Prompt

> A connected client can send batches with a valid 8-byte timestamp but a varint message-length prefix that exceeds the remaining bytes. `GetNextMessage()` returns `false` without retiring the batch, leaving it permanently queued. Repeated packets grow `connection.unbatcher` memory indefinitely (~16 KB per frame at default transport limits) without ever triggering a disconnect — even with `exceptionsDisconnect = true`. Separately, truncated varint prefixes (like a lone `0xFF` byte) throw uncaught from `DecompressVarUInt`, also bypassing all disconnect paths. After 24 hours this leaks approximately 7GB of memory on the server.

## What It Exercises

- Robustness (handling malformed network input, preventing resource exhaustion)
- Architecture (proper error propagation, cleanup on failure)
- Test Quality (testing malformed inputs, verifying no resource leaks)
- Correctness (ensuring disconnect happens for malicious/broken clients)

## Reference Solution

4 files changed, 203 additions, 66 deletions. Key changes:
- Unbatcher: Added Clear() method to drain queued batches back to pool
- GetNextMessage: Throws InvalidOperationException after clearing on oversized length
- NetworkServer/NetworkClient: Wrapped batch processing in try-catch, disconnect on exception
- Tests for malformed batches, no-queue-growth, and clear lifecycle

## Scoring Notes

- The fix must both detect the malformed batch AND disconnect the client — just logging is insufficient
- The Clear() method must return batches to the pool (not leak them)
- Both attack vectors must be handled: oversized length prefix AND truncated varint
- Tests should verify that repeated malformed batches don't accumulate memory
