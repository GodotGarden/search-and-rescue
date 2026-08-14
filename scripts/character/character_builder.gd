class_name CharacterModel
extends Node3D

## Builds a segmented-rigid-part humanoid from a CharacterAppearance and poses it procedurally.
## See "Key decision: segmented rigid parts" and "Rig conventions" in docs/procedural-character-spec.md.

const CharacterAppearance := preload("res://scripts/character/character_appearance.gd")
const ProceduralLocomotion := preload("res://scripts/character/procedural_locomotion.gd")

const RESCUE_HELMET_SHELL_COLOR := Color("d94e1f")
const RESCUE_HELMET_BRIM_COLOR := Color("2c2c2c")

@export var appearance: CharacterAppearance

var _joints: Dictionary = {}
var _rest_rotations: Dictionary = {}
var _locomotion: ProceduralLocomotion
var _identity_material: StandardMaterial3D
var _horizontal_velocity := Vector3.ZERO
var _grounded := true


func _ready() -> void:
	build(appearance if appearance != null else CharacterAppearance.new())


func _physics_process(delta: float) -> void:
	if _locomotion != null:
		_locomotion.update(delta, _horizontal_velocity, _grounded)


## Called once per physics frame by the owning body; horizontal_velocity is world-space, y ignored.
func set_locomotion_input(horizontal_velocity: Vector3, grounded: bool) -> void:
	_horizontal_velocity = horizontal_velocity
	_grounded = grounded


## Local/remote disambiguation is a rendering layer applied on top of appearance, not a cosmetic field.
func set_identity_color(color: Color) -> void:
	if _identity_material != null:
		_identity_material.albedo_color = color


func get_head_socket() -> Node3D:
	return _joints.get("HeadSocket")


func get_hip_socket() -> Node3D:
	return _joints.get("HipSocket")


func get_hand_socket(is_left: bool) -> Node3D:
	return _joints.get("HandL" if is_left else "HandR")


func build(character_appearance: CharacterAppearance) -> void:
	appearance = character_appearance
	for child in get_children():
		child.free()
	_joints.clear()
	_rest_rotations.clear()
	_identity_material = null
	_build_rig(character_appearance)
	_locomotion = ProceduralLocomotion.new(_joints, _rest_rotations)


func _build_rig(app: CharacterAppearance) -> void:
	var girth := lerpf(0.8, 1.3, app.build)
	var leg_length := app.height_m * 0.48
	var thigh_length := leg_length * 0.5
	var shin_length := leg_length * 0.5
	var torso_height := app.height_m * 0.30
	var neck_length := app.height_m * 0.025
	var head_size := app.height_m * 0.14 * app.head_scale
	var arm_length := app.height_m * 0.38
	var upper_arm_length := arm_length * 0.5
	var forearm_length := arm_length * 0.5
	var hip_half_width := 0.13 * girth
	var shoulder_half_width := hip_half_width * app.shoulder_hip_ratio
	var torso_depth := 0.15 * girth
	var limb_thickness := 0.085 * girth

	var skin_material := _make_material(app.skin_color)
	var clothing_material := _make_material(app.clothing_primary_color)
	var accent_material := _make_material(app.clothing_secondary_color)
	var hair_material := _make_material(app.hair_color)

	var pelvis := _add_pivot(self, "Pelvis", Vector3(0, leg_length, 0))
	_add_box(pelvis, Vector3(hip_half_width * 2.0, torso_height * 0.22, torso_depth), Vector3(0, torso_height * 0.11, 0), clothing_material)

	var torso := _add_pivot(pelvis, "Torso", Vector3(0, torso_height * 0.22, 0))
	_add_box(torso, Vector3(shoulder_half_width * 1.8, torso_height * 0.8, torso_depth), Vector3(0, torso_height * 0.4, 0), clothing_material)
	var identity_badge := _add_box(torso, Vector3(shoulder_half_width * 0.7, torso_height * 0.14, 0.02), Vector3(0, torso_height * 0.55, -torso_depth * 0.5 - 0.01), _make_material(Color.WHITE))
	_identity_material = identity_badge.material_override

	var neck := _add_pivot(torso, "Neck", Vector3(0, torso_height * 0.8, 0))
	var head := _add_pivot(neck, "Head", Vector3(0, neck_length, 0))
	_add_box(head, Vector3(head_size, head_size, head_size), Vector3(0, head_size * 0.5, 0), skin_material)
	if app.head_equipment == CharacterAppearance.HeadEquipment.NONE:
		_add_hair(head, app, head_size, hair_material)
	_add_head_equipment(head, app, head_size)
	_add_pivot(head, "HeadSocket", Vector3(0, head_size, 0))
	_add_pivot(pelvis, "HipSocket", Vector3.ZERO)

	_build_arm(torso, true, shoulder_half_width, torso_height, upper_arm_length, forearm_length, limb_thickness, skin_material, clothing_material, accent_material)
	_build_arm(torso, false, shoulder_half_width, torso_height, upper_arm_length, forearm_length, limb_thickness, skin_material, clothing_material, accent_material)
	_build_leg(pelvis, true, hip_half_width, thigh_length, shin_length, limb_thickness, clothing_material, accent_material)
	_build_leg(pelvis, false, hip_half_width, thigh_length, shin_length, limb_thickness, clothing_material, accent_material)


func _build_arm(torso: Node3D, is_left: bool, shoulder_half_width: float, torso_height: float, upper_arm_length: float, forearm_length: float, limb_thickness: float, skin_material: StandardMaterial3D, clothing_material: StandardMaterial3D, accent_material: StandardMaterial3D) -> void:
	var side_x := -1.0 if is_left else 1.0
	var suffix := "L" if is_left else "R"
	var shoulder := _add_pivot(torso, "Shoulder%s" % suffix, Vector3(side_x * shoulder_half_width, torso_height * 0.76, 0))
	_add_box(shoulder, Vector3(limb_thickness * 1.15, upper_arm_length, limb_thickness * 1.15), Vector3(0, -upper_arm_length * 0.5, 0), clothing_material)
	var elbow := _add_pivot(shoulder, "Elbow%s" % suffix, Vector3(0, -upper_arm_length, 0))
	_add_box(elbow, Vector3(limb_thickness, forearm_length, limb_thickness), Vector3(0, -forearm_length * 0.5, 0), accent_material)
	var hand := _add_pivot(elbow, "Hand%s" % suffix, Vector3(0, -forearm_length, 0))
	_add_box(hand, Vector3(limb_thickness * 1.1, limb_thickness * 1.3, limb_thickness * 0.9), Vector3(0, -limb_thickness * 0.6, 0), skin_material)


func _build_leg(pelvis: Node3D, is_left: bool, hip_half_width: float, thigh_length: float, shin_length: float, limb_thickness: float, clothing_material: StandardMaterial3D, accent_material: StandardMaterial3D) -> void:
	var side_x := -1.0 if is_left else 1.0
	var suffix := "L" if is_left else "R"
	var hip := _add_pivot(pelvis, "Hip%s" % suffix, Vector3(side_x * hip_half_width * 0.7, 0, 0))
	_add_box(hip, Vector3(limb_thickness * 1.3, thigh_length, limb_thickness * 1.3), Vector3(0, -thigh_length * 0.5, 0), clothing_material)
	var knee := _add_pivot(hip, "Knee%s" % suffix, Vector3(0, -thigh_length, 0))
	_add_box(knee, Vector3(limb_thickness * 1.1, shin_length, limb_thickness * 1.1), Vector3(0, -shin_length * 0.5, 0), accent_material)
	var foot := _add_pivot(knee, "Foot%s" % suffix, Vector3(0, -shin_length, 0))
	_add_box(foot, Vector3(limb_thickness * 1.3, limb_thickness * 0.7, limb_thickness * 2.4), Vector3(0, -limb_thickness * 0.35, -limb_thickness * 0.7), accent_material)


func _add_hair(head: Node3D, app: CharacterAppearance, head_size: float, hair_material: StandardMaterial3D) -> void:
	match app.hair_style:
		CharacterAppearance.HairStyle.SHORT:
			_add_box(head, Vector3(head_size * 1.02, head_size * 0.28, head_size * 1.02), Vector3(0, head_size * 0.92, 0), hair_material)
		CharacterAppearance.HairStyle.BUN:
			_add_box(head, Vector3(head_size * 1.0, head_size * 0.18, head_size * 1.0), Vector3(0, head_size * 0.87, 0), hair_material)
			var bun := MeshInstance3D.new()
			bun.name = "HairBun"
			var mesh := SphereMesh.new()
			mesh.radius = head_size * 0.22
			mesh.height = head_size * 0.44
			bun.mesh = mesh
			bun.position = Vector3(0, head_size * 0.6, head_size * 0.6)
			bun.material_override = hair_material
			head.add_child(bun)
		CharacterAppearance.HairStyle.NONE:
			pass


func _add_head_equipment(head: Node3D, app: CharacterAppearance, head_size: float) -> void:
	match app.head_equipment:
		CharacterAppearance.HeadEquipment.CAP:
			var cap_material := _make_material(app.clothing_secondary_color)
			_add_box(head, Vector3(head_size * 1.05, head_size * 0.32, head_size * 1.05), Vector3(0, head_size * 0.94, 0), cap_material)
			_add_box(head, Vector3(head_size * 0.4, head_size * 0.06, head_size * 0.35), Vector3(0, head_size * 0.82, -head_size * 0.65), cap_material)
		CharacterAppearance.HeadEquipment.RESCUE_HELMET:
			var shell_material := _make_material(RESCUE_HELMET_SHELL_COLOR)
			var brim_material := _make_material(RESCUE_HELMET_BRIM_COLOR)
			_add_box(head, Vector3(head_size * 1.15, head_size * 0.55, head_size * 1.15), Vector3(0, head_size * 1.0, 0), shell_material)
			_add_box(head, Vector3(head_size * 1.3, head_size * 0.08, head_size * 1.3), Vector3(0, head_size * 0.75, 0), brim_material)
		CharacterAppearance.HeadEquipment.NONE:
			pass


func _add_pivot(parent: Node3D, joint_name: String, local_position: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = joint_name
	pivot.position = local_position
	parent.add_child(pivot)
	_joints[joint_name] = pivot
	_rest_rotations[joint_name] = pivot.rotation
	return pivot


func _add_box(parent: Node3D, size: Vector3, local_position: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = "%sMesh" % parent.name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
