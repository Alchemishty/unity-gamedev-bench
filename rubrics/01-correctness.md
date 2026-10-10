# Rubric 1: Correctness

**Type:** Universal
**Scale:** 0-10

Does the code do what the task asked? No runtime errors, no logic bugs, edge cases handled.

## Scoring Criteria

| Score | Criteria |
|---|---|
| 0-2 | Code doesn't compile, or has fundamental logic errors that prevent the feature from working at all. |
| 3-4 | Compiles but has runtime bugs or misses core requirements stated in the task prompt. |
| 5-6 | Core functionality works, but edge cases cause failures (boundary values, empty inputs, concurrent access). |
| 7-8 | All requirements met, edge cases handled, no runtime errors under normal operation. |
| 9-10 | All requirements met, edge cases handled, and interaction with existing code is correct — no regressions, existing tests still pass, no breakage of pre-existing features. |

## What to Check

- Does the output satisfy every requirement in the task prompt?
- Does the code compile without errors?
- Are edge cases handled (null inputs, empty collections, boundary values, overflow)?
- Does the new code interact correctly with pre-existing scripts?
- Are there logic bugs (off-by-one, wrong condition, missing break, race condition)?
- For multiplayer tasks: does the sync mechanism actually work for all clients?

## Scoring Notes

- A 10 does not require perfection in style or architecture — only in function.
- Partial credit: if 3 of 4 requirements are met, score in the 6-8 range depending on how critical the missing requirement is.
- Compilation errors that would be trivially fixable (missing using statement) dock 1-2 points, not 8.
