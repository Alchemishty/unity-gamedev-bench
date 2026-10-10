# Robustness (0–10)

How does the code handle unexpected state?

| Score | Observable Evidence |
|---|---|
| 0 | No defensive programming. Null dereferences, unvalidated inputs throughout. |
| 2 | Some null checks exist but inconsistent. Mix of throws and silent consumption. |
| 4 | Error paths exist but messages are generic or missing context. Some silent null returns remain. |
| 6 | Most error paths handled with context messages. Inputs validated at public boundaries. |
| 8 | Consistent defensive programming. Nulls throw with context identifying what's missing and where. Inputs validated. Deserialization checked. |
| 10 | Every failure mode is explicit. Throw messages identify the missing value and the call site. Optional vs required null paths are deliberate and distinguishable. |
