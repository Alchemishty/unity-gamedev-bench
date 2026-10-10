# Rubric 6: Test Quality

**Type:** Universal
**Scale:** 0-10

Coverage, tier classification, assertion quality, and whether tests would actually catch a regression.

## Scoring Criteria

| Score | Criteria |
|---|---|
| 0-2 | No tests, or tests that assert nothing meaningful (e.g., `Assert.IsTrue(true)`). |
| 3-4 | Some tests exist but poor coverage. Happy path only. Wrong tier classification (PlayMode for pure logic). Tests that test library types instead of project code. |
| 5-6 | Happy path covered. AAA pattern used. Correct tier classification. But error paths and edge cases untested. |
| 7-8 | Good coverage. EditMode for pure logic, PlayMode for MonoBehaviour. Edge cases tested. Null-throw behavior verified. Descriptive test names. |
| 9-10 | Thorough — happy path, error paths, boundary values, null-throw verification, serialization edge cases. Test names describe scenario and expectation. Setup/teardown clean. |

## Test Tier Classification (Unity-specific)

| Code Type | Correct Tier | Location |
|---|---|---|
| Pure C# logic (validators, data transforms) | EditMode | `Assets/Tests/EditMode/` |
| ScriptableObject logic | EditMode | `Assets/Tests/EditMode/` |
| MonoBehaviour lifecycle | PlayMode | `Assets/Tests/PlayMode/` |
| NetworkBehaviour sync | PlayMode | `Assets/Tests/PlayMode/` |
| UI interaction | PlayMode | `Assets/Tests/PlayMode/` |

Wrong tier classification (e.g., PlayMode test for a pure function that doesn't need Unity runtime) docks 1-2 points.

## Test Quality Indicators

### Good Tests
- **AAA pattern:** Arrange, Act, Assert — clearly separated
- **One concept per test:** Each test verifies one behavior
- **Descriptive names:** `LookupById_WithInvalidId_ThrowsInvalidOperationException`
- **Edge cases:** Empty collections, null inputs, boundary values, overflow
- **Null-throw verification:** `Assert.Throws<InvalidOperationException>(() => ...)`

### Bad Tests
- Tests that test library types (`FixedString64Bytes` round-trip) instead of project logic
- Tests with no assertions or trivial assertions
- Tests that depend on execution order
- Tests that test implementation details instead of behavior
- Single-letter variable names in test code (`a`, `b`, `c`)

## Scoring Notes

- A task with no tests scores 0/10 regardless of how the rest of the code looks.
- Tests that would fail if you introduced a bug score higher than tests that would pass regardless.
- Test count matters less than test quality — 5 targeted tests beat 20 trivial ones.
