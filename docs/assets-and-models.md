# Asset and Model Conventions

These conventions keep voxel-low-poly models quick to make and safe to import. Goxel is the primary art tool. The conventions are a working agreement, not a reason to delay an asset that helps the next playable test.

## Visual direction

- Readable, stylized voxel-low-poly forms with clear silhouettes at third-person camera distance.
- Coastal rescue palette: natural terrain, high-visibility responder equipment, strong landmark colors.
- Favor chunky blocks, a restrained palette, and a few purposeful materials over tiny detail.
- Prioritize gameplay readability: trails, hazards, casualties, extraction points, and vehicles must stand out from the environment.

## File locations and names

Place source files in `assets/models/source/` and game-ready models in `assets/models/`. Do not delete source files merely because an exported model exists.

Use lowercase `snake_case` names:

```text
assets/models/source/vehicle_rescue_truck.gox
assets/models/vehicle_rescue_truck.obj
assets/models/prop_trail_sign.obj
assets/models/character_hiker_injured.obj
```

Useful prefixes:

- `character_` — player, casualty, responder
- `vehicle_` — ambulance, rescue truck, helicopter
- `building_` — exterior and any limited interior set
- `prop_` — standalone placement props
- `env_` — terrain dressing, rocks, trees, shoreline pieces
- `poi_` — distant landmarks such as lighthouse, village silhouette, dock, or rescue station
- `fx_` — visual-effect meshes

## Goxel source and export format

Keep editable Goxel files as `.gox` in `assets/models/source/`. Export static game models as `.obj` into `assets/models/` and keep their `.mtl` and texture files beside them when used. Godot can import OBJ models for the static assets that make up the first wilderness region.

Goxel is the default for static props, vegetation, rocks, trail signs, rescue equipment, building exteriors, and early vehicle blockouts. If a later asset needs a skeleton, animation, hierarchy, or richer material handling, choose a purpose-built follow-up workflow then; do not force that complexity into the first art slice.

See [Goxel workflow](goxel-workflow.md) for the repeatable handoff.

For each non-trivial model, verify:

- Scale and orientation look correct in a blank Godot test scene.
- Materials import as intended.
- Collision is added intentionally; it is not assumed to exist.
- The model has a readable silhouette at normal game camera distance.
- If it is static, it has no accidental animation or scene dependency.

## Coordinate, scale, and pivot conventions

- Use meters as the working scale: **1 Godot unit = 1 meter**.
- Use **1 Goxel voxel = 0.25 metres**: four voxels make one Godot metre. Validate this with a `4 × 4 × 4` voxel cube that imports as `1 × 1 × 1` Godot units before bulk production.
- Export with transforms applied where appropriate; avoid mysterious inherited scale.
- Place a prop's pivot at its ground contact point. Place a vehicle's pivot around its practical center; keep its forward direction consistent within the team.
- Treat the Godot import as the source of truth: test a sample early and lock the chosen forward-axis convention in the first model handoff.

See [Goxel workflow](goxel-workflow.md#quick-size-reference) for shared character, vehicle, helicopter, cabin, rescue-centre, and helipad dimensions.

## Polygon and texture guidance

There is no strict budget during the first slice. Keep meshes economical and favor silhouette over hidden detail. Use one to a few materials per ordinary prop. Avoid 4K textures by default; a small palette, vertex colors, or compact textures will often suit the style better.

Make collision separately and simply when needed: boxes, capsules, convex shapes, or a deliberately simple static mesh. Do not use the visible high-detail mesh as collision by habit.

## Character and vehicle handoff

For playable characters, casualties, and vehicles, include a short note with:

- intended role and rough real-world scale;
- whether the current Goxel export is static or needs a later animation workflow;
- material slots and color variants;
- collision or interaction points needed;
- source application/version and license status.

Vehicles have no interior requirement. Build clean exterior shapes first; include only doors, lights, stretchers, or equipment that the external gameplay camera can meaningfully show.

## Asset checklist

Before a model is considered ready:

- [ ] Source and export are named and stored consistently.
- [ ] It imports in Godot without visible scale/orientation surprises.
- [ ] It has intended material(s) and collision, if it needs collision.
- [ ] It is visible and legible from third-person play distance.
- [ ] Its author/source and license are recorded in the third-party asset register.
