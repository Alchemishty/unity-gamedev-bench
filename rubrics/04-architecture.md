# Architecture (0–10)

Structural quality appropriate to the scope of the change.

| Score | Observable Evidence |
|---|---|
| 0 | Everything in one class or method. No separation of concerns. |
| 2 | Some separation attempted but responsibilities bleed across classes. |
| 4 | Identifiable structure but shortcuts and wrong-direction dependencies. |
| 6 | Single responsibility mostly followed. Boundaries exist with minor violations. |
| 8 | Clean separation appropriate for the size of the change. Each unit has one reason to change. Dependencies point in the right direction. No over-engineering. |
| 10 | Correct structure for the scope and conventions of the existing codebase. Extends without modifying existing abstractions. No unnecessary layers or interfaces. |
