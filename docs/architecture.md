# Architecture — Keep the Prototype Small

## Guiding decision

Use Godot scenes, node composition, resources, and GDScript as the default architecture. Add an abstraction only after two real uses make the duplication or coupling painful.

The project uses the standard Godot 4.7 editor and GDScript.

## Simple scene composition

```text
Main
├── Session (host or joined client)
├── ActiveLevel
│   ├── World (terrain / landmarks)
│   ├── IncidentSpawner
│   ├── ExtractionPoint
│   └── Player
├── ActiveIncident
└── HUD
```

Prefer small reusable scenes, for example `Player.tscn`, `Casualty.tscn`, `IncidentHiker.tscn`, `ExtractionPoint.tscn`, and `Interactable.tscn`. A level scene owns its terrain and points of interest. The main scene only composes the selected level, current incident, and HUD, and connects the few signals it needs.

The rescue station may be a small level scene or a simple briefing/loadout screen. It is a home base, not a required open-world connector between regions.

## Responsibility boundaries

| Area | Owns | Does not own |
| --- | --- | --- |
| Player | movement, camera, attempting an interaction | mission rules, dispatch UI |
| Session / host | player spawning, authority and shared-session lifecycle | player camera, art/UI presentation |
| Interactable | prompt data and performing a local action | deciding overall incident completion |
| Incident | lifecycle, objectives, target setup, completion | player movement/camera |
| Casualty / hazard | local state and visual feedback | dispatch or global progression |
| HUD | displaying state supplied by the game | deciding gameplay state |
| World | terrain and fixed landmarks | incident-specific mission logic |

Use signals for meaningful events such as `interaction_completed`, `casualty_found`, `casualty_ready_for_extraction`, and `incident_completed`. Avoid an all-knowing manager that every script reaches into.

## Incident lifecycle

Use a small explicit state model so that resets and future multiplayer work are understandable:

```text
offered → accepted → searching → located → resolving → extracting → completed
```

Not every incident needs every state, but transitions should be named and observable. Store incident definitions in `.tres` resources when multiple scenarios begin sharing fields, such as title, objective text, search area, target scene, and extraction destination. One-off prototypes can initially keep values in their incident scene.

## Regions and progression

Each playable region is an independently loaded scene with a small set of authored points of interest. There is no need for world streaming or a shared coordinate system between regions. When content begins to multiply, add a small `LevelDefinition` resource with a title, preview image, level scene, available incidents, and basic unlock requirement.

Do not build persistent progression yet. At the prototype stage, a simple in-memory `PrototypeProfile` (current unlock flags and selected level) is enough to test the campaign shape. Promote it to a saved profile only when restarting the game must preserve player progress. Keep profile data to booleans/identifiers such as `flashlight_unlocked`, `ground_vehicle_unlocked`, and `coastal_reserve_unlocked`; scenes should not infer unlocks from arbitrary completed-objective state.

When the rescue station enters the prototype, keep loadouts data-driven and small. A `GearDefinition` resource can name an item, its capability category, its icon/scene, and any incident tags it can address. An `EquipmentDispenser` only offers unlocked definitions and produces the selected player loadout. Do not create a generic inventory framework before the first loadout decision is fun.

## Inputs and interactions

Define actions in Project Settings rather than checking raw keys in scripts. Start with named actions such as `move_forward`, `move_back`, `move_left`, `move_right`, `sprint`, `jump`, `interact`, and `cancel`.

An interaction should answer three questions in one place: what the player may do, whether they are in range, and what happens when the action succeeds. Start with the nearest valid target or a simple forward raycast; optimize selection rules only if it becomes confusing.

## Multiplayer MVP — build it with the first slice

The vertical slice is two-player host/join co-op. Use a listen-server model: one player runs the host and the other joins. For the MVP, target a local network and do not build accounts, matchmaking, relay services, a dedicated server, or host migration.

The host is authoritative for shared game facts: level selection/loading, player spawn slots, active incident lifecycle, casualty/hazard state, extraction state, and completion/unlock result. A player's movement may be locally controlled for responsiveness, but its replicated transform/animation must be visible to the other player. Every interaction that changes shared incident state goes to the host for validation and broadcast.

Keep ownership clear in scene APIs. For example, an interaction request contains the requesting peer and target identifier; the host decides whether the target can change state, then replicates the result. Do not let each client independently create casualties, advance objectives, or calculate rewards.

See [Multiplayer MVP](multiplayer-mvp.md) for the supported session contract and test cases.

## Rendering target

The supported baseline is **Forward+ on modern desktop hardware**. It is Godot's advanced desktop renderer and uses the RenderingDevice backend. It suits the planned wilderness scenes and leaves room for advanced lighting and environment features, but its base cost makes profiling essential as terrain, foliage, lights, and effects are added.

Web and mobile are deferred. Do not spend prototype time maintaining Compatibility or Mobile renderer parity, but avoid assuming that an untested fallback will preserve the intended visual result. See Godot's [renderer overview](https://docs.godotengine.org/en/latest/tutorials/rendering/renderers.html) when the platform strategy is revisited.

## Avoid for now

- Global service locators for ordinary scene references.
- A custom ECS, dependency injection framework, or event bus.
- Premature generic mission framework.
- Matchmaking, dedicated-server, host-migration, or generic networking frameworks beyond the two-player MVP.
