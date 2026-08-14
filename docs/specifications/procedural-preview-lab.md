# Procedural Preview Lab

**Status: proposed.** Formalizes and extends the dev harness at [scripts/dev/character_preview.gd](../../scripts/dev/character_preview.gd) into a reusable system for all procedural visuals, not just characters. Nothing here changes [procedural-character-spec.md](../procedural-character-spec.md)'s rig/locomotion architecture; the "character animation contract" section below refactors *how* locomotion is driven for preview purposes, not the walk-cycle math itself.

## Purpose

Provide a fast, repeatable development environment for procedural visuals. It must support hands-on experimentation and reliable batch captures without connecting generators to gameplay scenes.

The current `character_preview` scene becomes the first subject-specific implementation. Trees, props, terrain chunks, and future generators reuse the same preview stage and capture workflow.

## Core design

```text
Preview Lab
├── Shared preview stage
│   ├── Camera, lighting, ground, grid, backdrop
│   ├── Turntable and framing
│   └── Screenshot / metadata capture
├── Subject adapter
│   ├── CharacterPreviewAdapter
│   └── Future TreePreviewAdapter
├── Interactive lab scene
│   ├── Parameter controls
│   ├── Scenario / pose controls
│   └── Save-as / copy payload tools
└── Batch runner
    ├── Preview-case resource
    ├── Deterministic capture
    └── Visual-regression output
```

Keep the generic stage reusable, but do not prematurely make every control generic. Characters should have a purpose-built panel; trees can later expose their own seed, species, season, wind, and LOD controls.

## Modes

### 1. Interactive Lab

A debug-only scene for visually editing one or more subjects.

Character controls:

- Load an appearance resource; duplicate it into an unsaved working copy before editing.
- Reset, randomize seed, and save as a new `.tres`.
- Edit all appearance fields: height, build, proportions, skin/hair, clothing, accent, head equipment, and identity color.
- Select pose: rest, idle, walk, run, airborne, and later gesture.
- Control exact normalized gait phase, speed, grounded state, and playback/pause.
- Show one character, a comparison row, or a baseline-versus-working-copy pair.
- Camera: orbit, front/side/back views, orthographic toggle, fit-to-subject, and turntable.
- Stage: lighting preset, ground/grid toggle, silhouette mode, and neutral background.

The editable working copy prevents accidental mutation of source appearance resources during experiments.

### 2. Batch Capture Runner

Retain the existing command-line workflow for screenshots, but drive it through named preview cases rather than loose scene exports alone.

A `PreviewCase` resource should define:

- Subject type and source resource(s)
- Camera/stage preset
- Pose, exact phase, speed, and grounded state
- View: front, side, rear, or turntable frame
- Output path
- Generator/version metadata

Example cases:

- `responder_default_front`
- `responder_default_walk_contact`
- `responder_tall_helmet_side`
- `casualty_short_airborne`
- `tree_pine_wind_frame_03`

Each capture writes a PNG plus small JSON metadata containing the payload, generator version, case name, pose, camera preset, and capture timestamp.

## Character animation contract

The preview must be able to request an exact pose. Do not rely on "wait eight frames and capture whatever phase happened" — the mechanism `character_preview.gd`'s `capture_delay_frames` currently uses.

Refactor locomotion around a pure pose evaluator:

- Gameplay owns phase accumulation from travelled distance.
- The evaluator applies a supplied phase, speed, and grounded state to the rig.
- The preview supplies phase directly with a scrubber or fixed capture value.

This makes contact-pose comparisons, screenshots, and visual regressions reproducible while preserving the existing runtime animation behavior described in [Key decision: procedural sine-driven locomotion](../procedural-character-spec.md#key-decision-procedural-sine-driven-locomotion-not-keyframes).

## Shared subject-adapter contract

Each procedural subject supplies an adapter that can:

- Build or rebuild its preview instance from a resource/payload.
- Return a useful visual bounds estimate for camera framing.
- Apply subject-specific preview state.
- Describe supported views and capture cases.
- Return metadata needed to reproduce the output.

The preview stage owns camera, lighting, layout, screenshot capture, and metadata output. Subject adapters own generator-specific controls and evaluation.

## Preview presets

Ship these shared stage presets first:

- **Neutral Review** — grey background, ground plane, directional key light, soft ambient fill, shadows.
- **Silhouette** — flat single-color material and high-contrast background for proportion checks.
- **Gameplay Camera** — actual third-person camera distance and lighting approximation.
- **Asset Sheet** — orthographic front/side/rear layout for comparison captures.

The gameplay-camera preset is the acceptance view; the neutral and silhouette presets make shape problems easier to diagnose.

## Visual regression workflow

Visual regression is a developer aid, not a pixel-perfect gate initially.

1. Capture approved preview cases as baselines.
2. Re-run all cases after generator changes.
3. Produce a comparison sheet or tolerant image diff.
4. Review meaningful silhouette, palette, lighting, or framing changes.
5. Update baselines only when the visual change is intentional.

Keep rendering settings fixed for capture cases. Avoid random seeds, real-time clocks, free-running animation, and dynamic lighting in regression captures.

## Immediate improvements to the current harness

These apply to [scripts/dev/character_preview.gd](../../scripts/dev/character_preview.gd) before any broader refactor:

- Set `model.appearance` before adding the model to the scene tree, then let `CharacterModel._ready()` build it once. The current order can build the default appearance and then immediately rebuild the requested one.
- Replace `capture_delay_frames` as the primary pose-control mechanism with explicit pose/phase setup plus a short render-settle delay.
- Add front, side, and rear capture modes before adding more UI.
- Add a ground grid, fit-to-subject framing, and silhouette mode.
- Load valid appearances first, then calculate row positions from the valid list so a skipped resource does not leave uneven spacing.
- Treat multi-character layouts as comparison cases, separate from a single-subject inspection mode.

## Build order

1. Stabilize the existing batch harness: deterministic pose phase, stage presets, camera views, metadata sidecar.
2. Add the interactive Character Lab: working copy, parameter panel, pose scrubber, save-as, and comparison mode.
3. Add preview cases and baseline captures for the responder appearances.
4. Extract the shared stage and adapter contract.
5. Add a tree adapter only once the tree generator exists.

## Done criteria

- A developer can adjust a responder's parameters and pose live without entering gameplay.
- A developer can save a new appearance resource without overwriting the source by accident.
- The same named capture case produces the same subject, view, and animation pose on repeat runs.
- Front, side, rear, gameplay-camera, and silhouette views are available.
- A batch run can capture all approved character cases and record reproduction metadata.
- Adding a future tree preview requires a subject adapter, not a second bespoke screenshot system.

## Appendix: Character Pose Library

### Purpose

Define a small, scenario-driven pose set for responders and casualties. Poses use the existing segmented rigid rig: rest rotations plus named joint deltas, with no skinning, IK, or general animation-authoring system (see [Non-goals](../procedural-character-spec.md#non-goals-for-this-pass)).

"Prone" means lying face-down; "supine" means lying face-up.

### Pose categories

| Category | Examples | Implementation |
| --- | --- | --- |
| Locomotion | idle, walk, run, jump/fall | Procedural and phase-driven |
| Standing interaction | alert, crouch, kneel, reach | Static joint pose with optional blend |
| Grounded casualty | seated, prone, supine, side-lying | Static root orientation plus joint pose |
| Advanced movement | crawl, carry, drag | Later; needs dedicated gameplay and contact rules |

### Initial pose set

#### Standing / locomotion

- `standing_neutral` — default relaxed pose.
- `standing_alert` — shoulders up, head forward, arms slightly ready; suitable for a responder near an incident.
- `idle_scan` — low-amplitude head/torso variation layered over standing.
- `walk` / `run` — existing procedural locomotion.
- `jump_takeoff` — brief crouch and arm preparation.
- `airborne` — legs slightly tucked or extended; driven by grounded state.
- `landing` — short knee bend, then blend to standing or locomotion.

#### Interaction poses

- `crouch_inspect` — bent knees and hips, forward torso tilt. Reserve player collision resizing for a later movement feature.
- `kneel_one_knee` — primary treatment/assessment pose; one knee down, one foot planted.
- `kneel_both` — stable low interaction pose for prolonged tasks.
- `reach_down` — standing or kneeling overlay used while interacting with equipment or a casualty.
- `point` / `signal` — later gesture overlay; useful for multiplayer readability.

#### Casualty / world-state poses

- `sit_ground` — back unsupported, legs bent or extended.
- `sit_supported` — intended for a rock, tree, vehicle, or wall; requires a placed support anchor.
- `supine` — lying on the back, limbs naturally offset.
- `prone` — lying face-down, arms close to the body or one arm extended.
- `side_lying` — one shoulder down, upper knee bent, arms arranged for a stable readable silhouette.
- `downed_seated` — slumped seated variation for fatigue or minor injury.
- `downed_prone` — a more visibly incapacitated variant of prone.

### Priority

**Ship with character foundation**

- `standing_neutral`
- `idle_scan`
- `walk`
- `run`
- `airborne`

**First rescue-scenario pass**

- `kneel_one_knee`
- `reach_down`
- `sit_ground`
- `supine`
- `prone`
- `side_lying`

**Defer**

- `crouch_inspect` as a player movement mechanic
- `crawl`
- carrying, dragging, stretcher handling, ladders, climbing, and terrain-adaptive poses

Crawling should not be added as a cosmetic cycle alone: it needs a low collision profile, movement rules, and ground-contact handling to avoid looking like a standing character sliding sideways.

### Pose data contract

A `CharacterPose` resource should contain:

- `id` — stable identifier, such as `kneel_one_knee`
- `category` — locomotion, interaction, or grounded
- `joint_deltas` — rotation deltas relative to the rig rest pose
- `root_offset` and `root_rotation` — required for seated/lying poses
- `collision_profile` — standing, low, disabled, or not applicable
- `camera_profile` — default, crouched, or casualty inspection
- `interaction_sockets` — optional hand/head/hip socket expectations
- `blend_in` and `blend_out` durations

This is a focused pose library, not a replacement for the project's intentional non-goal of a general animation pipeline.

### Root and collision rules

- Standing, walking, and running keep the character root upright.
- Jump motion is owned by the character controller; the pose only describes body shape.
- A player may not visually lie down while retaining a standing collider.
- Casualties may use a rotated model root with no active character collider, anchored to the world by a placed `PoseAnchor`.
- Seated and lying casualties should be placed against a known surface or anchor; no IK or slope fitting is required for this pass.

### Layering

Apply pose layers in this order:

```text
Rest pose
→ posture pose (standing / kneeling / lying)
→ locomotion delta, if permitted
→ interaction or gesture overlay
```

Grounded casualty poses do not accept locomotion. Standing interaction poses may accept only a small idle overlay.

### Preview Lab cases

Add these named preview cases:

- `responder_standing_front`
- `responder_walk_contact_left`
- `responder_airborne`
- `responder_kneel_one_knee`
- `casualty_sit_ground`
- `casualty_supine`
- `casualty_prone`
- `casualty_side_lying`

Each should be reviewable from front, side, and gameplay camera views before being used in a scenario.
