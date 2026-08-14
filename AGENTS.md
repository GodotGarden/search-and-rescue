# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project

Island Search & Rescue: a low-poly, third-person 3D co-op search-and-rescue game built in **Godot 4.7, GDScript-only** (C# is not used). The prototype goal is a two-player co-op rescue loop: accept a callout, travel and search an outdoor region on foot, locate a casualty, resolve it through one clear interaction, and extract together. See `specification.md` for product scope and `roadmap.md` for milestone order.

## Commands

There is no separate build step; Godot imports assets on open/run.

- **Open the editor**: `godot --path . -e`
- **Run the game** (main scene, two-player LAN host/join demo): `godot --path .` or F5 in the editor
- **Run the procedural character preview lab** (dev harness, renders `CharacterAppearance` resources to a PNG + JSON metadata sidecar and quits — not `--headless`, it needs a real rendering context to produce pixels):
  ```bash
  # Row mode: side-by-side comparison of every *.tres in appearance_dir (or an explicit appearance_paths list)
  godot --path . res://scenes/dev/character_preview.tscn --resolution 1600x1000 --quit-after 15 -- output_path=/tmp/out.png

  # Batch mode: named, reproducible PreviewCase captures (own appearance/pose/camera view/stage preset each)
  godot --path . res://scenes/dev/character_preview.tscn --quit-after 60 -- cases=res://resources/preview_cases/responder_default_front.tres,res://resources/preview_cases/responder_default_walk_contact.tres
  ```
  Overrides are passed as `key=value` after `--` (see `@export` vars at the top of `scripts/dev/character_preview.gd` for the full list: `appearance_dir`, `appearance_paths`, `cases`, `stage_preset` — `neutral_review`/`silhouette`/`gameplay_camera`, `camera_view` — `front`/`side_left`/`side_right`/`rear`/`three_quarter`, `pose_phase`/`pose_speed`/`pose_grounded`, `live_playback`, `show_grid`, `capture_settle_frames`). `PreviewCase` (`scripts/dev/preview_case.gd`) is the resource type for batch-mode entries; see `resources/preview_cases/` for examples.
- There is no automated test suite yet. Verification is manual: run the affected scene in the editor and exercise the happy path plus one edge case (restart, leaving interaction range, interacting twice). For networked changes, test host+client across two machines/instances, not two copies of local state — see `docs/lan-multiplayer-testing.md`.

## Architecture

Full detail lives in `docs/architecture.md`; the essentials:

**Guiding decision**: use plain Godot scenes, node composition, resources, and GDScript. Add an abstraction only after two real uses make duplication/coupling actually painful. Avoid global service locators, a custom ECS, a generic event bus, or a general inventory/mission framework — these are explicitly out of scope until proven necessary.

**Scene composition**: `Main` composes a `Session` (host or joined client), the active level (`World` + `IncidentSpawner` + `ExtractionPoint` + `Player`), the active incident, and the `HUD`. Small reusable scenes (`Player.tscn`, `Casualty.tscn`, `IncidentHiker.tscn`, `ExtractionPoint.tscn`, `Interactable.tscn`) are preferred over monoliths.

**Responsibility boundaries** (who owns what — see the table in `docs/architecture.md`): Player owns movement/camera/interaction attempts, not mission rules. Session/host owns spawning and shared-session lifecycle, not camera/UI. Interactable owns prompt data and local action, not overall incident completion. Incident owns lifecycle/objectives, not player movement. Use signals (`interaction_completed`, `casualty_found`, `casualty_ready_for_extraction`, `incident_completed`) for cross-scene events rather than deep node-path reaches.

**Incident lifecycle** is an explicit named state machine: `offered → accepted → searching → located → resolving → extracting → completed`. Keep transitions observable rather than implicit.

**Multiplayer model**: two-player listen-server co-op (one host, one client), LAN-only for the MVP — no matchmaking, relay, dedicated server, or host migration. The host is authoritative for level selection, spawns, incident lifecycle, casualty/hazard state, extraction, and completion. Every interaction that changes shared state is a client request → host validates → host broadcasts result (see the `request_interaction` / `validate_interaction` / `apply_and_broadcast_interaction_result` shape in `docs/multiplayer-mvp.md`). Player movement is locally controlled for responsiveness but its replicated transform must reach the other peer. Full session contract and sync table: `docs/multiplayer-mvp.md`.

**Rendering target**: Forward+ only (desktop, RenderingDevice backend). Web/mobile/Compatibility renderer support is deliberately deferred — don't spend effort on parity.

**Procedural character rig** (`docs/procedural-character-spec.md`): characters are built as a hierarchy of rigid `Node3D` joints with primitive meshes, *not* a skinned `Skeleton3D` mesh — there's no rigger, so no weight-painting pipeline. `scripts/character/character_builder.gd` builds the joint hierarchy + meshes from a `CharacterAppearance` resource; `scripts/character/procedural_locomotion.gd` poses joints per frame (sine-driven, phase advances by distance travelled, not raw time) from horizontal velocity + grounded state. Every joint stores a rest rotation and locomotion applies an *additive* delta on top (`rotation = rest_rotation + delta`), never an accumulated `rotate_x()`. This segmented/blocky motion is the intentional MVP visual language, not a placeholder pending a future skinning pass — don't build "swap to skinning later" abstractions for it.
  - `CharacterAppearance` is a `.tres` `Resource`: cosmetic fields (height, build, skin/hair color, clothing color) carry no gameplay meaning; `head_equipment` is a separate, explicit gameplay-visible layer that visually overrides `hair_style` when set. Keep that split when adding new fields/slots.
  - Local/remote player identity color is a distinct disambiguation layer from cosmetic clothing color — don't fold one into the other.
  - The authoring `Resource` is not the wire format: appearance is sent host → clients once at spawn as a small versioned dictionary of primitives, then reconstructed locally into a `CharacterAppearance` instance per peer. Locomotion itself is never synchronized — each peer runs it locally off whatever position/velocity it already has.
  - `docs/specifications/procedural-preview-lab.md` describes the generalization of the dev preview harness — a reusable preview stage + subject-adapter pattern for procedural visuals (characters now, trees/props later). Build order step 1 (deterministic pose capture, camera-view/stage presets, batch `PreviewCase` mode) is implemented; the interactive lab UI, subject-adapter extraction, and the planned `CharacterPose` data contract for static poses (kneeling, prone, supine, etc.) are not yet built.

**Regions**: each playable region is an independently loaded scene with a handful of authored points of interest — no world streaming, no shared coordinate system across regions, not an open world.

## Conventions

- Define input actions in `project.godot` / Project Settings (`move_forward`, `interact`, `sprint`, etc.) rather than checking raw keys in scripts.
- Name scene roots by role (`Player`, `Casualty`, `IncidentHiker`). Keep a script next to its scene when tightly scene-specific; use `scripts/` for behavior reused across scenes.
- Prefer `@export`ed variables for values a designer would tune in the Inspector.
- Store shared/reusable definitions (incident data, gear, appearance presets) as `.tres` resources rather than hardcoded values once more than one instance needs the same shape (see `GearDefinition`, `CharacterAppearance`).
- Comment only where intent isn't obvious from structure/naming — this repo's existing docs are deliberately explicit about *why*, not *what*.
- Don't commit Godot's generated cache/import folders (`.godot/`) unless a specific generated file is genuinely needed.
- Add a third-party add-on only to solve a present, understood problem; record its source/version/license and confirm Godot 4.7 compatibility first (see `docs/licensing-and-third-party-assets.md`). Prefer native Godot features for the first slice.
- Art pipeline: **Goxel** for chunky voxel-style assets (vehicles, foliage, buildings, equipment) exported into Godot; see `docs/goxel-workflow.md` and `docs/assets-and-models.md` for the source-to-Godot handoff contract and asset checklist.

## Key docs (read before large changes)

- `specification.md` — product scope and acceptance criteria.
- `roadmap.md` — milestone order and deliberately deferred work.
- `docs/architecture.md` — scene structure, responsibility boundaries, incident state model.
- `docs/multiplayer-mvp.md` — the two-player host/join contract and sync table.
- `docs/technical-scaffold-requirements.md` — implementation handoff for terrain/third-person/LAN co-op foundation.
- `docs/procedural-character-spec.md` — character rig/locomotion/appearance architecture (status: accepted for MVP).
- `docs/character-appearance-visual-design.md` — follow-up visual-design goals on top of the accepted rig architecture.
- `docs/specifications/procedural-preview-lab.md` — dev-time preview/capture tooling for procedural visuals (status: proposed).
- `docs/development-workflow.md` — branching, day-to-day loop, testing checklist.
- `docs/lan-multiplayer-testing.md` — repeatable two-player LAN acceptance pass.
- `docs/licensing-and-third-party-assets.md` — provenance and add-on policy (code is Apache 2.0, original art is CC BY 4.0).
