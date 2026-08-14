# Visual Direction — Island SAR North Star

## Intent

The world should tell a rescue story at a glance: a bright rescue vehicle or responder against natural terrain, strong landmarks, and, in later regions, dramatic water/coastal scenery. The first region is an inland island. The style is original voxel-low-poly, inspired by the *principles* of clear silhouette, layered scenery, and readable rescue action—not by copying any one reference image, livery, vehicle, or location.

## Scene composition

Build the first inland-island scenes in three layers:

```text
Foreground: player, casualty, rescue tool, immediate hazard
Midground: playable trail, meadow/forest/wetland edge, lake shore, trees, rescue centre
Backdrop: mountains, lookout, distant village/health centre, cloud bank
```

- **Foreground** must make the current rescue interaction readable.
- **Midground** contains traversable terrain, search clues, and routes.
- **Backdrop** establishes a larger protected district and hints at future locations without requiring an open world or distant playable geometry.

## Terrain, water, and POIs

- Use static, authored faceted terrain with clear elevation steps: meadow, forest floor, wetland edge, low trail, lake shore, wooded slope, cliff, and high lookout where useful. Mountains make the edge of the playable district legible and natural. The terrain is not required to be voxel-based.
- Goxel models provide the voxel-low-poly layer placed on the terrain: trees, rocks, terrain dressing, structures, vehicles, equipment, and landmark shapes. Assemble these from reusable chunks; do not export one enormous environment model.
- Start with hand-placed Goxel tree and rock variants in the playable routes. A simple, deterministic scatter tool can be explored later if placing large forests becomes tedious and it preserves designed sightlines, clues, collisions, and performance. Do not make procedural generation a prerequisite for the first region.
- The initial water feature is a small lake with a visible shore and a non-swimmable boundary. A simple Godot water material/shader can provide gentle movement, reflections or colour variation, and shoreline foam without adding water gameplay.
- Place a small island in the lake as a visible near-term goal. It may become a tiny swimming-or-boat test area after the on-foot rescue loop works; it does not need to be accessible at first.
- Start with 5–7 memorable POIs in the first region: rescue centre/helipad, trailhead, lake island, wetland boardwalk or crossing, high lookout, village facade, and health-centre landmark.

## First structures to sketch

Keep the first structures small, useful, and mostly exterior-facing. They create routes and recognisable landmarks without committing the project to a building-interior system.

| Structure | First purpose | Prototype shape |
| --- | --- | --- |
| One-room wilderness cabin | Later shelter / missing-hiker scenario | A 6 m × 5 m cabin with one clear door, porch or woodpile, and a simple interior reserved for a later mission. |
| Rescue centre | Spawn, briefing, equipment dispenser, and return point | A 14 m × 10 m exterior with a visible entrance, vehicle apron, signage, and a few equipment props. No explorable office complex. |
| Helipad | Future helicopter landmark and later launch point | A 16 m marked pad beside the rescue centre; it can be empty until flight gameplay is ready. |
| Trailhead kiosk or shed | Route choice and search briefing landmark | A small map board, shelter, bin, or gear locker at the start of a trail. |
| Lookout platform | High-level navigation and search vantage point | A simple raised timber/metal platform with a strong silhouette, not a complex tower interior. |
| Village facades | Distant life and possible later mission location | A small cluster of exterior-only homes, shop, or dock-side forms beyond the first rescue route. |
| Health-centre exterior | Destination landmark and later handover location | A compact, clearly signed building visible from the village or road; begin as an exterior only. |

Use the shared [Goxel size reference](goxel-workflow.md#quick-size-reference) so these structures and later vehicles sit naturally on the same terrain. A building interior is added only when its rescue interaction cannot be delivered outdoors.

## Color and readability

- Natural terrain: muted greens, blue-greys, sandy or rocky warm neutrals.
- Rescue elements: a consistently high-visibility original color scheme, such as rescue orange with a contrasting dark/neutral secondary color.
- Hazards and interactables need their own readable color and silhouette language. Do not rely on a waypoint alone to make a player notice them.
- Use voxel blocks and faceted planes deliberately; a small palette and broad lighting shapes are more important than surface detail.

## Atmosphere

Each region needs a quiet ambient bed before it needs more content:

- Wind through trees or around cliffs.
- Birds, insects, a creek, and subtle forest movement in the inland island.
- Waves, shore wash, and distant gulls in later coastal zones.
- Distant village, harbor, or rescue-station activity when appropriate.
- Clouds, sunlight, mist, and light weather variation used carefully so clues and players remain visible.

Ambient sound and VFX must never hide important radio, interaction, casualty, fire, or vehicle cues.

## HUD language

The HUD should give situational awareness without turning the rescue into a combat game:

- Objective and optional mission time stay visible but compact.
- A compass or small minimap supports orientation, while fog of war hides dynamic incident information until players discover it.
- Equipment prompts appear only when relevant and identify the current tool clearly.
- Casualty condition/extraction information appears only after contact.
- A responder-condition or stamina display is preferable to a prominent combat-health bar.

## Future aerial-rescue tableau

A later specialist rescue can present a pilot, rescue diver, helicopter, hoist, casualty, and boat/shore team in one understandable scene. Build toward it in layers:

1. helicopter flight and landing;
2. a remote search or extraction that benefits from flight;
3. a small scripted hoist zone with a pilot, diver, and casualty;
4. only later, broader water rescue and diver capabilities.

The pilot and rescue diver may be player roles or support NPC roles depending on what makes the two-player loop strongest. This decision is deliberately deferred; the initial on-foot rescue team remains the priority.
