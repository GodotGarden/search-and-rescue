# Initial Specification — Island Search & Rescue

## Purpose

Create a rapid-prototype, low-poly third-person **two-player co-op** game about civilian search-and-rescue across compact island regions. Players respond to small emergencies together in approachable, readable spaces rather than operating a hard simulation or traversing an open world.

The prototype must answer one question: **is it satisfying for two people to receive a call, travel into the landscape, search, help someone, and bring the incident to a close together?**

The project starts in GDScript and targets modern desktop systems. Godot's Forward+ renderer is the intended visual baseline for the wilderness environments.

## Player fantasy

You and a co-responder are capable local rescuers. You read the landscape, split up or stay together, find people in trouble, use simple rescue tools, and make the scene safe. The tone can be earnest and adventurous, not graphic or grim.

## Core rescue loop

```text
Receive incident → prepare/load out → travel/search → locate casualty or hazard
→ select and use the relevant equipment → transport or resolve
→ return/report complete
```

Every prototype incident should use this loop, though individual steps may be abbreviated. Co-op should create practical choices: search separately, regroup when a casualty is located, decide which kit to bring, and share the visible result. A stranded hiker can be escorted to an extraction point; a small brush fire can be extinguished and then reported resolved.

## Campaign and level structure

The game is a collection of bounded, authored rescue regions—not one seamless open map. Think of a focused level with its own terrain, points of interest, callouts, and small sense of progression.

- **Rescue station / home base:** a modest hub for accepting callouts, changing basic loadout at an equipment dispenser, reviewing unlocked gear or vehicles, and launching a selected region. It can initially be a simple scene or UI, not a large explorable building.
- **Region / level:** one self-contained play space such as a small island, coast, woodland reserve, or mountain valley. It contains a few landmarks, incident areas, and its own local tasks.
- **First region:** an inland island focused on trails, mountains, forest, wetlands, and on-foot search. A central lake and small lake island make later swimming/boating feel like a natural new capability, rather than a separate game mode. Coastal and aerial-rescue regions come later.
- **Incident:** a single rescue scenario inside a region, with clear setup and completion criteria.
- **Campaign progression:** completing incidents can unlock equipment, vehicles, and eventually new regions. This should create fresh options, not prevent the team from testing core rescue gameplay.

Early progression should be light and transparent. Example sequence: basic on-foot kit → flashlight / better search tools → ground rescue vehicle → helicopter access → new, purpose-built region. The first prototype needs only a placeholder completion/unlock screen; a save system is not required before the rescue loop is proven.

## First playable vertical slice

### Scenario: lost / injured hiker

- One player hosts a session and one other player joins it, on the same local network for the first build.
- Both players spawn at the rescue station, can see each other move, and receive the same callout and objective state.
- A dispatch board or simple UI presents one wilderness callout.
- The host accepts it and both players receive a search area and light guidance.
- The players travel on foot in third person through an inland woodland space.
- Either player can find an NPC casualty using environmental clues, a search radius, or both; the discovery becomes visible to both.
- Either player can interact to assess and help the casualty; the shared casualty state updates for both.
- The players escort or carry the casualty to a nearby marked extraction point.
- The game acknowledges success for both players and returns them to a ready state.

This is the required first success state. Dialogue, scoring, complex medical treatment, weather systems, internet matchmaking, and fail states are optional until the shared loop is fun and reliable.

## Planned gameplay

### Player

- Third-person locomotion: walk, run, turn, jump or step over small obstacles.
- Camera that stays readable near terrain, trees, and buildings.
- Contextual interaction prompt and a simple action animation or progress indicator.
- Basic tools later: flashlight, map, compass, binoculars, glow stick, extinguisher, rope, rescue carry/escort, and mission-relevant protective clothing.

### HUD and situational awareness

- Keep the standard HUD small: current objective, a contextual interaction prompt, and the currently selected equipment.
- A compass or small minimap may help orientation, but must not reveal undiscovered casualties, hazards, or search clues.
- Show a casualty panel only when a casualty has been found, assessed, or is being extracted.
- Use a responder-condition or stamina indicator where useful; avoid a combat-style health-bar focus.

### Rescue interaction and NPCs

- Players are the rescue team. NPCs are usually casualties, hazards/creatures, or supporting roles such as dispatch and medical-center staff.
- Equipment interactions are arcade-like: identify the relevant tool, select it, interact, and see a clear outcome or next objective.
- First-aid and rescue items are gameplay categories, not detailed clinical simulations. The game does not teach, grade, or depict real medical procedures.
- Later equipment may include a first-aid or trauma kit, defibrillator, stretcher, oxygen support, exposure blanket, flares, or vehicle-specific supplies. Each should create a gameplay decision, not a procedural mini-game.
- A completed interaction stabilizes, marks ready for extraction, controls a hazard, or reveals the next step; it does not replace the need to transport or hand over a casualty.

### World

- Compact low-poly rescue regions with a few purposeful points of interest. The first inland island uses a rescue centre and helipad, trailhead, mountains, meadow, forest, wetland, lake shore, a small lake island, road, lookout, village, health-centre landmark, and extraction point.
- Mountains and non-traversable terrain form the natural boundary of the first map. They should make the district feel larger without requiring an open world or invisible walls across ordinary trails.
- Outdoor-first design. Buildings are facades by default.
- A limited interior is allowed only when it creates a distinct rescue task, such as locating a casualty or reaching a contained fire.
- Clear silhouettes, paths, and landmarks that support search gameplay without excessive UI guidance.
- Build each region in layers: a readable playable foreground, a midground of terrain and points of interest, and a distant backdrop that establishes the wider rescue district.
- Use static, authored faceted terrain with clear playable slopes, cliffs, creek beds, and elevation layers. Goxel supplies the voxel-low-poly buildings, trees, rocks, vehicles, equipment, and other set dressing placed on that terrain.
- Water is a separate Godot shader/material system rather than a Goxel export. The initial lake is a visible, non-swimmable boundary with clear shore treatment; it does not need swimming physics for the first rescue slice.
- After the on-foot loop is working, the small lake island is the contained test bed for a swimming or small-boat capability. The team should test one access method at a time before building water rescues around it.
- Village and health-centre exteriors can begin as simple landmarks or facades. Later coastal regions can use memorable POIs such as a lighthouse, boat launch, headland, beach, and mountain trail. Distant POIs can foreshadow later mission locations without being enterable yet.
- Environmental ambience—wind, water, birds, trees, distant activity, and changing cloud cover—should make a scene feel alive without obscuring incident clues.
- Each region is a separately authored level, with contained terrain and incident placement; the game does not require seamless travel between regions.
- Outdoor scenes should be built and profiled for Forward+, with a clear performance budget before environment density expands.

### Incidents

Initial incident types:

1. Wilderness search: missing, lost, or injured hiker.
2. Small outdoor hazard: brush fire or flare-up, resolved with a simple extinguisher/water interaction.

Future incident possibilities: stranded kayaker, cliffside callout, storm damage, roadside collision, small building fire, boat rescue, and aerial hoist extraction. Add these only after the first two can share reliable incident and interaction patterns.

### Vehicles

- Ground vehicles are planned after the on-foot loop proves itself.
- Vehicles are externally operated: no modeled or playable interiors.
- Driving should be arcade-like, readable, and safe to prototype.
- An arcade helicopter is planned later for transport, search, and access to remote terrain. It must not block the first rescue slice.
- Later aerial-rescue scenes may include a pilot, rescue diver, casualty NPCs, and a hoist. Keep this as a specialist scenario after the base helicopter control loop works.

### Progression

- Basic gear is available at the start from the rescue station.
- Before a callout, players choose a small shared or individual loadout from the equipment dispenser; capacity is deliberately limited so the choice matters.
- Better tools, ground vehicles, helicopter access, and new regions are potential campaign rewards.
- Region-specific progress can open further incidents or routes within that region.
- Broader campaign progress unlocks capabilities that meaningfully change how later regions can be approached.
- Unlocks should be a reward for completing working rescue loops, never a substitute for a readable baseline path.
- See [Gameplay and progression](docs/gameplay-and-progression.md) for the capability bands and interaction rules.

## Scope boundaries

### In scope now

- Two-player, host/join co-op, third-person, on-foot wilderness rescue on a local network.
- One compact map zone and one complete hiker incident.
- Synchronized player presence, shared NPC/casualty state, one relevant-equipment interaction, objective state, and completion UI.
- Host departure/disconnect returns both players to the session screen with a clear message; seamless host migration is not required.
- Forward+ as the supported renderer on modern desktop hardware.
- Low-poly placeholder art and a clean artist handoff path.

### Designed for, but deferred

- More than two players, internet matchmaking, dedicated servers, host migration, and anti-cheat.
- Web and mobile exports, including Compatibility or Mobile renderer tuning.
- Ground vehicle driving and passenger/casualty transport.
- Swimming, boat controls, and water-rescue incidents.
- Arcade helicopter.
- Multiple incident types, day/night, weather, and persistent progression.

### Out of scope for the prototype

- Vehicle interiors, realistic emergency-service procedure, clinical medical simulation, open-world scale, seamless inter-level travel, mission scripting tools, complex AI crowds, and extensive enterable buildings.
- Web/mobile platform support and renderer-parity work.

## Experience requirements

- A new player can understand the current objective without a tutorial wall.
- Both players can understand the shared objective and see when the other player changes the incident state.
- Searching involves looking at the environment, not only chasing a waypoint.
- A casualty and hazard are visually legible at a short distance.
- The player cannot become permanently stuck because of simple terrain or an interaction edge case.
- A complete first callout takes roughly 5–10 minutes during normal play.

## Acceptance criteria for the first slice

- The project opens and runs in the standard Godot 4.7 editor.
- The intended build runs in Forward+ on the team's target desktop machines.
- A third-person character can traverse the test area with a usable camera.
- One player can host and a second player can join the same local-network session.
- Both players can see the other player's movement and receive the same active objective.
- Either player can find the hiker, complete the rescue interaction, reach extraction, and trigger the same completion state for both players.
- Both players can select and use the relevant default rescue kit without detailed medical procedure input.
- Restarting the scene resets the incident without manual editor intervention.
- A joining player cannot create a duplicate incident, casualty, or completion reward; if the host leaves, the session ends cleanly for both.
- The slice uses placeholder or properly tracked art and contains no unrecorded third-party content.

## Decisions to revisit after the slice

- Whether escorting or carrying feels better as the baseline casualty transport mechanic.
- How much guidance the search area needs.
- Whether terrain size makes ground vehicles meaningfully better than on-foot travel.
- Whether carrying a casualty must require two players or should remain an optional one-player action.
- Whether the first released co-op build should support only LAN play or also a simple direct internet connection.
- The minimum target desktop hardware and outdoor-scene performance budget for release.
