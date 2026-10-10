# Rubric 4: Architecture

**Type:** Universal
**Scale:** 0-10

Structural quality: separation of concerns, dependency direction, appropriate pattern usage.

## Scoring Criteria

| Score | Criteria |
|---|---|
| 0-2 | God classes. Everything in one file/layer. Tight coupling everywhere. |
| 3-4 | Some separation but responsibilities bleed across classes. Dependencies point in mixed directions. |
| 5-6 | Single responsibility mostly followed. Layer boundaries exist but have shortcuts. |
| 7-8 | Clean separation. Each class has one reason to change. Dependencies point downward (toward data/abstractions). Appropriate patterns used without over-engineering. |
| 9-10 | New code lands in the correct layer. Interfaces used for cross-layer communication. Open for extension without modification. No unnecessary abstractions. |

## What to Check

- **Single Responsibility:** Does each class have one reason to change? A class handling UI rendering, API calls, and business logic in one file scores low.
- **Dependency Direction:** Do dependencies point toward stable abstractions? UI depending on Data is correct. Data depending on UI is a violation.
- **Pattern Appropriateness:** Are patterns used because they solve a real problem, or because the agent defaulted to them? Over-engineering (factory for a class with one implementation) scores lower than appropriate simplicity.
- **Layer Placement:** Does new code land in the correct layer? In the starter project: Data → API → Registry → Player → UI.
- **Interface Segregation:** Small focused interfaces (`IEquippable`, `IPurchasable`) over wide base classes.

## The Starter Project's Layers

```
Data → API → Registry → Player → UI
```

Import direction: left-to-right only. Lower layers must not reference higher layers. New code should respect this structure.

## Scoring Notes

- A refactor task that splits a god class into focused responsibilities should score significantly higher than one that merely renames variables within the same structure.
- Over-engineering (unnecessary abstractions, premature patterns) docks 1-2 points even if the structure is technically clean.
- Architecture is about the structure the agent chose, not about what existed before.
