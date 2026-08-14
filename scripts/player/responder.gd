extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var acceleration := 18.0
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025

const GRAVITY := 18.0
const CAMERA_PITCH_LIMIT := deg_to_rad(65.0)
const NETWORK_SEND_INTERVAL := 1.0 / 15.0

@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var name_tag: Label3D = $NameTag
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

var _look_pitch := -0.2
var _network_position := Vector3.ZERO
var _network_yaw := 0.0
var _network_send_elapsed := 0.0


func _ready() -> void:
	var is_local := is_multiplayer_authority()
	camera.current = is_local
	name_tag.text = "You" if is_local else "Responder"
	var material := body_mesh.material_override.duplicate() as StandardMaterial3D
	material.albedo_color = Color(0.1, 0.45, 0.9) if is_local else Color(1.0, 0.35, 0.1)
	body_mesh.material_override = material
	if is_local:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		_network_position = global_position
		_network_yaw = rotation.y


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("toggle_mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_look_pitch = clampf(_look_pitch - event.relative.y * mouse_sensitivity, -CAMERA_PITCH_LIMIT, CAMERA_PITCH_LIMIT)
		camera_pivot.rotation.x = _look_pitch


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		global_position = global_position.lerp(_network_position, minf(delta * 12.0, 1.0))
		rotation.y = lerp_angle(rotation.y, _network_yaw, minf(delta * 12.0, 1.0))
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = move_toward(velocity.x, move_direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, move_direction.z * speed, acceleration * delta)
	move_and_slide()
	_network_send_elapsed += delta
	if _network_send_elapsed >= NETWORK_SEND_INTERVAL:
		_network_send_elapsed = 0.0
		_send_network_state()


func _send_network_state() -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	if multiplayer.is_server():
		relay_state.rpc(global_position, rotation.y, velocity)
	else:
		submit_state.rpc_id(1, global_position, rotation.y, velocity)


@rpc("any_peer", "call_remote", "unreliable")
func submit_state(position_value: Vector3, yaw: float, movement_velocity: Vector3) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	_apply_network_state(position_value, yaw, movement_velocity)
	relay_state.rpc(position_value, yaw, movement_velocity)


@rpc("authority", "call_remote", "unreliable")
func relay_state(position_value: Vector3, yaw: float, movement_velocity: Vector3) -> void:
	_apply_network_state(position_value, yaw, movement_velocity)


func _apply_network_state(position_value: Vector3, yaw: float, movement_velocity: Vector3) -> void:
	_network_position = position_value
	_network_yaw = yaw
	velocity = movement_velocity
