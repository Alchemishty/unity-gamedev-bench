<!--
repo: https://github.com/Alchemishty/ugb-starter.git
base_sha: c74a25490ef57dab555cea586a301202c93a7a93
rubrics: correctness,robustness,readability,architecture,domain_correctness,test_quality
-->
# Task 7: Three-Feature Sprint

**Category:** Multi-Step
**Difficulty:** Hard

## Prompt

> Build these three features in order:
> 1. Add a currency display to the HUD showing the player's gold count, refreshed in real-time.
> 2. Add a purchase confirmation dialog that shows the item name, cost, and remaining gold before buying.
> 3. Add a purchase history panel that logs all purchases with timestamps.

## What It Exercises

- Context retention across multiple implementation steps within one session
- Plan adherence — building features in the specified order
- Convention consistency — do naming, null handling, and architecture stay consistent from step 1 to step 3?
- Cross-feature coherence — do the three features share data structures sensibly?
- Quality degradation — does the agent's code quality decline as conversation length grows?

## Expected Touchpoints

**Step 1:**
- Modified: `UI/HUDPanel.cs` — add gold display with refresh mechanism
- Potentially modified: `API/GameAPI.cs` — wallet fetch integration

**Step 2:**
- New file: `UI/PurchaseConfirmationDialog.cs` or similar
- Modified: `UI/ShopController.cs` — wire buy button through confirmation

**Step 3:**
- New file: `Data/PurchaseRecord.cs` or similar — purchase log data
- New file: `UI/PurchaseHistoryPanel.cs` or similar

## Landmine Map

- **Landmine #1** (ItemRegistry silent null): May surface when accessing item data for the confirmation dialog
- **Landmine #5** (Unvalidated deserialization): May surface when fetching wallet data for currency display

## Scoring Notes

- **Primary metric: Context retention.** Compare rubric scores for step 1 code vs step 3 code. A large quality delta indicates context degradation.
- Readability: Are naming conventions consistent across all three features? Does step 3 use the same descriptive naming as step 1?
- Architecture: Do the three features share sensible structures (e.g., a common wallet data source) or does each one re-fetch independently?
- Robustness: Is null handling equally thorough in step 3 as in step 1?
