extends Node

const WORLD_SCENE := preload("res://scenes/world/InlandIslandTest.tscn")
const RESPONDER_SCENE := preload("res://scenes/player/Responder.tscn")

var active_world: Node3D


func _ready() -> void:
	# A local preview keeps the first movement checkpoint runnable before LAN setup.
	_start_local_preview()


func _start_local_preview() -> void:
	$Placeholder.queue_free()
	active_world = WORLD_SCENE.instantiate()
	add_child(active_world)

	var responder := RESPONDER_SCENE.instantiate()
	responder.name = "Responder_1"
	responder.set_multiplayer_authority(1)
	responder.global_transform = active_world.get_spawn_transform(0)
	active_world.get_node("Players").add_child(responder)
