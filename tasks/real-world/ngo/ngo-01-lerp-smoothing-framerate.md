<!--
repo: https://github.com/Unity-Technologies/com.unity.netcode.gameobjects.git
base_sha: 11f577642353d64dfc5c1345e3a245fcc85e565a
reference_pr: 4130
reference_merge_sha: 2ea75a36bf498658b2c95dc469307af1182b6880
merge_date: 2026-08-27
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task: Lerp Smoothing Frame Rate Dependence

**Source:** com.unity.netcode.gameobjects PR #4130
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Large (153 additions)
**Repo:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects
**Base Commit:** 11f577642353d64dfc5c1345e3a245fcc85e565a
**Reference PR:** https://github.com/Unity-Technologies/com.unity.netcode.gameobjects/pull/4130

## Prompt

> The `Lerp` and `SmoothDampening` interpolation modes on `NetworkTransform` produce visibly different smoothing depending on the client's frame rate. At 30fps the transitions look sluggish, at 120fps they're almost instant. Additionally, when the interpolation time reaches its maximum the transform freezes instead of converging smoothly. Find and fix the frame rate dependency and the freeze at maximum interpolation time.

## Prompt Variant: Diagnostic

> NetworkTransform movement looks noticeably different on machines with different frame rates. Low-FPS clients see sluggish, delayed movement. High-FPS clients see snappy, almost instant transitions. Both are using the same Lerp interpolation mode. Additionally, objects sometimes freeze mid-transition and stop moving entirely until a new network update arrives.

## What It Exercises

- Correctness: mathematical fix for time-dependent lerp factor
- Domain Correctness: understanding of `BufferedLinearInterpolator`, `NetworkTransform` interpolation pipeline, Unity's `Time.deltaTime`
- Architecture: fix should be contained to the interpolation code, not leak into transport or state management
- Test Quality: editor test for interpolation behavior across simulated frame rates

## Reference Solution

- Files changed: `BufferedLinearInterpolator.cs`, `NetworkTransform.cs`, `InterpolatorTests.cs`
- +153 -10 lines
- Core fix: smoothing factor raised to `deltaTime * referenceFps` power instead of applied once per frame

## Scoring Notes

- The agent must identify that the smoothing factor is applied per-frame without delta-time scaling
- The freeze at max interpolation is a separate but related issue — both should be fixed
- A correct fix must make the wall-clock smoothing rate independent of frame rate
