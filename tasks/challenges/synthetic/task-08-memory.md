# Task 8: Cross-Session Memory

**Category:** Cross-Session
**Difficulty:** Hard

## Prompt

### Session 1

> Add a player status indicator that syncs a custom enum (Ready, InGame, Away) across all clients using a NetworkVariable. Show the status next to each player's name in the HUD.

### Session 2 (new session, same project state)

> Add a player title system — each player has a display title (string) synced to all clients via NetworkVariable, editable by the owning player. Show it in the HUD below the player name.

## What It Exercises

- Cross-session knowledge transfer — does the agent learn from session 1 and apply that knowledge in session 2?
- The OnValueChanged initial-value pitfall — session 1 will likely surface it (same pattern as landmine #4). Does the agent avoid it proactively in session 2?
- Memory systems — agents with retrospective/memory features should capture the pitfall in session 1 and recall it in session 2
- Consistent Netcode patterns across sessions

## Expected Touchpoints

**Session 1:**
- New file: `Data/PlayerStatus.cs` — enum (Ready, InGame, Away)
- Modified: `Player/PlayerController.cs` — add NetworkVariable for status
- Modified: `UI/HUDPanel.cs` — display status text

**Session 2:**
- Modified: `Player/PlayerController.cs` — add NetworkVariable for title
- Modified: `UI/HUDPanel.cs` — display title below name

## Landmine Map

- **Landmine #4** (OnValueChanged in Awake): The existing pattern in PlayerController. Session 1 will force the agent to confront this when adding the status NetworkVariable. Session 2 tests whether the agent remembers the lesson.

## Scoring Notes

- **Primary metric: Memory application.** Binary — did the agent handle OnValueChanged initial value correctly in session 2 WITHOUT re-encountering the bug first?
- Domain Correctness: Both sessions should use OnNetworkSpawn (not Awake), call base methods, read initial value explicitly, and pair subscribe/unsubscribe in correct lifecycle methods.
- The standard rubrics also apply to all code in both sessions.
- Score sessions independently, then add the memory binary as a bonus metric.

## Execution Protocol

1. Run session 1 with the Session 1 prompt
2. Let the agent complete (including any memory/retrospective if the agent supports it)
3. Start a NEW session with the same project files (session 1's changes preserved)
4. Run session 2 with the Session 2 prompt
5. Score both sessions, plus the memory transfer metric
