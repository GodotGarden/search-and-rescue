extends Control

signal end_session_requested

const TOOL_LABELS := ["Binoculars", "Map", "Compass"]

@onready var binoculars_label: Label = $BinocularsLabel
@onready var map_overlay: Control = $MapOverlay
@onready var map_display: Control = $MapOverlay/Panel/Margin/Rows/MapDisplay
@onready var compass_overlay: Control = $CompassOverlay
@onready var compass_display: Control = $CompassOverlay/Margin/Rows/CompassDisplay
@onready var slots := [$ToolbeltHotbar/Slots/Slot1, $ToolbeltHotbar/Slots/Slot2, $ToolbeltHotbar/Slots/Slot3]

var _local_responder: Node3D
var _equipped_tool := 0
var _local_authority := 0


func _ready() -> void:
	$EndSessionButton.pressed.connect(func() -> void: end_session_requested.emit())
	set_equipped_tool(0)


func set_local_responder(responder: Node3D) -> void:
	_local_responder = responder
	_local_authority = responder.get_multiplayer_authority() if responder != null else 0
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
	if event.is_action_pressed("cancel"):
		if map_overlay.visible:
			map_overlay.visible = false
		elif compass_overlay.visible:
			compass_overlay.visible = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("equip_tool_1"):
		_select_tool(0)
	elif event.is_action_pressed("equip_tool_2"):
		_select_tool(1)
	elif event.is_action_pressed("equip_tool_3"):
		_select_tool(2)
	elif event.is_action_pressed("interact"):
		_local_responder.use_equipped_tool(true)
	else:
		return
	get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not is_instance_valid(_local_responder):
		return
	if event.is_action_released("interact"):
		_local_responder.use_equipped_tool(false)


func _select_tool(tool: int) -> void:
	_local_responder.equip_tool(tool)
	set_equipped_tool(tool)


func set_equipped_tool(tool: int) -> void:
	_equipped_tool = tool
	$Readout/Margin/Rows/ToolbeltLabel.text = "Equipped: %s — %s" % [TOOL_LABELS[tool], "hold E to use" if tool == 0 else "press E to open"]
	for index in range(slots.size()):
		slots[index].modulate = Color(1.0, 0.88, 0.4) if index == tool else Color.WHITE


func use_equipped_tool(tool: int) -> void:
	if tool == 1:
		map_overlay.visible = not map_overlay.visible
	elif tool == 2:
		compass_overlay.visible = not compass_overlay.visible


func set_session_info(role: String, status: String, player_count: int) -> void:
	$Readout/Margin/Rows/RoleLabel.text = "%s — %s" % [role, status]
	$Readout/Margin/Rows/DebugLabel.text = "Players: %d / 2 — tool peer: %d" % [player_count, _local_authority]
	$EndSessionButton.visible = role == "Host"
