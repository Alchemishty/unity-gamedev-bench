<!--
repo: https://github.com/Unity-Technologies/com.unity.netcode.gameobjects.git
base_sha: 2ea75a36bf498658b2c95dc469307af1182b6880
reference_pr: 4133
reference_merge_sha: 57f2ff63a3239963a833af75b0a1ff42e7740772
merge_date: 2026-08-28
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: NetworkTransform Interpolation Render Time

**Source:** com.unity.netcode.gameobjects PR #4133
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Large (257 additions)
**Repo:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects
**Base Commit:** 2ea75a36bf498658b2c95dc469307af1182b6880
**Reference PR:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects/pull/4133

## Prompt

> Clients see jittery or snapping NetworkTransform movement, especially under variable network conditions. Investigation reveals the interpolation buffer is using an incorrect render time — it's derived from `LocalTime` minus tick latency, which puts it at approximately `ServerTime` instead of a buffer behind it. This means the interpolator often runs out of buffered states and snaps to the latest value.

## Prompt Variant: Diagnostic

> Clients see jittery and snapping movement on networked objects, especially when network latency varies. Objects teleport to new positions instead of smoothly interpolating. The problem is worse under packet loss but still visible on stable connections. The interpolation system appears to be running out of buffered states.

## What It Exercises

- Correctness: fixing the render-time derivation so the interpolation buffer has enough headroom
- Domain Correctness: understanding of Netcode's `LocalTime`, `ServerTime`, tick latency, and the relationship between them
- Architecture: surgical fix to the time calculation, not a restructure of the interpolation system
- Test Quality: runtime test verifying interpolation doesn't snap under normal tick latency

## Reference Solution

- Files changed: `NetworkTransform.cs`, `NetworkTransformInterpolationRenderTimeTests.cs`, `NetworkTransformTickLatencyTests.cs`
- +257 -9 lines
- Core fix: render time now derived from `ServerTime` minus a jitter buffer, not `LocalTime` minus tick latency

## Scoring Notes

- This is a deep networking timing bug — the agent needs to understand the Netcode timing model
- A surface-level fix (increasing buffer size) would mask the symptom; the correct fix changes the time derivation
- Test should verify smooth interpolation across varying latencies
