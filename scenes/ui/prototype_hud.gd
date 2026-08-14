extends Control

signal end_session_requested

@onready var binoculars_label: Label = $BinocularsLabel
@onready var map_overlay: Control = $MapOverlay
@onready var map_display: Control = $MapOverlay/Panel/Margin/Rows/MapDisplay
@onready var compass_overlay: Control = $CompassOverlay
@onready var compass_display: Control = $CompassOverlay/Margin/Rows/CompassDisplay

var _local_responder: Node3D


func _ready() -> void:
	$EndSessionButton.pressed.connect(func() -> void: end_session_requested.emit())


func set_local_responder(responder: Node3D) -> void:
	_local_responder = responder
	if responder == null:
		map_overlay.visible = false
		compass_overlay.visible = false
		binoculars_label.visible = false


func _process(_delta: float) -> void:
	if not is_instance_valid(_local_responder):
		return
	map_display.set_player_state(_local_responder.global_position, _local_responder.global_rotation.y)
	compass_display.set_heading(_local_responder.global_rotation.y)
	binoculars_label.visible = _local_responder.is_viewing_binoculars()


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_local_responder):
		return
	if event.is_action_pressed("toggle_map"):
		map_overlay.visible = not map_overlay.visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_compass"):
		compass_overlay.visible = not compass_overlay.visible
		get_viewport().set_input_as_handled()


func set_session_info(role: String, status: String, player_count: int) -> void:
	$Readout/Margin/Rows/RoleLabel.text = "%s — %s" % [role, status]
	$Readout/Margin/Rows/DebugLabel.text = "Players: %d / 2" % player_count
	$EndSessionButton.visible = role == "Host"
