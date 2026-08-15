# Character Appearance Visual Design

**Status: design goals for the next CharacterModel/CharacterAppearance pass.** The rig, locomotion, and data-model architecture in [procedural-character-spec.md](procedural-character-spec.md) are settled and unaffected by this document. This is a follow-up visual pass on the same system, informed by design feedback on the first playable build.

## Purpose

The first pass proved the segmented-rig approach (see [Key decision: segmented rigid parts](procedural-character-spec.md#key-decision-segmented-rigid-parts-not-a-skinned-skeleton)) but reads as stacked rectangles rather than a deliberately designed responder: uniform proportions, two near-identical dark-blue clothing tones, a floating head, and a dead-straight rest pose. The problem is not that the model is too low-poly — it's that it's too uniform. This document captures the visual design goals for closing that gap, without changing the rig topology, locomotion, or `CharacterAppearance` wire format any more than necessary.

## Visual brief

> A chunky, readable outdoor rescue responder: broad helmet and shoulders, layered jacket over dark work trousers, substantial boots and gloves, with a high-visibility accent repeated across the chest, sleeves, and lower legs. Forms should be simple and faceted, but each body region must have a distinct silhouette or color break.

## Design goals

### 1. A rescue-worker silhouette, not an extruded capsule

Build the torso from a wider chest/jacket block and a slightly narrower waist/hip block, rather than the current single long box, with a visible belt or jacket-hem line at the seam between them.

**Why:** one deliberate silhouette break at the waist is what reads as "constructed garment" instead of "stretched box." This is the single highest-leverage change to the torso.

### 2. Separate the limbs from the body

Move the shoulder attach point slightly farther out from the torso centerline, make the sleeve (upper-arm mesh) chunkier than a bare limb, and give the wrist a distinct cuff/glove color break.

**Why:** the current upper arm and torso share both color and an unbroken silhouette edge at the shoulder, so the arm visually disappears into the torso even though it's a separate mesh. Motion in the walk cycle doesn't read for the same reason. A color and thickness break at the shoulder and wrist is what makes the limb visible as its own part, independent of how it's animated.

### 3. Three clothing value groups, not two dark blues

Today `CharacterAppearance` has two clothing colors (`clothing_primary_color`, `clothing_secondary_color`), both used at similar dark values. Move to three distinct roles:

| Role | Typical value | Placement |
| --- | --- | --- |
| Jacket | Blue | Chest/torso block |
| Trousers/boots | Charcoal | Waist block, shins, feet |
| Safety accent | Warm yellow, cream, or orange | Repeated: chest, sleeves, lower legs |

**Why:** it's the *repetition* of a third accent color across three separate body regions — not the color choice itself — that reads as a designed uniform rather than a random assortment of parts. This is a data-model change: `CharacterAppearance` needs a third color field (see [Data-model impact](#data-model-impact) below).

### 4. A visible neck and a stronger helmet silhouette

Give the neck joint a small visible mesh instead of the current zero-length pivot — the head currently looks detached from the torso. Build the rescue helmet as a low-segment faceted dome with a brim (and optionally side ear pieces), not a box stacked on a box.

**Why:** the neck gap and the box-on-box helmet are the two head-region details most responsible for the "assembled from generic parts" read, and both are cheap, geometry-light fixes consistent with the low-poly voxel language.

### 5. Give the idle stance some character

At rest: bend the elbows slightly rather than locking arms straight, hold the arms a little away from the torso (this also supports goal 2), stand the feet a touch wider than hip width, and angle the toes outward very slightly.

**Why:** the rest pose is on screen at least as much as the walk cycle, and a perfectly straight, symmetric mannequin pose reads as generated rather than posed. This only requires each joint to have a non-zero **rest rotation** — `procedural_locomotion.gd` already applies locomotion as a delta on top of whatever rest rotation the builder assigns (see [the rig-conventions note on rest rotation](procedural-character-spec.md#rig-conventions)), so this needs no locomotion changes, only different values for `_rest_rotations` at build time in `character_builder.gd`.

### 6. Light it like a 3D object (separate pass, sequenced after silhouette)

A directional key light, soft ambient fill, and contact shadows will make the faceted blocks feel intentional rather than flat. Do this only after the silhouette/color pass above — flat lighting is currently making an already-uniform shape look worse, but fixing lighting first would mask whether the silhouette work actually solved the problem.

## Non-goals for this pass

Explicitly out of scope, consistent with [the parent spec's non-goals](procedural-character-spec.md#non-goals-for-this-pass):

- Fingers, facial features, cloth/skin textures, or any additional small geometry beyond what's listed above. The brief is a small number of higher-leverage silhouette and color changes, not more detail.
- Lighting/shadow tuning (goal 6) — sequenced after the silhouette pass, not bundled with it.
- A player-facing color/style picker UI. Still host/internal only, per the parent spec's resolved decision on `variant_seed`.

## Data-model impact

Goal 3 needs a new color field on `CharacterAppearance` (e.g. `accent_color`). Since this changes what a given `variant_seed` produces, `generator_version` should be bumped when it ships, per the field's existing purpose ("bumped when builder logic changes shape in a way that would make an old seed produce a different result"). The three presets in `resources/character/` will need their accent color set explicitly at that time, not left to a default.

No other field, the rig topology, the joint hierarchy, the locomotion algorithm, or the network payload shape needs to change for this pass.

## Acceptance criteria for this pass

Observable, not just "code exists":

- [ ] At gameplay camera distance, the silhouette shows a visible break at the waist (jacket vs. trousers), not one continuous torso outline.
- [ ] Arms are visually distinguishable from the torso at rest — no color/silhouette merge at the shoulder.
- [ ] The safety accent color appears in at least three places (chest, sleeves, lower legs) and is visibly distinct from both clothing colors.
- [ ] The neck is visible; the head does not read as detached from the torso.
- [ ] The rescue helmet reads as helmet-shaped (dome + brim), not as a box stacked on a box.
- [ ] The idle rest pose shows slightly bent elbows, arms held off the torso, and a stance wider than hip width — checked across all three appearance presets.
- [ ] All three appearance presets ([appearance_compact_scout.tres](../resources/character/appearance_compact_scout.tres), [appearance_standard_responder.tres](../resources/character/appearance_standard_responder.tres), [appearance_tall_guide.tres](../resources/character/appearance_tall_guide.tres)) still build without error and remain visually distinct from each other.
