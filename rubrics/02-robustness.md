# Rubric 2: Robustness

**Type:** Universal
**Scale:** 0-10

How does the code handle unexpected state? Defensive programming, error handling, fail-loud vs fail-silent.

## Scoring Criteria

| Score | Criteria |
|---|---|
| 0-2 | No defensive programming. Null dereferences, unvalidated inputs, silent failures throughout. |
| 3-4 | Some error handling but inconsistent. Mix of explicit throws and silent null consumption. |
| 5-6 | Most error paths handled, but a few silent null consumptions or unvalidated inputs remain. |
| 7-8 | Consistent defensive programming. Nulls throw with context messages. Inputs validated at boundaries. Deserialization checked. |
| 9-10 | Every failure mode is explicit. Throw messages identify what's missing and where. Optional vs required null paths are deliberate and distinguishable. |

## The Null Decision Rule

The core question for every null check: **"If this value is null, is the system broken, or is this just one valid path?"**

- System is broken → **throw** with a message identifying what's missing
- Absence is a valid, expected state → **guard** with early return or TryGet
- Unsure → **throw** (it's easier to relax a throw into a guard than to debug silent null propagation)

## What Scores Low

```csharp
// Silent null consumption — the system needs this to work but fails silently
var registry = AccessoryRegistry.Instance;
if (registry == null) return;

// Unvalidated deserialization — null propagates downstream
var data = JsonConvert.DeserializeObject<Response>(json);
data.Items.ForEach(...); // NullReferenceException far from the source
```

## What Scores High

```csharp
// Explicit failure with context
var registry = AccessoryRegistry.Instance
    ?? throw new InvalidOperationException(
        "AccessoryRegistry singleton not initialized. Check bootstrap ordering.");

// Validated deserialization
var data = JsonConvert.DeserializeObject<Response>(json)
    ?? throw new InvalidOperationException(
        $"Failed to deserialize Response from: {json[..Math.Min(json.Length, 100)]}");
```

## Violations to Flag

- `if (x == null) return;` where x being null means the system is broken
- `?.` null-conditional on required values (hides the failure point)
- Unvalidated `DeserializeObject` results
- API responses consumed without checking HTTP status
- `catch {}` or `catch (Exception) { }` that swallow errors silently
