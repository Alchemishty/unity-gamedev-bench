# Domain Correctness (0–10)

Correct lifecycle, framework, serialization, threading, networking, and performance behavior relevant to this task.

| Score | Observable Evidence |
|---|---|
| 0 | Fundamental framework misunderstandings. Violates core lifecycle contracts. |
| 2 | Basic lifecycle present but critical mistakes in framework-specific patterns. |
| 4 | Lifecycle ordering correct but misses important framework conventions or edge cases. |
| 6 | Framework rules followed. Minor domain edge cases missed. |
| 8 | All framework rules followed. Serialization validated. Performance patterns respected. Event lifecycle correctly paired. |
| 10 | Framework lifecycle, ownership, event cleanup, serialization, and performance patterns all handled correctly for the specific framework in use. |

Note: framework-specific expectations (Unity Netcode, Mirror SyncVars, etc.) are specified in each task's scorer notes, not in this rubric.
