# Multiplayer MVP — Two-Player Co-op

## Goal

Support one host and one joining player completing the same on-foot hiker-rescue incident together. This is a feature of the first vertical slice, not a later conversion of single-player gameplay.

## Supported session contract

- **Players:** exactly two: one host and one client.
- **Connection:** host/join on the same local network for the first playable desktop build. Web and mobile are not MVP targets; matchmaking is not part of the MVP.
- **Session start:** the host selects the test region; the client joins before the level begins. Mid-incident joining is optional until M3 and must not block the first slice.
- **Session end:** if the host leaves or disconnects, end the session for both players and return to the session screen with a clear message. Do not attempt host migration.
- **Save/progression:** only the host's prototype progress is used. Persistent co-op progression is deferred.
- **Communication:** in-game voice chat is not required; the initial players are in the same room. Contextual pings and quick status calls can be added later if they improve remote play.

## What must synchronize

| System | MVP behavior | Authority |
| --- | --- | --- |
| Player roster/spawns | One player scene per connected peer, no duplicates | Host |
| Player movement and animation | Each player sees the other move and animate plausibly | Owning player sends; host relays/validates later if needed |
| Active level | Both load the same selected region before play begins | Host |
| Dispatch/objective text | Same incident state and objective for both | Host |
| Casualty/hazard | One shared target; discovery and rescue state are identical | Host |
| Interactions | Either player can request an eligible interaction | Host validates and broadcasts result |
| Extraction/completion | Completion happens once and is shown to both | Host |

## Explicitly not required

- Internet matchmaking, accounts, invites, relay/NAT traversal, dedicated servers, or anti-cheat.
- More than two players, spectator mode, drop-in/drop-out, host migration, or reconnecting into an active callout.
- Vehicle networking. Vehicles arrive after the on-foot co-op rescue is stable.
- Voice-chat capture, moderation, or voice-service integration.

## Implementation shape

Keep a small `Session` scene/controller responsible for starting or joining a session, loading the level, assigning peer IDs to player scenes, and ending the session. Keep `IncidentHiker` responsible for incident state, but let only the host create it and approve its shared state transitions.

Use clear network-facing methods rather than scattering RPC calls across ordinary gameplay code. For example:

```text
client: request_interaction(target_id)
host: validate_interaction(peer_id, target_id)
host: apply_and_broadcast_interaction_result(target_id, new_state)
```

The exact Godot networking nodes and methods can stay behind this small boundary. The important prototype rule is that shared facts have one authority.

## Test checklist

- [ ] Host can create a session and a second machine can join it on the local network.
- [ ] Both players spawn exactly once and see the other player move.
- [ ] Both see the same callout and objective updates.
- [ ] The hiker appears exactly once for both players.
- [ ] Either player can find and interact with the hiker; the result becomes visible to both.
- [ ] Extraction completes once and both see the same success state.
- [ ] Restarting the level produces one fresh incident for both players.
- [ ] If the host exits, the client receives a clear session-ended message and returns safely to the menu/session screen.
