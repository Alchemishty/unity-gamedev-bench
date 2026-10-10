# Rubric 7: Efficiency

**Type:** Objective metrics
**Scale:** Raw counts (not scored 0-10)

Measures how efficiently the agent completed the task, not just the quality of the output.

## Metrics

| Metric | How to Measure | Source |
|---|---|---|
| **User corrections** | Count of times the user redirected, corrected, or clarified during the task. | Conversation log |
| **Compilation errors** | Count of compilation errors encountered during development. | Conversation log / console output |
| **Self-fix rate** | Percentage of compilation errors the agent fixed without user help. | `(self-fixed / total errors) × 100` |
| **Test failures** | Count of test failures encountered during development. | Conversation log / test output |
| **Total iterations** | Number of edit-compile-test cycles before task completion. | Conversation log |

## Multi-Step Metrics (Task 7 only)

| Metric | How to Measure |
|---|---|
| **Context retention delta** | Rubric score difference between step 1 and step 3 code. Positive means quality improved; negative means it degraded. |

## Cross-Session Metrics (Task 8 only)

| Metric | How to Measure |
|---|---|
| **Memory application** | Binary: did the agent handle the known pitfall correctly in session 2 without re-encountering the bug? Yes/No. |

## Recording

These metrics are collected from conversation logs, not from the code diff. When running headless (e.g., `claude -p`), the log output serves as the conversation record.

For manual/interactive runs, record:
- Each time you corrected the agent (count as 1 user correction)
- Each compilation error you observed in the output
- Each time the agent re-ran tests after a failure

## Reporting

Report these metrics alongside the 0-10 rubric scores in the results template. They provide context for the quality scores — an agent that scores 8/10 with 0 corrections is more capable than one that scores 8/10 with 5 corrections.
