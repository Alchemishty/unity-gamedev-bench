# Correctness (0–10)

Does the code do what the task asked?

| Score | Observable Evidence |
|---|---|
| 0 | No meaningful implementation. Empty diff or completely wrong approach. |
| 2 | Attempts the task but does not compile, or compiles with fundamental logic errors that prevent any functionality. |
| 4 | Partially implements the requested behavior. Main path may work but core requirements are missing. |
| 6 | Main path works correctly. Important edge cases or secondary requirements are missing. |
| 8 | Complete implementation. All stated requirements met with minor defects (trivial edge cases, cosmetic issues). |
| 10 | Complete, correct, regression-free. All requirements, edge cases, and interaction with existing code handled. |

Verification override:
- Compile failure with C# diagnostics → cap at 2.
- Test regression (new failures vs baseline) → cap at 4.
