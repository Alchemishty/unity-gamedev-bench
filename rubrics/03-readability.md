# Rubric 3: Readability

**Type:** Universal
**Scale:** 0-10

How quickly can a human understand what this code does?

## Scoring Criteria

| Score | Criteria |
|---|---|
| 0-2 | Abbreviated names, unclear control flow, misleading or excessive comments. |
| 3-4 | Mix of descriptive and cryptic names. Some methods are clear, others require tracing. |
| 5-6 | Mostly readable. Names are descriptive but a few abbreviations or ambiguous identifiers remain. Control flow is straightforward. |
| 7-8 | Clear throughout. Every identifier communicates intent. Booleans read as questions. Collections named by contents. Methods describe their action. Comments only where why is non-obvious. |
| 9-10 | Code is self-documenting. A developer unfamiliar with the project can understand each method without external context. File organization is logical and consistent. |

## Sub-Components

### Naming Quality (highest weight)
Names are the primary vehicle for readability. Score heavily on:

- **Full words always:** `playerAccessory` not `pa`, `equippedItemsBySlot` not `eqMap`
- **Booleans as questions:** `isEquipped`, `hasBeenPurchased`, `canAffordItem`
- **Collections by contents:** `accessoryItems`, `ownedAccessoryIds`, `accessoryDataById`
- **Methods by action:** `RefreshWalletDisplay()` not `Refresh()`, `SyncEquippedAccessoriesToNetwork()` not `DoSync()`
- **Minimum length:** 3+ characters for locals (except `i`/`j`/`k` in for-loops), 5+ for fields/properties

### Structure
- File organization (constants, fields, lifecycle, public, private, nested)
- Method length (long methods that do multiple things hurt readability)
- Control flow clarity (early returns over deep nesting)

### Comments
- **Appropriate:** Why-comments explaining non-obvious constraints
- **Inappropriate:** What-comments restating the code, section dividers adding no information, commented-out code

### Abstraction Level
- Neither too clever (one-liner LINQ chains that require mental parsing)
- Nor too verbose (10 lines for something that has a clear 3-line form)

## Violations to Flag

- Any single-letter variable name outside a for-loop counter
- Any abbreviation not in the universally-understood set (id, url, api, ui)
- Boolean without `is`/`has`/`can`/`should`/`was` prefix
- Method named `Handle()`, `Process()`, `DoStuff()`, `Refresh()` without specificity
- What-comments: `// get the player` above `GetComponent<Player>()`
