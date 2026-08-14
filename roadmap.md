# Roadmap — Prototype to First Rescue Game

The roadmap is ordered by learning value. Finish and play each milestone before investing in the next one. A milestone can be cut down; it should not quietly expand into several milestones.

## M0 — Project foundation

**Goal:** Open a clean, GDScript-only Godot 4.6 project and establish the smallest reusable structure.

- Add the directory scaffold and documentation.
- Set basic input actions and project display settings.
- Set Forward+ as the intended desktop renderer and record the development machines used for performance checks.
- Create one bounded inland-island test region with a rescue-centre start point, mountains as a natural boundary, and a main scene.
- Add a bare host/join session screen for two local-network players; no accounts or matchmaking.
- Add version-control ignores for Godot-generated files.
- Verify a fresh clone or copy opens and runs.

**Done when:** another contributor can open the project, host or join a placeholder session, run a placeholder scene, and understand where scenes, scripts, models, and licenses belong.

## M1 — Co-op third-person outdoor movement

**Goal:** Make moving through the landscape pleasant before building missions.

- Third-person character scene with camera rig, walk/run, collision, and basic obstacle handling.
- Two connected players spawn once, see each other's position and movement, and retain control of their own character.
- Small terrain section with a trail, slopes, a meadow/forest/wetland transition, Goxel tree placeholders, and visual landmarks.
- Add a lake and shore as a visual water boundary. It does not need to be swimmable; a simple Godot water material/shader experiment is enough at this stage.
- Keep the first small lake island visible as a future access goal, not a required location in the hiker rescue.
- Compose the first inland-island vista with layered forest, hills or cliffs, pines, a creek/gorge, and one distant POI such as a lookout, medical center, or village silhouette.
- Minimal contextual HUD: current objective, interaction prompt, selected equipment, and limited compass/minimap orientation. Do not expose undiscovered incident information.

**Done when:** two players can comfortably travel from the rescue station to a distant trail point, see each other move, and do not suffer duplicate spawns, camera collisions, or stuck states.

## M2 — One complete co-op hiker rescue

**Goal:** Validate the complete rescue loop on foot.

- Dispatch/incident starter with one callout.
- Shared incident lifecycle: the host owns creation and state transitions; both clients receive the same result.
- Search area, objective updates, and a hidden or partially obscured casualty NPC.
- One relevant-equipment interaction: use the fixed default response kit on the casualty and show a clear stabilized/ready-for-extraction state.
- Escort or carry mechanic to a marked extraction point.
- Success, reset, and simple feedback.

**Done when:** two playtesters can host/join and complete the same scenario in 5–10 minutes without developer explanation, duplicate targets, or mismatched objective state.

## M2.5 — Outdoor performance baseline

**Goal:** Establish a useful performance floor for the Forward+ wilderness scene before environment content expands.

- Run the working co-op slice on the target desktop machines with Forward+.
- Measure frame rate and frame-time stability in the busiest outdoor view, including terrain, foliage placeholders, both players, and the active incident.
- Set an initial environment-density and visual-effects budget from those results.

**Done when:** the team has a repeatable Forward+ performance check and a documented budget for the first wilderness region.

## M3 — Improve the loop, not the feature count

**Goal:** Turn the working slice into something worth repeating.

- Observe a few playtests and fix confusion, stuck states, and tedious travel.
- Tune objective guidance, clue placement, movement, and interaction timing.
- Add one variation of the hiker incident using the same scene/resource patterns.
- Improve placeholder audio, VFX, and low-poly environment readability where they affect play.
- Add a small ambient soundscape: wind, water or forest sounds, birds, and location-specific distant activity. It must support, not mask, gameplay cues.
- Test joining before a callout, during a callout, and after completion; handle the supported cases cleanly.

**Done when:** the team can explain why searching and resolving an incident is enjoyable, and the base systems support a second callout without copy-paste sprawl.

## M3.5 — Rescue station, loadouts, and first unlock

**Goal:** Confirm the game can grow through discrete regions without becoming an open-world project.

- Add a simple rescue-station briefing/loadout screen or physical hub corner with an equipment dispenser.
- Let players choose a deliberately small loadout before a callout.
- Present the completed callout and one tangible unlock, such as a flashlight, backpack capacity, or access to a second incident.
- Select or launch one bounded region explicitly; do not add seamless world travel.
- Keep progression in memory or a minimal prototype profile until a real save requirement exists.

**Done when:** players understand that incidents belong to distinct rescue regions, can choose a simple loadout, and see that completing one can unlock a tangible next capability.

## M4 — Add a second resolution pattern

**Goal:** Test a small outdoor fire/hazard callout.

- Simple hazard state and extinguisher/water action.
- Add the first specialized protective loadout only if it changes the player's approach to the scene.
- Fire readability, safe interaction range, progression, and resolved state.
- Reuse the incident lifecycle, objective UI, and completion path.

**Done when:** a small brush-fire incident feels different from the hiker rescue while using the same core game loop.

## M4.5 — Lake access experiment

**Goal:** Decide whether reaching a small lake island is a fun, understandable capability unlock.

- Keep this experiment inside the existing inland region: a shore, one small island, and one clear reason to reach it.
- First decide the access method: a simple arcade swim **or** a simple small boat. Do not build both in the same experiment.
- If swimming is tested, make the water entry/exit, camera, stamina/limits, and return-to-shore behaviour reliable before adding rescue stakes.
- If a boat is tested, keep it to one stable, easy-to-control craft and a short crossing; do not turn it into a full boating system.
- Use the result to inform a later stranded-kayaker or island-casualty incident only if the crossing itself is enjoyable.

**Done when:** two players can safely and clearly reach the island and return, with no camera, collision, or network-state surprises. If the experiment is not fun, keep the lake scenic and defer water gameplay.

## M5 — Ground vehicle prototype

**Goal:** Learn whether driving improves the rescue fantasy.

- Externally entered/exited arcade response vehicle; no interiors.
- Compact road loop and dispatch-to-scene travel test.
- Clear handoff between driving, on-foot search, and incident completion.
- Test one vehicle loadout decision, such as choosing a stretcher or extra response supplies.

**Done when:** driving adds a useful decision or faster travel without making mission setup or controls frustrating.

## M6 — Helicopter experiment

**Goal:** Test a simple arcade helicopter only after ground play works.

- Takeoff/landing, readable third-person camera, and basic flight bounds.
- A remote search or extraction situation that genuinely benefits from flight.
- Only after those work, prototype a simple hoist extraction with a pilot, rescue diver, and casualty. Start with a tightly scripted rescue zone rather than open-water simulation.

**Done when:** flight is fun and supports rescue work rather than becoming a disconnected mini-game; hoist/diver work remains a follow-up if the basic aerial loop is not already solid.

## Later — Multiplayer expansion and content growth

Keep the two-player host/join model small until the co-op incident is stable. Only then evaluate direct internet connections, invite flow, host migration, dedicated servers, or more players. Expand the set of bounded regions, limited interiors, incident catalogue, persistent progression, and weather only where the existing loop gives a concrete reason.

## Explicit non-goals before M3

- More than two players, matchmaking, and dedicated servers
- Helicopters or vehicle interiors
- Large map streaming
- Seamless/open-world travel
- Complex interiors
- Realistic medical procedures
- Procedural generation
- Broad add-on adoption
