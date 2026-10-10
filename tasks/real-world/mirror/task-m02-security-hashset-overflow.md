<!--
repo: https://github.com/MirrorNetworking/Mirror.git
base_sha: 503a1b5e4b50a5d1257a6d39afc7862d194e449e
reference_pr: 4115
reference_merge_sha: 66347349d7a368b15e746220d508667db709ceda
merge_date: 2026-06-27
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Security — ReadHashSet Allocation Attack and Unbatcher Overflow

**Source:** MirrorNetworking/Mirror PR #4115
**Category:** Security
**Difficulty:** Medium
**Size:** Medium (66 additions)
**Repo:** https://github.com/MirrorNetworking/Mirror
**Base Commit:** 503a1b5e4b50a5d1257a6d39afc7862d194e449e
**Reference PR:** https://github.com/MirrorNetworking/Mirror/pull/4115

## Prompt

> Security review found two independent vulnerabilities in the networking layer. First, `ReadHashSet` in NetworkReaderExtensions is missing the allocation limit check that `ReadList` and `ReadArray` both have — a malicious peer can send an arbitrarily large length prefix and force unbounded memory allocation on the receiver, causing a denial of service. Second, in the Unbatcher, `DecompressVarUInt` returns a `ulong` but it's directly cast to `int` — values above `int.MaxValue` wrap to negative, which silently passes the `reader.Remaining < size` validation since negative is always less than remaining bytes. A malformed batch can bypass size validation entirely.

## Prompt Variant: Diagnostic

> A fuzzing harness is crashing Mirror clients with out-of-memory exceptions and unexpected batch processing behavior. The crashes happen during network deserialization but only with specially crafted payloads — normal gameplay traffic works fine. Two separate crash types have been reported: one is a memory exhaustion, the other processes batches with impossible sizes.

## What It Exercises

- Robustness (input validation, integer overflow handling)
- Correctness (matching security patterns across similar methods)
- Test Quality (testing boundary conditions, malicious inputs)
- Architecture (consistent defensive patterns across codebase)

## Reference Solution

4 files changed, 66 additions, 1 deletion. Key changes:
- Added AllocationLimit check to ReadHashSet matching ReadList/ReadArray pattern
- Added explicit ulong-to-int overflow guard before cast in Unbatcher
- Added test coverage for both vulnerabilities

## Scoring Notes

- Both bugs must be identified and fixed — partial fix scores lower
- The ReadHashSet fix should follow the exact same pattern as ReadList/ReadArray (consistency matters)
- The overflow fix must use an explicit range check, not just cast — the cast IS the bug
- Tests should verify that malicious inputs are rejected, not just that valid inputs work
