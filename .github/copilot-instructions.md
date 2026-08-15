# Copilot Instructions — Shared Contract for Procedural Systems Agents

This repository defines four specialist agent profiles under `.github/agents/`:

- `procedural-environment` — terrain, foliage, world-scale placement
- `character-creature-systems` — character/creature rigs, appearance, locomotion
- `simulation-physics` — forces, collision, steering, springs, flocking
- `rendering-vfx` — shaders, materials, GPU particles, visual-only effects

All four inherit this document. See `AGENTS.md` for the full project overview, build/run commands, and architecture; this file adds the cross-agent policies and collaboration protocol specific to procedural work.

## Project facts

- Godot 4.7, **GDScript only** — no C#. Forward+ renderer (RenderingDevice backend) only; do not add Compatibility/mobile/web-specific code paths.
- No separate build step; Godot imports on open/run. There is no automated test suite — verification is manual (run the affected scene, or the preview lab).
- Character rig: rigid `Node3D` joint hierarchy built by `scripts/character/character_builder.gd` from a `CharacterAppearance` resource (`scripts/character/character_appearance.gd`); posed per-frame by `scripts/character/procedural_locomotion.gd`. There is no `Skeleton3D`/skinning pipeline.
- Procedural preview/capture harness: `scenes/dev/character_preview.tscn` + `scripts/dev/character_preview.gd`, driven by `PreviewCase` resources (`scripts/dev/preview_case.gd`, examples in `resources/preview_cases/`). See `docs/specifications/procedural-preview-lab.md` (status: build order step 1 implemented; interactive lab UI and non-character subject adapters, e.g. trees, are not yet built) and the `AGENTS.md` Commands section for exact invocation strings (row mode vs. batch `cases=...` mode).
- Existing procedural generators already follow the seed/RNG convention this contract requires: e.g. `scripts/world/procedural_tree.gd`'s `ProceduralTree.create(seed_value)` uses a local `RandomNumberGenerator` seeded per instance, not global randomness.
- Multiplayer is two-player LAN host/client (`scripts/multiplayer/session.gd`). Appearance/generation state that must match across peers is sent host → client once as a small versioned dictionary of primitives and reconstructed locally — see `docs/multiplayer-mvp.md` and the "procedural character rig" section of `AGENTS.md`. Locomotion itself is never synced; each peer runs it locally.
- Treat the paths and implementation-status notes in this document as maintained facts: update them in the same PR when an architectural change makes them inaccurate.

## Shared policies (all agents)

- **No C#.** GDScript only for gameplay/procedural systems.
- **Inspect before you edit.** Read the nearby script/scene and relevant doc in `docs/` before changing established architecture; preserve existing patterns instead of introducing parallel ones.
- **Reproducibility.** Any generated output that must reproduce across sessions, preview captures, saves, or network peers needs an explicit seed and a generator version. Use a local `RandomNumberGenerator` instance — never depend on global random state or implicit engine randomization.
- **Artist-facing controls.** Expose tunables designers would plausibly adjust via `@export`. Keep internal invariants, unit conversions, and safety clamps out of the exported surface.
- **Validate inputs.** Guard exported ranges and reject/clamp invalid geometry, NaN transforms, unbounded generation loops, and runaway node/instance counts.
- **Single transform owner.** Exactly one system may write a given node's transform per frame. Use engine physics (`RigidBody3D`/`CharacterBody3D`, Jolt) for collision-driven motion; use hand-rolled `Node3D` transforms only for visual-only motion. Never let both drive the same body.
- **Prefer scalable rendering.** For high instance counts (grass, leaves, debris, crowds of particles), use shared meshes/materials, `MultiMeshInstance3D`, shaders, or GPU particle systems. Do not instantiate one node per blade/leaf/particle.
- **Use the Procedural Preview Lab for visual verification when it is relevant.** Extend it via a subject-specific adapter or `PreviewCase` when a generator needs repeated iteration, comparison, or capture. Otherwise verify the affected scene directly and state why no preview case was added.
- **Character rig invariant.** Preserve the rigid `Node3D` joint hierarchy. Animate as `rotation = rest_rotation + delta`; never accumulate via `rotate_x()`/`rotate_y()`/`rotate_z()` or equivalent incremental rotation calls.
- **No speculative frameworks.** Add an abstraction (base class, generic particle/force framework, generic ECS-like system) only once a second concrete use case makes duplication genuinely painful.
- **Stay in your domain.** Keep changes within your assigned specialty (see agent profiles below). If a task genuinely requires an interface change in an adjacent domain, propose the smallest possible interface change and record it in the Specialist Handoff instead of silently expanding scope.

## Collaboration protocol

1. **Classify the work before implementing.** Identify: primary owner specialty, consulted specialties, expected on-screen instance count, frame-time assumptions, seed/reproducibility needs, and which preview case (existing or new) will verify it.
2. **One owner per feature.** Exactly one specialist is the implementation owner for a given feature branch or PR. Other specialists review or contribute a written handoff — they do not independently edit the same feature in parallel.
3. **Specialist Handoff required for cross-domain work.** When a task touches another specialty's domain, the owner ends its final response and PR description with a `## Specialist Handoff` section containing:
   - decision made
   - files and public interfaces changed
   - explicit assumptions
   - seed/version behavior
   - preview/test command to verify
   - performance considerations
   - open questions, tagged with the specialty that should answer them

   Use this exact structure:

   ```
   ## Specialist Handoff
   - **Decision:**
   - **Files / interfaces changed:**
   - **Assumptions:**
   - **Seed / generator version:**
   - **Verification:**
   - **Performance:**
   - **Open questions:** `[Owning specialty] ...`
   ```

4. **Read before you continue.** The next specialist must read the issue, PR, and any existing Specialist Handoff before changing code.
5. **Stop and ask when blocked on a decision.** If a task cannot be safely completed without a product or cross-system decision, stop after documenting the options and request direction rather than guessing.
