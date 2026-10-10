# Benchmark Results: [Run Name]

**Date:** YYYY-MM-DD
**Agent:** [e.g., Claude Code, Aider, Cursor, custom]
**Configuration:** [e.g., bare minimum, with harness, custom prompt]
**Tasks run:** [list task IDs, e.g., s01-s07 for synthetic, m01-m04 m06-m13 for Mirror, all for full]
**Scorer:** [AI model / human / both]

## Overall Score

```
unity-gamedev-bench score: XX% (XXX/YYY)
```

YYY = sum of applicable rubric slots × 10 across all scored tasks.

## Per-Rubric Averages

Averaged across tasks where the rubric was applicable (not N/A).

| Rubric | Average (out of 10) | Tasks Scored |
|---|---|---|
| Correctness | X.X | N |
| Robustness | X.X | N |
| Readability | X.X | N |
| Architecture | X.X | N |
| Domain Correctness | X.X | N |
| Test Quality | X.X | N |

**Weakest rubric:** [name] — [brief explanation]

## Per-Source Scores

| Source | Tasks | Score | Percentage |
|---|---|---|---|
| Synthetic | s01-s07 | XXX/YYY | XX% |
| Mirror | m01-m04, m06-m13 | XXX/YYY | XX% |
| NGO | n01-n05 | XXX/YYY | XX% |
| Boss Room | b01-b07 | XXX/YYY | XX% |

## Per-Task Breakdown

### Task [ID]: [Task Name]

| Rubric | Score | Justification |
|---|---|---|
| Correctness | /10 | [one sentence with specific code reference] |
| Robustness | /10 | [one sentence] |
| Readability | /10 | [one sentence] |
| Architecture | /10 or N/A | [one sentence] |
| Domain Correctness | /10 or N/A | [one sentence] |
| Test Quality | /10 or N/A | [one sentence] |
| **Task Total** | **/YY** | YY = applicable rubric slots × 10 |

**Violations found:** [list with file references]

**Efficiency metrics:**
- User corrections: X
- Compilation errors: X
- Self-fix rate: X%
- Test failures: X

---

*(Repeat for each task)*

---

## Key Findings

1. **Strongest area:**
2. **Weakest area:**
3. **Notable patterns:**

## Improvement Opportunities

Based on the scores, these changes would have the highest impact:
1. [specific recommendation tied to weakest rubric]
2. [specific recommendation tied to weakest source]
3. [specific recommendation tied to a recurring violation]
