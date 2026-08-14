# Technical Scaffold Requirements

## Purpose

This is the implementation brief for the first code-agent pass. Its job is to create a runnable, understandable foundation for the inland-island rescue prototype—not to build a general game framework or the full first mission.

The required first result is a **two-player LAN third-person walking demo**: a host and one joining player load the same bounded outdoor test level, spawn exactly once, move around it, and see one another move.

For gameplay scope and acceptance criteria, see the [Specification](../specification.md). For ownership rules, see [Multiplayer MVP](multiplayer-mvp.md) and [Architecture](architecture.md).

## Non-negotiable constraints

- Standard **Godot 4.6**, GDScript only, desktop-first.
- Forward+ is the intended renderer. Do not spend time supporting Web, mobile, or another renderer in this scaffold.
- Use built-in Godot nodes and high-level multiplayer APIs. Do not install a terrain, networking, inventory, ECS, or mission-framework add-on for the first pass.
- Two players only: one LAN host and one direct-IP joining client. No accounts, matchmaking, internet relay, dedicated server, reconnect, or host migration.
- The host is authoritative for the session, level choice, spawn roster, and future shared mission facts.
- Use placeholder geometry, materials, and labels. The scaffold must not depend on finished Goxel art.
- Keep all initial code and scenes easy to delete or replace. Do not add persistence, progression, vehicles, swimming, boating, fire, casualty logic, or elaborate UI yet.

## Required repository layout

Create this small starting structure; add folders only when a real asset or script needs them.

```text
res://
├── scenes/
│   ├── main/
│   │   └── Main.tscn
│   ├── multiplayer/
│   │   └── SessionMenu.tscn
│   ├── player/
│   │   └── Responder.tscn
│   ├── world/
│   │   └── InlandIslandTest.tscn
│   └── ui/
│       └── PrototypeHud.tscn
├── scripts/
│   ├── multiplayer/
│   │   └── session.gd
│   ├── player/
│   │   └── responder.gd
│   └── world/
│       └── inland_island_test.gd
├── assets/
│   ├── models/source/
│   ├── models/
│   ├── audio/
│   ├── textures/
│   └── ui/
└── resources/
```

`Main.tscn` is the project main scene. It owns the session/menu transition, selected level, loaded level, and prototype HUD. It must not become a catch-all game manager.

## Required deliverables

### 1. Project settings and inputs

- Set the main scene and a sensible desktop window size.
- Confirm Forward+ is the intended renderer in project settings.
- Define named input actions rather than checking raw keys in code:

  | Action | Default keyboard / mouse intent |
  | --- | --- |
  | `move_forward`, `move_back`, `move_left`, `move_right` | WASD movement |
  | `jump` | Space |
  | `sprint` | Shift |
  | `interact` | E |
  | `cancel` | Escape |
  | `toggle_mouse_capture` | Escape or a clearly documented alternative |

- Capture the mouse during normal third-person play and provide a reliable way to release it.

### 2. Session menu and LAN connection

Build a small `SessionMenu` with:

- **Host** button;
- direct-IP address field and **Join** button;
- clear connection/error/status text;
- a configurable `DEFAULT_PORT` constant (initially `8910` is fine);
- a return-to-menu path when hosting fails, joining fails, or the host ends the session.

Use Godot's `ENetMultiplayerPeer` through one small `session.gd` boundary. Do not scatter connection setup across player or world scripts. Start the selected inland test level only after the host is ready; joining clients load the level as part of the host-controlled session flow.

### 3. Inland island test level

Create `InlandIslandTest.tscn` as a compact, authored blockout. It must be pleasant enough to test movement, camera, terrain collision, and visibility—not a finished environment.

- Rough outer footprint: about **300 m × 300 m**; keep the practical on-foot routes smaller.
- Build an accessible central area containing a trail, gentle slopes, a meadow-to-forest transition, a small wetland edge, and a lake shore.
- Use mountains, cliffs, dense non-traversable terrain, and water edges to make the boundary natural. Do not rely on a visible rectangular wall.
- Put a small lake island in view, but make the water non-swimmable and the island inaccessible for this scaffold.
- Add a rescue-centre/helipad blockout, trailhead, lookout, distant village forms, and health-centre landmark as simple boxes or other primitives. Buildings are exterior landmarks only.
- Add two clearly named spawn markers and one distant trail destination marker.
- Give all walkable ground, slopes, and blocking rocks/buildings intentional collision. Use simple static collision shapes; no final terrain tool is required.
- Use simple lighting, sky, fog/environment, and a water material/plane if useful. The water only needs to read well at a distance; no buoyancy, underwater camera, or swim code.

The level should be built from ordinary Godot meshes/nodes or a small generated blockout under the level scene's control. Keep terrain presentation separate from collision so later faceted terrain or Goxel assets can replace either one.

### 4. Third-person responder

Create `Responder.tscn` with a `CharacterBody3D` root, a collision shape, a visible placeholder mesh, a pivot for horizontal camera rotation, a `SpringArm3D`, and a `Camera3D`.

The controller must provide:

- walk, run/sprint, gravity, jump, and stable floor/slope behaviour;
- camera-relative movement;
- orbit camera with mouse look, pitch clamp, and spring-arm collision;
- no control of a remote player's camera or input;
- a visible distinction between the local responder and a remote responder, even if it is only material colour or a name label;
- no combat, health, inventory, animation rig, or interaction implementation yet.

Tune for forgiving exploration rather than realism. The required result is that a player can run between the rescue centre and the distant trail marker without falling through terrain, snagging on basic props, or losing the camera behind a wall.

### 5. Two-player replication

Implement the narrowest reliable version of the multiplayer contract:

- The host creates exactly one responder per connected peer, assigns authority correctly, and prevents duplicate spawns after a scene reload.
- The joining client receives the same level and sees the host's responder; the host sees the joining responder.
- Each local player controls only its own responder.
- Replicate position, rotation, and enough movement state for the remote player to appear responsive. It is acceptable to use a simple fixed send rate and interpolation for this prototype; do not attempt prediction/reconciliation unless a real playtest proves it necessary.
- The host relays or owns shared state. Clients must not independently instantiate shared world content or advance future incident state.
- If the host disconnects or returns to the menu, the client gets a clear message and returns safely to the session menu.
- The connection and spawn flow must work when testing two separate desktop instances on the same LAN. Local multi-instance testing is useful, but not the only acceptance check.

Use Godot's multiplayer nodes or focused RPC methods where they keep authority visible. Network-facing methods should live in `session.gd` or a clearly named small companion script, not throughout the project.

### 6. Minimal HUD and debug feedback

Add a compact `PrototypeHud` that shows:

- session role/status (host, connected client, or disconnected);
- current level name;
- a short placeholder objective, such as “Reach the trail marker”; and
- a small optional debug readout for player count or connection state.

Keep this separate from the session menu. It is a temporary verification aid, not the final game HUD.

## Build order and checkpoints

Work in this order. Stop and test after each checkpoint before moving on.

1. **Project opens:** create project settings, `Main.tscn`, and the scene/script folders. The project runs to a harmless placeholder screen.
2. **Local movement:** add `InlandIslandTest` and one local responder. Verify terrain collision, slopes, camera, mouse capture, and the trail destination.
3. **Host/join:** add the session menu and connect two instances. Verify the same level and exactly one player per peer.
4. **Replication polish:** make remote movement readable, handle connection failures and host exit, and add status HUD feedback.
5. **Art handoff check:** import one Goxel calibration cube and one simple tree/rock only after the blockout works. Follow [Goxel workflow](goxel-workflow.md).

Make a small, separately reviewable change or commit after every checkpoint.

## Definition of done for this scaffold

- [ ] Project opens in standard Godot 4.6 and runs `Main.tscn` using Forward+.
- [ ] A player can host on the LAN; another machine can join by IP and port.
- [ ] Both players load the inland-island test level and spawn once at distinct spawn markers.
- [ ] Both can walk, sprint, jump, and use a collision-safe third-person camera.
- [ ] Each sees the other move without persistent duplicate players, frozen remote transforms, or ownership/control crossover.
- [ ] The level visibly communicates mountain boundaries, trails, meadow/forest/wetland variation, lake shore, lake island, and the basic POIs.
- [ ] The lake has no accidental swimming, drowning, underwater, or boat behaviour; it is a deliberate visual boundary.
- [ ] Closing the host session returns both players safely to the session menu with understandable feedback.
- [ ] No external add-on, final art dependency, or deferred gameplay system is required to run the demo.

## Explicitly defer

- Hiker/casualty, dispatch, equipment selection, interaction, extraction, and mission completion. These begin after this foundation is reliable.
- Vehicles, helicopter, hoist, boats, swimming, diving, water physics, and water-rescue incidents.
- Inventory, loadouts, progression, saving, achievements, or a generic item system.
- Finished terrain, procedural foliage, navigation meshes, AI pathfinding, animation rigs, audio systems, or weather simulation.
- Matchmaking, internet multiplayer, voice chat, more than two players, host migration, or dedicated servers.

The next implementation brief should add one shared hiker incident to this foundation, not broaden the technology stack.
