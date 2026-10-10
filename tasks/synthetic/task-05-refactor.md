<!--
repo: https://github.com/Alchemishty/ugb-starter.git
base_sha: c74a25490ef57dab555cea586a301202c93a7a93
difficulty: medium
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task 5: Clean Up Messy Script

**Category:** Refactor
**Difficulty:** Medium

## Prompt

> ShopController.cs is getting hard to maintain. It handles too many things. Improve it.

## What It Exercises

- Single Responsibility Principle — splitting a god class into focused classes
- Naming discipline — renaming abbreviated variables to descriptive names
- Performance awareness — removing GetComponent from hot paths
- Layer discipline — placing extracted classes in correct architectural layers
- Event cleanup — adding missing listener removal
- Knowing when NOT to change — don't alter API signatures others depend on without reason

## Expected Touchpoints

- Modified: `UI/ShopController.cs` — renamed variables, removed Update loop, potentially split
- New files: Extracted business logic classes (purchase validation, wallet management)
- Potentially new: Test files for extracted logic

## Landmine Map

- **Landmine #2** (Abbreviated variables): `sel`, `mgr`, `itms`, `gld`, `ld`, `pc`, `spwnedCards` — all should be renamed to descriptive names
- **Landmine #3** (GetComponent in Update): `UpdateSelectedItemDisplay()` calls `GetComponent<ItemRegistry>()` every frame via Update — must be cached or removed

## Scoring Notes

- Readability: All abbreviated variables must be renamed. `canAffordSelectedItem` scores higher than `afford`. Booleans should read as questions.
- Architecture: Extracting business logic into separate classes scores higher than just renaming within the same god class. But don't over-engineer — unnecessary abstraction layers score lower.
- Domain Correctness: Removing GetComponent from the Update path is a performance requirement. Event cleanup (AddListener/RemoveListener pairs) should be present.
- Robustness: After refactoring, null handling should be explicit. Silent `return` on null `GameAPI.Instance` is a robustness violation.
- Note: Renaming `[SerializeField]` fields without `[FormerlySerializedAs]` breaks existing scene/prefab serialization — flag this as a violation if present.
