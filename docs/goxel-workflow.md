# Goxel Workflow

## Purpose

Goxel is the primary art tool for the game's voxel-low-poly asset layer. It is the fast path for assets that need to read clearly in a third-person rescue game: terrain dressing, props, equipment, trees, rocks, signs, building exteriors, and early vehicle blockouts. The base terrain itself is static and faceted, authored separately in Godot or a terrain workflow.

## Scale calibration

Use this working scale throughout the prototype:

**1 Goxel voxel = 0.25 metres (25 cm). Four voxels = 1 Godot metre.**

Before making a large asset library, export a `4 × 4 × 4` voxel calibration cube from Goxel as OBJ and import it into a blank Godot scene. It should measure `1 × 1 × 1` Godot units. If Goxel's OBJ export needs an import-scale adjustment, make and record that adjustment once; do not compensate by sizing individual models differently.

Godot remains metric: **1 Godot unit = 1 metre**. Keep game models at their intended size instead of scaling their nodes in scenes.

## Quick size reference

Use these as proportions, not rigid architectural requirements. A readable silhouette matters more than exact realism.

| Asset | Approximate game size | Approximate Goxel size |
| --- | --- | --- |
| Responder | 1.75 m tall | 7 voxels tall |
| Standard door | 1 m × 2 m | 4 × 8 voxels |
| First-aid kit | 0.5 m × 0.3 m × 0.2 m | 2 × 1 × 1 voxels |
| Pine tree | 8–12 m tall | 32–48 voxels tall |
| One-room wilderness cabin | 6 m × 5 m × 3 m | 24 × 20 × 12 voxels |
| Rescue-centre exterior | 14 m × 10 m × 4.5 m | 56 × 40 × 18 voxels |
| Helipad | 16 m across | 64 voxels across |
| Small rescue helicopter, fuselage | 10–12 m long | 40–48 voxels long |
| Small rescue helicopter, rotor span | 10–12 m across | 40–48 voxels across |
| Rescue truck / all-terrain ambulance | 6 m × 2.25 m × 2.5 m | 24 × 9 × 10 voxels |

For models with moving pieces later, make the body and any door, rotor, wheel, or hoist part separate. The first exterior blockout can remain static.

## File handoff

```text
assets/models/source/prop_trail_sign.gox   # Editable Goxel source
assets/models/prop_trail_sign.obj          # Godot import source
assets/models/prop_trail_sign.mtl          # Keep if Goxel generated/uses it
```

Use the same base name for source and export. Do not edit the exported OBJ by hand; change the `.gox` file, export again, then verify the reimport in Godot.

## Model checklist

- Build for the third-person camera: silhouette first, tiny detail second.
- Keep interactive items easy to identify by shape and color.
- Put the model's base at the ground line where possible, so placement in Godot is predictable.
- Use simple Godot collision for solid props; do not assume an OBJ provides useful collision.
- Test every new asset in the Godot `ArtTest` scene before using it in an incident.

## Working limits

- Start with static models. Do not solve character animation, vehicle rigs, or animated equipment in the first Goxel slice.
- Make terrain dressing, road-side assets, and large structures from reusable chunks rather than one enormous exported model.
- Use Goxel for authored landmarks and dressing; gameplay-critical trails, search clues, collision, objectives, and lighting stay under Godot's control.

## First environment kit

Sketch these as small, reusable exterior-first models over the first few weeks:

1. `env_rock_small`
2. `env_pine_tree`
3. `prop_trail_sign`
4. `prop_response_kit`
5. `building_wilderness_cabin_exterior`
6. `building_rescue_center_exterior`
7. `poi_rescue_center_helipad`
8. `poi_lookout_platform`

The cabin can later become the first limited interior scenario; its first version should be a readable exterior with a doorway and a simple footprint. The rescue centre should begin as a compact exterior landmark, a spawn/loadout point, and a clearly marked helipad—rather than a detailed building. These assets are enough to validate the style, scale, importing, collision, and third-person readability before producing a larger kit.
