# Procedural Character Specification

**Status: accepted for the MVP.** The architecture (segmented rig, procedural locomotion, appearance/equipment data model) is settled; remaining work is implementation against the phased build order below, not further design debate.

The first playable build of this architecture reads as too visually uniform (stacked rectangles rather than a designed responder). See [Character Appearance Visual Design](character-appearance-visual-design.md) for the follow-up design goals on `CharacterAppearance`/`character_builder.gd` — a visual pass on top of this document's architecture, not a revision of it.

## Purpose

Replace the placeholder capsule in [Responder.tscn](../scenes/player/Responder.tscn) with a generated low-poly humanoid that can be customized (stature, build, gender presentation, coloring) and animated (idle, walk, run, and later gestures) without a 3D modeller or rigger. This is the "purpose-built follow-up workflow" that [assets-and-models.md](assets-and-models.md#goxel-source-and-export-format) anticipated once a character needs a skeleton, animation, or hierarchy.

## Goals

- A `CharacterAppearance` resource that can produce a visibly different-looking responder/casualty from a small set of parameters, entirely at runtime, with no imported model.
- A joint hierarchy that can be posed procedurally: idle sway, walk cycle, run cycle, driven by the character's current speed — no keyframe authoring tool required.
- Reuse across the two known `character_` roles: player responders now, hiker/casualty NPCs later ([visual-direction.md](visual-direction.md) and [assets-and-models.md](assets-and-models.md) both name casualties as a near-term character asset).
- Stay inside the existing voxel-low-poly language: chunky blocks, faceted forms, readable silhouette over surface detail ([visual-direction.md](visual-direction.md#color-and-readability)).
- Cheap to replicate in the two-player MVP: appearance is a handful of floats/colors sent once at spawn, not a streamed asset.

## Non-goals (for this pass)

- Sculpted or expressive faces. Low-poly blocky heads can vary proportion, skin tone, and a couple of hair/headwear shapes — not eyebrows, eye shape, or expression.
- Cloth/hair simulation, IK foot-planting, or slope-adaptive posing. Accept some foot-sliding on slopes, consistent with the "forgiving exploration" bar already set for movement in [technical-scaffold-requirements.md](technical-scaffold-requirements.md#4-third-person-responder).
- A general animation-authoring pipeline (`.anim` libraries, blend trees) or a general character-customization UI. Both can follow once the underlying rig is proven.
- Skinned-mesh deformation. See the rig decision below for why.

## Key decision: segmented rigid parts, not a skinned skeleton

Godot's usual character pipeline is a single skinned mesh deformed by a `Skeleton3D`. That needs a rigger to weight-paint vertices to bones — the exact gap this project doesn't have.

Instead, build the body as a **hierarchy of joints**, where each joint is a `Node3D` holding one or two primitive meshes (the current `Responder.tscn` already does this for the toolbelt: belt, binoculars, pouch, and compass are separate primitive nodes, not one mesh). A shoulder joint rotates and everything parented under it — upper arm, elbow joint, forearm, hand — moves with it. No skinning, no weight painting, no imported rig.

```text
CharacterRig (Node3D)
├── Pelvis
│   ├── Torso
│   │   ├── Neck → Head
│   │   ├── ShoulderL → UpperArmL → ElbowL → ForearmL → HandL
│   │   └── ShoulderR → UpperArmR → ElbowR → ForearmR → HandR
│   ├── HipL → ThighL → KneeL → ShinL → FootL
│   └── HipR → ThighR → KneeR → ShinR → FootR
```

Trade-off to accept: joints are rigid blocks, so motion reads as blocky/toy-like rather than fluid. That fits the existing voxel-low-poly direction; it would look wrong in a realistic style.

**This is the intended MVP visual language, not a placeholder pending a future rigger.** Don't design against ever revisiting it — a later art pass could still add skinning — but don't plan for that replacement either; no "keep it swappable" abstraction is warranted here. Revisit only if a playtest shows the motion fails readability at actual gameplay camera distance, or a later feature (e.g. a cinematic/close-up moment) needs deformation this rig can't provide.

## Key decision: procedural sine-driven locomotion, not keyframes

Because animation here is pure joint *rotation* (no scale/translate needed for a walk cycle), it is independent of a given character's proportions. That lets us separate two concerns cleanly:

- **Shape** — `CharacterAppearance` decides bone lengths and mesh sizes (how tall, how broad).
- **Motion** — a small `ProceduralLocomotion` script decides joint angles per frame from a phase accumulator, opposite-phase for the opposing limb, knee angle rectified so it only bends one way, arm swing counter to legs.

No animation clips, no `AnimationPlayer` curves to hand-tune per character. Walk vs. run vs. idle are the same function with different amplitude/frequency, faded by current speed.

Three refinements over the naive version, settled here rather than discovered during tuning:

- **Phase advances by distance travelled, not raw time.** `phase += horizontal_speed * delta * stride_rate` rather than `phase += delta * some_constant`. Tying frequency directly to speed without this would make a character's feet slide or "moonwalk" relative to the ground, and differently-proportioned characters (short legs vs. tall) would need different constants to look right at the same speed.
- **Every joint stores a rest rotation; locomotion applies an additive delta on top of it each frame** (`joint.rotation = rest_rotation + locomotion_delta`), never `joint.rotate_x(...)` accumulated frame over frame. Incrementing in place drifts and blocks layering a future gesture/pose on top of locomotion.
- **The animator receives horizontal velocity and a grounded flag, not just a scalar speed.** A character that jumps, is falling, or is shoved needs to blend out of the walk/run cycle rather than keep striding in the air. Airborne pose (a simple fixed pose, not a new cycle) is in scope for the locomotion step below; a full jump/land animation is not.

## Rig conventions

Left implicit, these are exactly the kind of thing that quietly diverges between the builder script and the animator script and shows up as popping or mirrored limbs. Settling them now:

- Every animated joint is a pivot `Node3D` at the joint's rotation center; the visible primitive mesh is a child of that pivot, offset so it extends away from the pivot in the limb's rest direction (mirrors how `CollisionShape3D`/`BodyMesh` are already offset from the `Responder` root in `Responder.tscn`).
- Rest pose: standing, arms at sides, facing `-Z` (Godot's forward), consistent with the existing `Responder` root's forward convention.
- Left/right is from the character's own perspective, not the camera's (`HandL` is stage-left when facing `-Z`).
- The builder script owns direct references to the joints it creates (e.g. a `Dictionary` or typed fields) rather than the locomotion script re-finding them by `get_node()` path — path-based lookup is fragile the moment the hierarchy is tweaked.
- Joint rotation is clamped per joint (e.g. knee only bends one direction, within a plausible range) so a bad locomotion parameter can't visibly invert a limb.

## `CharacterAppearance` resource (data model)

A `Resource` (`.tres`), following the project's existing preference for small data-driven resources (see `GearDefinition` in [architecture.md](architecture.md#regions-and-progression)). Every continuous field is clamped at the resource level (not just by convention in whatever UI eventually sets it), and `generator_version` exists specifically so a seed reproduces the same shape later even if the generation code changes.

| Field | Type | Effect |
| --- | --- | --- |
| `height_m` | float, clamped e.g. 1.5–2.0 | Overall rig *mesh* scale only for this pass — see MVP decisions below. Reference: current Responder capsule is 1.75 m ([goxel-workflow.md](goxel-workflow.md#quick-size-reference)); default here should match. |
| `build` | float 0–1 | Torso/limb girth — narrow to stocky. |
| `shoulder_hip_ratio` | float, clamped to a plausible range | Continuous silhouette slider rather than a binary gender switch; presets can clamp to typical sub-ranges but the field itself stays continuous. |
| `head_scale` | float, clamped | Head size relative to body — also a cheap way to get a distinct "kid/NPC" silhouette later. |
| `skin_color` | Color | — |
| `hair_style` | enum (`none`, `short`, `bun`) | Small fixed set of blocky attachments, not free-form hair geometry. Purely cosmetic — see equipment-vs-cosmetic rule below. |
| `hair_color` | Color | — |
| `head_equipment` | enum (`none`, `cap`, `rescue_helmet`, …), separate from `hair_style` | Gameplay-visible headwear. When set to anything but `none`, it renders in place of/over hair at the head socket and takes visual precedence over `hair_style` — cosmetics don't need to coordinate with what equipment is worn. |
| `clothing_primary_color` / `clothing_secondary_color` | Color | Cosmetic uniform/clothing colors only. Deliberately **not** the local/remote disambiguation color — see below. |
| `variant_seed` | int | Deterministic jitter within the above ranges, for generating a crowd of distinct casualties/NPCs without hand-authoring each one. **Host/internal only for this milestone** — no player-facing customization UI; used to vary presets and future NPC casualties, not exposed as a "create your responder" screen. |
| `generator_version` | int | Bumped when builder logic changes shape in a way that would make an old seed produce a different result. Not player-facing. |

**Cosmetic appearance vs. gameplay-visible equipment is a hard split.** `CharacterAppearance` (hair, skin, clothing color, build) is purely cosmetic and carries no gameplay meaning. `head_equipment` — and any future slot like it — is an explicit attachment layer that can communicate state (e.g. wearing a rescue helmet) without making cosmetics semantic or ambiguous over the network. Keep that boundary when adding future slots rather than overloading a cosmetic field to also mean something mechanically.

**Identity color stays a separate layer.** `responder.gd` currently uses blue-vs-orange to disambiguate local vs. remote player, which is a readability/gameplay signal, not a cosmetic choice. If `clothing_primary_color` became player-customizable, it could collide with that signal. Keep local/remote disambiguation as a rendering step applied on top of (or clearly independent from) `CharacterAppearance` — e.g. a thin accent/outline — rather than folding it into the customizable clothing fields.

### MVP scope decision: appearance is visual-only

For this pass, `CharacterAppearance` changes what the model *looks like* and nothing else. Collision shape, camera height/position, movement speed, and interaction reach stay exactly as they are today regardless of `height_m` or `build`. A tall and a short character occupy the same capsule and move at the same speed. This avoids a fairness/hitbox question that doesn't need answering yet, and keeps this pass a rendering change, not a movement-tuning one. Revisit only if a real design need for it shows up.

## Integration points

- New scene, e.g. `scenes/character/CharacterModel.tscn`, with `scripts/character/character_builder.gd` (builds the joint hierarchy + meshes from a `CharacterAppearance`) and `scripts/character/procedural_locomotion.gd` (poses joints per frame from horizontal velocity + grounded state). The builder runs at `_ready()` at minimum; an `@tool`-annotated editor preview is a nice-to-have on top of that runtime path, not something the runtime depends on — keeps editor-node ownership/cleanup out of the critical path.
- `Responder.tscn` swaps `BodyMesh` for an instance of `CharacterModel.tscn`. It needs to expose named attachment sockets — at least `HeadSocket`, `HipSocket`/`Toolbelt` anchor, `HandL`, `HandR` — since the existing toolbelt, name tag, and camera pivot are currently positioned against the capsule's fixed geometry and will need to reattach to the new model's actual proportions rather than being untouched by the swap.
- `responder.gd` feeds the model horizontal velocity and grounded state each physics frame instead of owning animation logic itself.
- Casualty/hiker reuse: same `CharacterModel.tscn` + a limbs-at-rest or lying-down pose, once that content is scoped — not part of this pass's build order, just why the builder shouldn't be player-specific from the start.

### Network payload vs. authoring resource

`CharacterAppearance` as a `.tres` `Resource` is the right *authoring* shape, but a `Resource` reference is not a reasonable thing to hand to Godot's RPC layer as the wire format. Keep them distinct:

- **Wire format**: a small versioned dictionary/packed value set (the same fields, as primitives) sent host → clients once at spawn, matching the trust model already used for movement state in `responder.gd` — the host is authoritative for spawn data, clients don't invent their own. Handle late joiners (send current roster's appearance on join) and respawns (resend, don't assume the old instance persists) explicitly rather than as an afterthought.
- **Local reconstruction**: each peer builds its own local `CharacterAppearance` resource instance from the received payload and hands it to `character_builder.gd`. Determinism only needs to hold for a single peer's own render of a given payload — peers don't need bit-identical procedural generation of each other's *code*, just the same payload in, same shape out.
- **Locomotion is not synchronized over the network at all.** Each peer runs `procedural_locomotion.gd` locally off the position/velocity it already has (its own input locally, the replicated/interpolated value for the remote player). This means remote leg-phase is an approximation, not frame-exact with what the remote player's own client shows — accepted deliberately, consistent with the project's existing stance that "it is acceptable to use a simple fixed send rate and interpolation for this prototype; do not attempt prediction/reconciliation unless a real playtest proves it necessary" ([technical-scaffold-requirements.md](technical-scaffold-requirements.md#5-two-player-replication)). Revisit only if playtesting shows the approximation actually reads as wrong, not preemptively.

## Suggested phased build order

1. **Static rig, no animation.** Builder script assembles the joint hierarchy and meshes from one hardcoded `CharacterAppearance`; replaces the capsule; reattach toolbelt/name-tag/camera to the new sockets. Verify silhouette and scale at normal camera distance, matching the [asset checklist](assets-and-models.md#asset-checklist).
2. **Parameter variation.** Wire up 2–3 preset `CharacterAppearance` resources (e.g., visibly different heights/builds/colors) to confirm the generation logic actually responds to the data model, not just one hardcoded shape, and that clamps hold at the extremes.
3. **Idle + walk + run + airborne.** `ProceduralLocomotion` driven by horizontal velocity and grounded state, using distance-based phase and rest-pose-plus-delta rotation as described above. Tune amplitude/frequency by eye.
4. **Multiplayer spawn sync.** Send the wire-format payload once per spawn, including late joiners and respawns; confirm both peers render the same shape for a given player. Confirm the identity-color layer still disambiguates local/remote independent of any clothing color chosen.
5. **Performance check-in.** Confirm frame time is unaffected with the two-player MVP's expected on-screen character count before treating this as done; note if mesh/material instances should be cached/shared across characters rather than reallocated per spawn.

Casualty/NPC reuse, gestures beyond walk/run, and any customization UI are explicitly out of scope until this foundation is proven, matching the project's general habit of not building the general framework before the first concrete use ([architecture.md](architecture.md#guiding-decision)).

## Resolved decisions

Settled explicitly rather than left implicit, since they shape the data model and build order above:

- **No player-facing `variant_seed`/customization UI in this milestone.** It stays host-assigned/internal, driving presets and future NPC variation. Preserves the non-goal of skipping a general customization UI while keeping the exact data path a future UI would need.
- **Segmented rigid motion is the intended MVP look, not a stopgap.** No "keep it swappable for skinning later" abstraction; see the note under the rig decision above.
- **Equipment is a separate layer from cosmetics.** `head_equipment` communicates gameplay state and visually overrides `hair_style`; hair/skin/clothing color stay purely cosmetic. See the data model note above.

## Acceptance criteria for the first playable milestone

Observable, not just "code exists":

- [ ] Three deliberately different `CharacterAppearance` presets are readable at normal gameplay camera distance and stay inside the existing (unchanged) collision silhouette.
- [ ] Idle, walk, run, stop, and airborne transitions show no rotation drift, popping, or a joint stuck at an implausible angle.
- [ ] Two connected peers, plus one peer that joins after spawn, all render the same appearance for a given player.
- [ ] Toolbelt items, name tag, and camera stay correctly positioned across all approved appearance presets.
- [ ] Local vs. remote identity is still visually unambiguous regardless of chosen clothing colors.
- [ ] Frame time holds at the two-player MVP's expected character count.

## Definition of done for this spec

- [x] Rig topology (joint list above) reviewed and agreed, including what's deliberately excluded (fingers, spine segments, foot roll).
- [x] `CharacterAppearance` field list reviewed, including the equipment-vs-cosmetic split.
- [x] Phased build order agreed, with an explicit performance check-in before calling it done.
- [x] Open questions resolved — see Resolved decisions above.
