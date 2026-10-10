<!--
repo: https://github.com/wave-harmonic/crest.git
base_sha: 33918b9a6c65c73cf5f95e6f6a703a98f7d92669
reference_pr: 1157
reference_merge_sha: babcc81603372bc1668ee87705d8dd07274da91e
merge_date: 2025-04-03
rubrics: correctness,robustness,readability,architecture,domain_correctness
-->

# Task: Foam Breaks with Negative Floating Origin

**Source:** wave-harmonic/crest PR #1157
**Category:** Bug Fix
**Difficulty:** Hard
**Size:** Medium (63 additions across 14 files)
**Repo:** https://github.com/wave-harmonic/crest
**Base Commit:** 33918b9a6c65c73cf5f95e6f6a703a98f7d92669
**Reference PR:** https://github.com/wave-harmonic/crest/pull/1157

## Prompt

> In Crest ocean system, foam appears constantly and incorrectly when the ocean GameObject's Y position is a large negative value (below -1000). The same scene works correctly when the ocean is at Y=0 or positive values. This breaks any setup using floating origin with a significant downward offset. Steps to reproduce: open the BoatWakes scene, lower the Ocean GameObject to (0, -1000, 0), observe that foam covers the entire surface.

## Prompt Variant: Diagnostic

> Ocean foam rendering is broken when the ocean is positioned at large negative Y values. Foam appears everywhere instead of only where waves break. Positive Y values work correctly. The issue is visible in the BoatWakes sample scene.

## What It Exercises

- Correctness (coordinate space handling in shaders and C#)
- Domain Correctness (shader/HLSL code, render pipeline, floating-point precision at extreme values)
- Architecture (consistent depth/height representation across C# and shader code)
- Readability (clear variable naming in shader code)

## Reference Solution

14 files changed, 63 additions, 36 deletions. The fix changes depth representation to use infinity-based water depth encoding that is independent of world-space Y position, affecting both C# scripts and HLSL shaders.

## Scoring Notes

This is a cross-language task (C# + HLSL). The agent must understand floating-point precision issues at extreme coordinates, the relationship between sea floor depth encoding and foam generation, and how to make a consistent fix across both C# configuration code and shader computations. Test Quality is N/A — shader behavior is not unit-testable in the traditional sense.
