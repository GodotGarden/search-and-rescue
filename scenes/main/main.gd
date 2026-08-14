extends Node

const LEVEL_PATH := "res://scenes/world/InlandIslandTest.tscn"
const RESPONDER_SCENE := preload("res://scenes/player/Responder.tscn")

@onready var session: Node = $Session
@onready var session_menu: Control = $Interface/SessionMenu
@onready var hud: Control = $Interface/PrototypeHud
@onready var active_level_root: Node3D = $ActiveLevel

var active_world: Node3D


func _ready() -> void:
	session.host_ready.connect(_on_host_ready)
	session.level_requested.connect(_on_level_requested)
	session.player_spawn_requested.connect(_spawn_responder)
	session.status_changed.connect(_show_status)
	session.session_ended.connect(_return_to_menu)
	session.session_failed.connect(_return_to_menu)
	session_menu.host_requested.connect(_on_host_requested)
	session_menu.join_requested.connect(_on_join_requested)
	hud.end_session_requested.connect(_on_end_session_requested)
	_show_status("Choose Host to start a LAN session, or enter a host IP to join.")


func _on_host_requested() -> void:
	session.start_host()


func _on_join_requested(address: String) -> void:
	session.start_join(address)


func _on_host_ready() -> void:
	_load_level(LEVEL_PATH)
	session.set_active_level(LEVEL_PATH)


func _on_level_requested(level_path: String) -> void:
	_load_level(level_path)
	session.notify_client_level_loaded()


func _load_level(level_path: String) -> void:
	_clear_active_level()
	var level_scene := load(level_path) as PackedScene
	active_world = level_scene.instantiate()
	active_level_root.add_child(active_world)
	session_menu.visible = false
	hud.visible = true
	_refresh_hud()


func _spawn_responder(peer_id: int, spawn_index: int) -> void:
	if active_world == null or active_world.get_node_or_null("Players/Responder_%d" % peer_id) != null:
		return
	var responder := RESPONDER_SCENE.instantiate()
	responder.name = "Responder_%d" % peer_id
	responder.set_multiplayer_authority(peer_id)
	active_world.get_node("Players").add_child(responder)
	responder.global_transform = active_world.get_spawn_transform(spawn_index)
	if peer_id == multiplayer.get_unique_id():
		hud.set_local_responder(responder)
	_refresh_hud()


func _on_end_session_requested() -> void:
	session.end_session("Host ended the session.")


func _return_to_menu(message: String) -> void:
	_clear_active_level()
	hud.visible = false
	session_menu.visible = true
	session_menu.set_status(message)


func _clear_active_level() -> void:
	if active_world != null:
		active_world.queue_free()
		active_world = null
	hud.set_local_responder(null)


func _show_status(message: String) -> void:
	session_menu.set_status(message)
	_refresh_hud()


func _refresh_hud() -> void:
	if hud.visible:
		hud.set_session_info(session.get_role_label(), session.get_status(), session.get_roster_size())
