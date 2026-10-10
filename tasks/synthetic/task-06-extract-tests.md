<!--
repo: https://github.com/Alchemishty/ugb-starter.git
base_sha: c74a25490ef57dab555cea586a301202c93a7a93
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task 6: Extract Testable Logic

**Category:** Refactor
**Difficulty:** Medium

## Prompt

> We need to add tests for the purchase flow but the logic is baked into UI button handlers. Make it testable and add the tests.

## What It Exercises

- Extracting business logic from MonoBehaviour into pure C# classes
- Creating EditMode tests for extracted logic (no Unity runtime needed)
- Understanding what's testable without Unity (validation, calculations) vs what needs PlayMode (UI interaction, network)
- AAA test pattern (Arrange, Act, Assert)
- Testing error paths — null inputs, insufficient funds, invalid items

## Expected Touchpoints

- New file: Pure C# class for purchase validation/logic (e.g., `PurchaseValidator.cs`, `ShopService.cs`)
- Modified: `UI/ShopController.cs` — delegates to extracted logic, stays thin
- New files: `Tests/EditMode/` — tests for the extracted logic
- Directory creation: `Assets/Tests/EditMode/` if it doesn't exist

## Landmine Map

- **Landmine #2** (Abbreviated variables): If the agent touches ShopController, abbreviations should be renamed
- **Landmine #5** (Unvalidated deserialization): The purchase flow calls GameAPI which has unvalidated deserialization — extracted logic should validate inputs

## Scoring Notes

- Architecture: The extracted class must be pure C# (no MonoBehaviour, no GameObject, no ScriptableObject.CreateInstance) to be testable in EditMode
- Test Quality: Tests must exercise the ACTUAL extracted class, not Unity standard library types. AAA pattern, one concept per test, descriptive test method names (`PurchaseValidator_WithInsufficientFunds_ReturnsInsufficientFunds`)
- Readability: Extracted class should have clear method signatures. The MonoBehaviour should be visibly thinner after extraction.
- Correctness: Tests should cover happy path, insufficient funds, null item, already owned, and any other edge cases the agent identifies
