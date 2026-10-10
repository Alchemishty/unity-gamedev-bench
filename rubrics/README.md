# Rubrics

7 rubrics for scoring AI coding agent output. Each output is scored independently against these rubrics on a 0-10 scale (except Rubric 7, which records objective metrics).

## Rubric Index

| # | Rubric | Type | Swappable? |
|---|---|---|---|
| 1 | [Correctness](01-correctness.md) | Universal | No |
| 2 | [Robustness](02-robustness.md) | Universal | No |
| 3 | [Readability](03-readability.md) | Universal | No |
| 4 | [Architecture](04-architecture.md) | Universal | No |
| 5 | [Domain Correctness](05-domain-correctness.md) | Domain-specific | Yes |
| 6 | [Test Quality](06-test-quality.md) | Universal | No |
| 7 | [Efficiency](07-efficiency.md) | Objective metrics | No |

## Universal vs Domain-Specific

**Rubrics 1-4 and 6 are universal.** They apply to any codebase in any language. A Python web API and a Unity multiplayer game are both scored on correctness, robustness, readability, architecture, and test quality with the same criteria.

**Rubric 5 is domain-specific.** The default module evaluates Unity/Netcode knowledge. To benchmark agents on a different domain, replace `05-domain-correctness.md` with your own:

- **Web backend:** Replace Netcode lifecycle rules with HTTP/REST patterns, ORM usage, middleware ordering, SQL injection prevention.
- **Frontend/React:** Replace with component lifecycle, hook rules, rendering performance, accessibility.
- **Embedded/systems:** Replace with memory management, interrupt safety, hardware abstraction.
- **Other game engines (Unreal, Godot):** Replace with that engine's lifecycle, networking, and performance patterns.

The rubric file format stays the same — a 0-10 scale with criteria at each level and a domain-specific checklist.

## Scoring Rules

- Score each output independently before comparing.
- Every score must reference specific code (variable names, patterns, line numbers from the diff).
- "The naming is good" is insufficient. "All variables use full descriptive names (e.g., `equippedItemIds` instead of `eqIds`)" is correct.
- A violation must be observable in the diff, not assumed from context.

## Maximum Scores

Per task: up to 60 points (6 rubrics × 10 each), but not all rubrics apply to every task. Rubric 7 is recorded separately as raw counts.

Per benchmark run (39 scored tasks): the maximum depends on rubric applicability per task. The score is always reported as a percentage of applicable points.
