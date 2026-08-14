# Two-Player LAN Test Guide

Use this guide to verify the current walking-demo scaffold with one host and one joining player. It tests the supported MVP contract only: two desktop players on one local network, connected directly by IP. Matchmaking, internet relay, reconnecting, and more than two players are not supported.

## Before starting

- Use two separate Godot desktop instances. Two physical machines on the same LAN are the required test; two instances on one machine are a useful smoke test.
- Use the same commit and Godot 4.6 project on both machines.
- Ensure the joining machine can reach the host's LAN IP address.
- Allow inbound UDP traffic on port `8910` on the host machine if its firewall asks. The port is defined as `DEFAULT_PORT` in `scripts/multiplayer/session.gd`.
- For a same-machine check, use `127.0.0.1` as the joining address. Do not treat this as a substitute for a LAN test.

## Find the host's LAN address on macOS

On the host Mac, open **System Settings → Network**, select the connected Wi-Fi or Ethernet service, then open **Details…**. The address listed under **IP Address** is the value to enter on the joining machine—for example, `192.168.1.42`.

As a terminal shortcut for a typical Wi-Fi connection, run:

```sh
ipconfig getifaddr en0
```

Use the returned IPv4 address. Do not use an address beginning with `127.` (loopback), a public internet address, or the router's address. If the Mac is connected by Ethernet and `en0` prints nothing, use the address shown in System Settings for that Ethernet service instead.

## Start a session

1. Open the project and run it with <kbd>F5</kbd> on the host machine.
2. Enter a distinct **Responder name**, then select **Host LAN session**. The inland island loads and the HUD shows **Host**.
3. Find the host machine's LAN IP address, such as `192.168.1.42`; on macOS, follow the steps above.
4. Run a second instance on the joining machine. Enter a different **Responder name** and the host IP address, then select **Join session**.
5. Wait for the inland island to load on the client. Each machine should show two responders: the local responder is blue, the remote responder is orange, and each has the selected name above them.

## Core acceptance pass

Perform this sequence once per build that changes session, player, world, or shared-gameplay code.

| Check | Steps | Expected result |
| --- | --- | --- |
| Connection | Host, then join with the correct LAN IP. | The client enters the same inland-island level. Neither instance stays on a connecting screen. |
| Spawn roster | Stand still after the client joins. | Exactly two responders exist, at separate spawn markers. Rejoining or changing focus does not create another responder. |
| Local ownership | Move, sprint, jump, and orbit the camera on each machine. | Each player controls only their own responder and camera. The other responder remains input-free locally. |
| Names | Compare the labels above both responders. | Each machine shows its own name with “(You)” and the other player's chosen name. |
| Replication | Have each player run from the rescue centre toward the trail destination, then stop and change direction. | The other instance sees responsive movement without a permanently frozen or duplicate responder. |
| World consistency | Compare landmarks and objective text. | Both players see the same inland-island blockout and the objective “Reach the trail marker.” |
| Mouse control | Press <kbd>Escape</kbd> while playing, then press it again. | The mouse releases and can be captured again without losing movement control. |
| Host exit | Select **End session** on the host. | The host and client both return safely to the session menu; the client explains that the host disconnected. |

Record the commit, machine/OS pair, Godot version, and any failure in the playtest notes. Include whether the test was same-machine or LAN; a passing loopback test does not prove LAN connectivity.

## Failure checks

| Symptom | Check first |
| --- | --- |
| Client cannot connect | Confirm the host is already running, both devices are on the same LAN, the entered IP is the host's LAN address, and UDP port `8910` is allowed through the host firewall. |
| Client connects but never loads the island | Record the host/client HUD status and Godot output. This is a session-flow regression, not a reason to manually load the scene on the client. |
| Extra, missing, or frozen responder | Record which instance sees the issue, whether it happened after joining or ending/restarting a session, and the relevant Godot output. Do not test a third player: the current session is capped at two. |
| Camera or input moves the wrong responder | Record the peer role and responder colours. Local input belongs only to the responder controlled by that peer. |
| Client remains in the world after host exit | Capture the host and client logs. The supported result is a safe return to the session menu, not host migration or reconnect. |

## Scope boundary

This guide validates M1's movement/networking foundation. The next test plan should extend it for M2's shared hiker incident: host-owned incident creation, shared objectives, one casualty, a synchronized interaction, extraction, completion, and reset. Keep those checks separate from this baseline so movement/session regressions remain easy to diagnose.
