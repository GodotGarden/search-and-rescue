extends Control

signal end_session_requested


func _ready() -> void:
	$EndSessionButton.pressed.connect(func() -> void: end_session_requested.emit())


func set_session_info(role: String, status: String, player_count: int) -> void:
	$Readout/Margin/Rows/RoleLabel.text = "%s — %s" % [role, status]
	$Readout/Margin/Rows/DebugLabel.text = "Players: %d / 2" % player_count
	$EndSessionButton.visible = role == "Host"
