# Island Search & Rescue

A low-poly, third-person 3D co-op search-and-rescue game set across bounded island regions. The first goal is a small but convincing two-player rescue loop: receive an incident, travel and search outdoors, locate a casualty or hazard, resolve it, and return to complete the call together.

This is a **Godot 4.6, GDScript-only** project. C# can be added later if a concrete need emerges.

## Prototype focus

The initial playable slice is **two-player co-op**, on-foot wilderness rescue in third person. It deliberately excludes vehicle interiors and extensive building interiors. Buildings are mostly exterior landmarks; enterable spaces exist only when a rescue scenario needs one.

The game is **not an open world**. It should use compact, authored playable regions—an inland island, forest valley, coastal reserve, or similar—each with a few memorable points of interest and a self-contained incident set. The first region is an inland island built for on-foot search and rescue. A rescue station acts as the home base for briefing, basic gear, and later unlocks.

The project is desktop-first and uses Godot's **Forward+** renderer as its visual baseline. Web and mobile exports are deferred; the team can reconsider them as separate platform efforts later.

Project code is intended to use **Apache License 2.0**; original artwork is intended to use **CC BY 4.0**. See [Licensing and third-party assets](docs/licensing-and-third-party-assets.md).

The visual style is a hybrid: faceted static terrain and water/environment systems in Godot, with **Goxel** for chunky, readable vehicles, foliage, buildings, equipment, and other authored assets.

See [specification.md](specification.md) for the product scope and [roadmap.md](roadmap.md) for the order of work.

## Quick start

1. Install the standard Godot Engine **4.6** editor and Git.
2. Create or open the Godot project in this repository.
3. Open `project.godot` and run the game with <kbd>F5</kbd>.

Use Forward+ in Project Settings for the intended desktop look. Develop and test on machines with current graphics hardware that supports Godot's RenderingDevice-based renderers.

The game opens maximized and is HiDPI-aware on macOS. Its 1280×720 logical viewport uses Godot's `canvas_items` stretch mode, so the UI and scene scale with the available display size.

## Current scaffold demo

The current main scene is a two-player LAN third-person walking demo. On the first machine, select **Host LAN session**. On the second machine, enter the host machine's LAN IP address and select **Join session**. Both machines use UDP port `8910`; allow it through the host firewall if needed.

Use <kbd>WASD</kbd> to move, <kbd>Shift</kbd> to sprint, and <kbd>Space</kbd> to jump. The mouse controls the orbit camera. <kbd>Escape</kbd> releases/captures the mouse; use the on-screen **End session** control to return the host—and connected client—to the session menu.

Each responder currently carries a visual toolbelt with binoculars, a map pouch, and a magnetic compass. The compass needle remains aligned to world north as the responder turns. These are placeholder kit props only; selecting, using, and choosing equipment begins at the later loadout milestone.

For a quick same-machine check, host in one desktop instance and join `127.0.0.1` from a second instance. Also test across two LAN machines before considering the networking checkpoint complete.

Follow the [two-player LAN test guide](docs/lan-multiplayer-testing.md) for the full repeatable acceptance pass and troubleshooting steps.

## Documentation map

- [Specification](specification.md) — playable goals, boundaries, and acceptance criteria.
- [Roadmap](roadmap.md) — milestones and deliberately deferred work.
- [Architecture](docs/architecture.md) — small-scene, GDScript-first structure.
- [Technical scaffold requirements](docs/technical-scaffold-requirements.md) — implementation handoff for the initial terrain, third-person, and LAN co-op foundation.
- [Gameplay and progression](docs/gameplay-and-progression.md) — the rescue interaction, loadout, and capability-unlock model.
- [Multiplayer MVP](docs/multiplayer-mvp.md) — the deliberately narrow two-player host/join contract.
- [Two-player LAN test guide](docs/lan-multiplayer-testing.md) — setup, acceptance checks, and troubleshooting for the current scaffold.
- [Asset and model conventions](docs/assets-and-models.md) — the handoff contract for low-poly art.
- [Goxel workflow](docs/goxel-workflow.md) — the source-to-Godot path for voxel models.
- [Visual direction](docs/visual-direction.md) — the island SAR north star, layered terrain, POIs, and ambience.
- [Development workflow](docs/development-workflow.md) — branching, testing, and practical working rules.
- [Licensing and third-party assets](docs/licensing-and-third-party-assets.md) — provenance and add-on policy.

## Intended repository layout

```text
res://
├── addons/                 # Third-party Godot add-ons; keep their licenses
├── assets/
│   ├── audio/
│   ├── models/
│   ├── textures/
│   └── ui/
├── scenes/
│   ├── world/
│   ├── player/
│   ├── vehicles/
│   ├── npcs/
│   ├── incidents/
│   ├── multiplayer/
│   └── ui/
├── scripts/
│   ├── interaction/
│   ├── incidents/
│   ├── multiplayer/
│   ├── player/
│   └── vehicles/
└── resources/
    ├── incidents/
    └── vehicles/
```

Keep game-specific scenes and scripts close together when that is clearer than this top-level grouping. The layout is a starting point, not an architectural law.

## First playable target

**Callout: Lost hiker on an inland forest trail.** One player hosts and the other joins. Both start at the rescue station, take the default response kit, accept the call, follow a rough route on foot, search the area, find an injured hiker, use the relevant kit through one clear interaction, escort or carry them to a marked extraction point, and complete the incident together.

If that works, the project has earned the next layer: a drivable ground vehicle, a simple fire incident, then an arcade helicopter.

## Project principles

- Prove the rescue loop before adding content volume or technology.
- Make co-op state clear and reliable before adding more players, matchmaking, or online services.
- Build readable, forgiving third-person controls before realistic simulation.
- Make equipment selection and scene awareness engaging; do not simulate clinical procedures.
- Reuse a small number of scene patterns and resources.
- Prefer outdoor spaces and strong landmarks over detailed interiors.
- Treat every external asset, plug-in, sound, and texture as something that needs a recorded source and license.

## Contributing

Read [Development workflow](docs/development-workflow.md) before making changes and [Asset and model conventions](docs/assets-and-models.md) before importing art.
