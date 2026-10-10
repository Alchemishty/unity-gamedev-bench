# Rubric 5: Domain Correctness — Unity / Netcode

**Type:** Domain-specific (swappable)
**Scale:** 0-10

Unity engine and Netcode for GameObjects knowledge applied correctly.

> **This rubric is domain-specific.** To benchmark agents on a different domain, replace this file with your own 0-10 scale and domain checklist. See [rubrics/README.md](README.md) for guidance.

## Scoring Criteria

| Score | Criteria |
|---|---|
| 0-2 | Fundamental engine misunderstandings. NetworkVariable access before spawn. Missing base calls. Wrong lifecycle method. |
| 3-4 | Basic lifecycle correct but edge cases missed. Subscription/unsubscription mismatched. |
| 5-6 | Lifecycle ordering correct. Event cleanup present. But misses edge cases like initial value handling or late-join scenarios. |
| 7-8 | All lifecycle rules followed. Edge cases handled. Serialization validated. Event pairs matched. Editor/runtime separation correct. |
| 9-10 | Lifecycle, ownership, event cleanup, serialization validation, performance patterns, and edge cases all handled. Code demonstrates deep engine understanding. |

## Domain Checklist

Score by counting how many of these the agent gets right:

### NetworkBehaviour Lifecycle
- [ ] `OnNetworkSpawn` used (not `Awake`) for NetworkVariable access
- [ ] `base.OnNetworkSpawn()` called before custom logic
- [ ] `base.OnNetworkDespawn()` called after custom cleanup
- [ ] `OnValueChanged` initial value handled explicitly (it doesn't fire for the initial value)
- [ ] `IsOwner` / `IsServer` checked only after spawn

### Event Subscription Lifecycle
- [ ] Every `+=` has a corresponding `-=` in the lifecycle counterpart
- [ ] `OnNetworkSpawn` / `OnNetworkDespawn` paired for network events
- [ ] `OnEnable` / `OnDisable` paired for scene-lifetime events
- [ ] No anonymous lambdas on long-lived subscriptions (can't unsubscribe)

### Performance
- [ ] No `GetComponent` / `Find` / `FindObjectOfType` in `Update` or per-frame methods
- [ ] No allocations in hot paths (no `new List<>()`, no LINQ, no string concat in Update)
- [ ] No `Debug.Log` without `#if UNITY_EDITOR` in production code

### Serialization
- [ ] `JsonConvert.DeserializeObject` results validated (not null-propagated)
- [ ] NetworkVariable payloads validated on read
- [ ] `[FormerlySerializedAs]` used when renaming `[SerializeField]` fields

### Editor/Runtime Separation
- [ ] No `UnityEditor` references without `#if UNITY_EDITOR` guards
- [ ] Editor-only code in `Editor/` directories

## Adapting for Other Domains

To create a domain module for a different engine or framework:

1. Copy this file as your template
2. Replace the scoring criteria with your domain's knowledge levels
3. Replace the checklist with your domain's rules (e.g., Unreal: BeginPlay vs Constructor, UPROPERTY, replication; Godot: _ready vs _init, signal connections, process vs physics_process)
4. Keep the 0-10 scale and the same scoring structure
