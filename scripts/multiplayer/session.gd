extends Node

const DEFAULT_PORT := 8910
const MAX_PLAYERS := 2

signal host_ready
signal level_requested(level_path: String)
signal player_spawn_requested(peer_id: int, spawn_index: int, display_name: String)
signal status_changed(message: String)
signal session_ended(message: String)
signal session_failed(message: String)

var _peer: ENetMultiplayerPeer
var _active_level_path := ""
var _spawned_peers: Dictionary = {}
var _display_names: Dictionary = {}
var _local_display_name := "Responder"
var _status := "Disconnected"


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func start_host() -> void:
	_end_peer()
	_peer = ENetMultiplayerPeer.new()
	var result := _peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if result != OK:
		_fail("Could not host on port %d (error %d)." % [DEFAULT_PORT, result])
		return
	multiplayer.multiplayer_peer = _peer
	_display_names[1] = _local_display_name
	_set_status("Hosting on LAN port %d." % DEFAULT_PORT)
	host_ready.emit()


func start_join(address: String) -> void:
	_end_peer()
	_peer = ENetMultiplayerPeer.new()
	var result := _peer.create_client(address, DEFAULT_PORT)
	if result != OK:
		_fail("Could not begin joining %s:%d (error %d)." % [address, DEFAULT_PORT, result])
		return
	multiplayer.multiplayer_peer = _peer
	_set_status("Connecting to %s:%d…" % [address, DEFAULT_PORT])


func set_local_display_name(display_name: String) -> void:
	var cleaned_name := display_name.strip_edges().left(18)
	_local_display_name = cleaned_name if not cleaned_name.is_empty() else "Responder"


func set_active_level(level_path: String) -> void:
	if not multiplayer.is_server():
		return
	_active_level_path = level_path
	_spawn_peer(multiplayer.get_unique_id(), 0)


func notify_client_level_loaded() -> void:
	if not multiplayer.is_server():
		client_level_loaded.rpc_id(1)


func end_session(message := "Session ended.") -> void:
	_end_peer()
	session_ended.emit(message)


func get_role_label() -> String:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return "Disconnected"
	return "Host" if multiplayer.is_server() else "Connected client"


func get_status() -> String:
	return _status


func get_roster_size() -> int:
	return _spawned_peers.size()


func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server() or peer_id == 1:
		return
	if _active_level_path.is_empty():
		_fail("A client connected before the host level was ready.")
		return
	_set_status("Client connected; loading the inland island.")
	load_level.rpc_id(peer_id, _active_level_path)


func _on_connected_to_server() -> void:
	_set_status("Connected. Waiting for the host to load the level…")
	register_display_name.rpc_id(1, _local_display_name)


func _on_connection_failed() -> void:
	_fail("Could not connect to the host. Check the IP address and LAN firewall.")


func _on_server_disconnected() -> void:
	end_session("The host disconnected. Returned to the session menu.")


@rpc("authority", "call_remote", "reliable")
func load_level(level_path: String) -> void:
	level_requested.emit(level_path)


@rpc("any_peer", "call_remote", "reliable")
func client_level_loaded() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id <= 1 or _spawned_peers.has(peer_id):
		return
	for existing_peer_id in _spawned_peers:
		spawn_responder.rpc_id(peer_id, existing_peer_id, _spawned_peers[existing_peer_id], _display_names.get(existing_peer_id, "Responder"))
	_spawn_peer(peer_id, 1)
	_set_status("Two responders are active.")


func _spawn_peer(peer_id: int, spawn_index: int) -> void:
	if _spawned_peers.has(peer_id):
		return
	_spawned_peers[peer_id] = spawn_index
	var display_name: String = _display_names.get(peer_id, "Responder")
	player_spawn_requested.emit(peer_id, spawn_index, display_name)
	spawn_responder.rpc(peer_id, spawn_index, display_name)


@rpc("authority", "call_remote", "reliable")
func spawn_responder(peer_id: int, spawn_index: int, display_name: String) -> void:
	if _spawned_peers.has(peer_id):
		return
	_spawned_peers[peer_id] = spawn_index
	_display_names[peer_id] = display_name
	player_spawn_requested.emit(peer_id, spawn_index, display_name)


@rpc("any_peer", "call_remote", "reliable")
func register_display_name(display_name: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id <= 1:
		return
	var cleaned_name := display_name.strip_edges().left(18)
	_display_names[peer_id] = cleaned_name if not cleaned_name.is_empty() else "Responder"


func _fail(message: String) -> void:
	_end_peer()
	session_failed.emit(message)


func _end_peer() -> void:
	_spawned_peers.clear()
	_display_names.clear()
	_active_level_path = ""
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_peer = null
	_set_status("Disconnected")


func _set_status(message: String) -> void:
	_status = message
	status_changed.emit(message)
