extends CenterContainer

signal host_requested(display_name: String)
signal join_requested(address: String, display_name: String)

@onready var address_input: LineEdit = $Panel/Margin/Content/AddressInput
@onready var name_input: LineEdit = $Panel/Margin/Content/NameInput
@onready var status_label: Label = $Panel/Margin/Content/StatusLabel


func _ready() -> void:
	$Panel/Margin/Content/HostButton.pressed.connect(func() -> void: host_requested.emit(_get_display_name()))
	$Panel/Margin/Content/JoinButton.pressed.connect(_emit_join_requested)
	address_input.text_submitted.connect(func(_value: String) -> void: _emit_join_requested())


func set_status(message: String) -> void:
	status_label.text = message


func _emit_join_requested() -> void:
	var address := address_input.text.strip_edges()
	if address.is_empty():
		set_status("Enter the host's LAN IP address first.")
		return
	join_requested.emit(address, _get_display_name())


func _get_display_name() -> String:
	var display_name := name_input.text.strip_edges()
	return display_name if not display_name.is_empty() else "Responder"
