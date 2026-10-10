#!/bin/bash
# Install the full agent harness into the project working copy.
# This is the configuration that scored 140/180 in the pilot run.
#
# Adapt this script for your own harness — replace the file contents
# with your scaffolding, or copy from an external directory.

set -euo pipefail

# ---- CLAUDE.md ----
cat > CLAUDE.md << 'CLAUDEEOF'
# HarnessTestBed

Unity multiplayer test project. Netcode for GameObjects, Newtonsoft.Json, NUnit tests.

## Quick Reference
- **Agent guide:** AGENTS.md — read first every session
- **Architecture:** docs/architecture.md — layers, singletons, bootstrap ordering
- **Conventions:** docs/conventions.md — coding standards authority
- **Domain:** docs/domain.md — Netcode rules, API contracts
- **Testing:** docs/testing.md — EditMode vs PlayMode
- **Enforcement:** enforcement/ — non-negotiable rules checked after writing code

## Non-Negotiable Rules
1. Never silently consume null — throw when non-null is required
2. SOLID principles are mandatory
3. Fully descriptive variable names — no abbreviations
4. Verify through Unity compiler before proceeding
CLAUDEEOF

# ---- AGENTS.md ----
cat > AGENTS.md << 'AGENTSEOF'
# HarnessTestBed — Agent Guide

Unity multiplayer test project: item system, shop, player sync over Netcode for GameObjects.

## Agent Rules

1. **Never silently consume null.** If a value must be non-null, throw `InvalidOperationException` or `ArgumentNullException` with a message identifying what's missing and where.
2. **SOLID principles are mandatory.** One class = one responsibility. Depend on abstractions.
3. **Variable names must immediately tell the reader what they represent.** `playerInventory` not `pi`. `equippedItemIds` not `eqIds`.
4. **Use game design data structures** (object pools, flyweight, dictionary lookups) where they increase efficiency.
5. **All code changes verified through Unity compiler** before moving on.
6. **Read docs/conventions.md** before writing any new code.
7. **Read docs/domain.md** before touching multiplayer or Netcode code.
8. **Tests required:** EditMode for pure logic, PlayMode for MonoBehaviour/NetworkBehaviour.
9. **When in doubt, throw an error** rather than degrade silently.
10. **Always call base.OnNetworkSpawn() and base.OnNetworkDespawn()** when overriding NetworkBehaviour lifecycle methods.

## Docs
- [Architecture](docs/architecture.md) — layers, bootstrap ordering, singletons
- [Conventions](docs/conventions.md) — coding standards authority
- [Domain](docs/domain.md) — Netcode rules and pitfalls
- [Testing](docs/testing.md) — EditMode vs PlayMode strategy
- [Enforcement](enforcement/) — non-negotiable checked rules
AGENTSEOF

# ---- Directory structure ----
mkdir -p docs enforcement memory

# ---- docs/conventions.md ----
cat > docs/conventions.md << 'CONVEOF'
# Conventions

## Null Safety
Never silently consume null when the value is required.
```csharp
// REQUIRED
var registry = ItemRegistry.Instance
    ?? throw new InvalidOperationException("ItemRegistry not initialized");

// FORBIDDEN when registry is required
if (registry == null) return;
```

## Naming
- Full words: `playerController` not `pc`, `selectedItem` not `sel`
- Booleans as questions: `isEquipped`, `canAfford`, `hasItem`
- Collections by contents: `equippedItemIds`, `shopItems`
- Methods by action: `RefreshWalletDisplay`, `SyncInventoryToNetwork`
- Minimum 3 chars (except i/j/k in for loops)

## SOLID in Unity
- **S**: One MonoBehaviour = one job
- **O**: ScriptableObjects for data-driven extension
- **L**: Honor base lifecycle contracts (call base.OnNetworkSpawn)
- **I**: Small interfaces over fat base classes
- **D**: Depend on registries/catalogs, not concrete MonoBehaviours

## Performance Red Flags
- No GetComponent/Find in Update — cache in Awake
- No allocations in hot paths (no LINQ, no new List, no string concat in Update)
- No Debug.Log in release builds without #if UNITY_EDITOR

## Script Organization
1. Constants, static fields
2. [SerializeField] fields
3. Public properties
4. Private fields
5. Unity lifecycle (Awake, Start, Update, OnDestroy)
6. NetworkBehaviour lifecycle (OnNetworkSpawn, OnNetworkDespawn)
7. Public methods
8. Private methods
CONVEOF

# ---- docs/domain.md ----
cat > docs/domain.md << 'DOMEOF'
# Domain — Netcode Rules

## Lifecycle Ordering
1. Awake — cache local references only. No NetworkVariable access.
2. OnNetworkSpawn — safe for NetworkVariables, RPCs, IsOwner. Always call base.OnNetworkSpawn().
3. OnNetworkDespawn — unsubscribe from network events. Always call base.OnNetworkDespawn().
4. OnDestroy — local-only cleanup.

## Critical Rules
- OnValueChanged does NOT fire for the initial value. Read it explicitly in OnNetworkSpawn.
- Never access NetworkVariables or invoke RPCs before OnNetworkSpawn.
- Unsubscribe from OnValueChanged in OnNetworkDespawn, not OnDestroy.
- Always call base.OnNetworkSpawn() and base.OnNetworkDespawn().
- Validate JSON deserialized from NetworkVariable payloads — never assume shape.

## Common Pitfalls
1. OnValueChanged subscription in Awake — fails silently, misses initial value
2. Missing base.OnNetworkSpawn() — skips internal Netcode initialization
3. Modifying NetworkVariable on non-owner — fails silently, check IsOwner
4. Destroying NetworkObject with Destroy() — use NetworkObject.Despawn()
5. Unsubscribing in OnDestroy instead of OnNetworkDespawn
DOMEOF

# ---- docs/architecture.md ----
cat > docs/architecture.md << 'ARCHEOF'
# Architecture

## Layers (import direction: left-to-right only)
Data → API → Registry → Player → UI

| Layer | Responsibility | Types |
|---|---|---|
| Data | Enums, DTOs, serializable structs | ItemType, ItemData, PlayerState |
| API | REST clients | GameAPI, APIConfig |
| Registry | Catalogs, SO lookups, facades | ItemCatalog, ItemRegistry |
| Player | NetworkBehaviours | PlayerController |
| UI | MonoBehaviour UIs | ShopController, HUDPanel |

## Singletons
- ItemRegistry — DontDestroyOnLoad, throw if null when accessed
- GameAPI — DontDestroyOnLoad, throw if null when accessed
ARCHEOF

# ---- docs/testing.md ----
cat > docs/testing.md << 'TESTEOF'
# Testing

## EditMode Tests (pure C#)
Location: Assets/Tests/EditMode/
For: data validation, business logic, serialization, catalog lookups.
Pattern: [Test], AAA, NUnit assertions, no MonoBehaviour.

## PlayMode Tests (Unity runtime)
Location: Assets/Tests/PlayMode/
For: MonoBehaviour lifecycle, NetworkBehaviour sync, component interaction.
Pattern: [UnityTest] returning IEnumerator, [TearDown] cleanup.

## What to Extract
Move business logic out of MonoBehaviours into pure C# classes.
Test the pure classes in EditMode. Keep MonoBehaviours thin (wiring only).
TESTEOF

# ---- enforcement/ ----
cat > enforcement/null-safety.md << 'NULLEOF'
# Enforcement: Null Safety
Never silently consume null when the value is required.
- GetComponent<T>() where T is required → throw
- Singleton.Instance → throw if null
- Deserialization → validate non-null
- if (x == null) return; when x is required → VIOLATION
NULLEOF

cat > enforcement/naming.md << 'NAMEEOF'
# Enforcement: Naming
- No abbreviations (except id, url, api, ui, rpc, dto)
- Booleans: is/has/can/should prefix
- Collections: describe contents
- Methods: describe action
- Minimum 3 chars (except i/j/k loop counters)
NAMEEOF

cat > enforcement/netcode-lifecycle.md << 'NETEOF'
# Enforcement: Netcode Lifecycle
- Never access NetworkVariables before OnNetworkSpawn
- Always call base.OnNetworkSpawn() and base.OnNetworkDespawn()
- Subscribe to OnValueChanged in OnNetworkSpawn, unsubscribe in OnNetworkDespawn
- Read initial NetworkVariable value explicitly in OnNetworkSpawn
- Never check IsOwner in Awake (ownership not assigned yet)
NETEOF

cat > enforcement/serialization-safety.md << 'SEREOF'
# Enforcement: Serialization Safety
- Every JsonConvert.DeserializeObject result must be null-checked and throw on failure
- Every API response must check HTTP status before deserializing
- AccessoryState/PlayerState JSON payloads validated on every read
SEREOF

cat > enforcement/event-cleanup.md << 'EVTEOF'
# Enforcement: Event Cleanup
- Every += must have a matching -= in the lifecycle counterpart
- OnNetworkSpawn ↔ OnNetworkDespawn
- OnEnable ↔ OnDisable
- No anonymous lambdas for subscriptions that need cleanup
EVTEOF

cat > enforcement/layer-imports.md << 'LAYEOF'
# Enforcement: Layer Imports
Data → API → Registry → Player → UI
Lower layers must not reference higher layers.
LAYEOF

cat > enforcement/editor-runtime.md << 'EDEOF'
# Enforcement: Editor/Runtime
No UnityEditor references in runtime code without #if UNITY_EDITOR guards.
EDEOF

# ---- memory/ stubs ----
for f in patterns fixes preferences review-lessons domain; do
    cat > "memory/${f}.md" << MEMEOF
# ${f:u} — Cross-Session Memory

Entries added by /retrospective after completing features.

---
MEMEOF
done

echo "Harness installed successfully."
