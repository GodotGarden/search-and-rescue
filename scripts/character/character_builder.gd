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
var _silhouette_enabled := false
var _silhouette_material: StandardMaterial3D
## True after set_exact_pose()/set_kneel_one_knee_pose() and before the next
## set_locomotion_input() call. Suspends the automatic per-physics-frame _locomotion.update() below
## so a held/static pose isn't overwritten one tick later by update() running with whatever stale
## _horizontal_velocity/_grounded this model happens to hold (zero/true by default — exactly the
## idle pose, which silently clobbered both the existing pose_speed preview cases and the new
## kneel_one_knee pose before this flag existed). Real gameplay is unaffected: responder.gd calls
## set_locomotion_input() every physics frame, which clears this immediately.
var _pose_held := false


func _ready() -> void:
	build(appearance if appearance != null else CharacterAppearance.new())


func _physics_process(delta: float) -> void:
	if _locomotion != null and not _pose_held:
		_locomotion.update(delta, _horizontal_velocity, _grounded)


## Called once per physics frame by the owning body; horizontal_velocity is world-space, y ignored.
func set_locomotion_input(horizontal_velocity: Vector3, grounded: bool) -> void:
	_horizontal_velocity = horizontal_velocity
	_grounded = grounded
	_pose_held = false


## Local/remote disambiguation is a rendering layer applied on top of appearance, not a cosmetic field.
func set_identity_color(color: Color) -> void:
	if _identity_material != null:
		_identity_material.albedo_color = color


## Sets an exact, reproducible pose for preview/capture tooling — no delta-time integration.
## gait_phase_normalized/idle_phase_normalized are 0..1 (fraction of a full gait/sway cycle).
## See "Character animation contract" in docs/specifications/procedural-preview-lab.md.
func set_exact_pose(gait_phase_normalized: float, speed: float, grounded: bool, idle_phase_normalized: float = 0.0) -> void:
	if _locomotion != null:
		_locomotion.set_exact_pose(gait_phase_normalized * TAU, speed, grounded, idle_phase_normalized * TAU)
		_pose_held = true


## Static "one knee down" interaction pose — see the rig-limitation note on
## ProceduralLocomotion.apply_kneel_one_knee_pose() (does not lower the model root, so the
## kneeling knee will not literally touch the ground plane).
func set_kneel_one_knee_pose(kneeling_leg_left: bool = false) -> void:
	if _locomotion != null:
		_locomotion.apply_kneel_one_knee_pose(kneeling_leg_left)
		_pose_held = true


## Flat, unshaded, single-color materials on every mesh — for silhouette/proportion review.
## Re-applied automatically if the rig is rebuilt (build()) while enabled.
func set_silhouette_mode(enabled: bool) -> void:
	_silhouette_enabled = enabled
	_apply_silhouette_mode()


## Combined AABB of every visible mesh, in this node's own local space (not world space) —
## for preview camera fit-to-subject framing.
func get_visual_aabb() -> AABB:
	var combined := AABB()
	var first := true
	var world_to_local := global_transform.affine_inverse()
	for mesh_instance in _find_mesh_instances(self):
		var local_transform: Transform3D = world_to_local * mesh_instance.global_transform
		var mesh_aabb: AABB = local_transform * mesh_instance.get_aabb()
		if first:
			combined = mesh_aabb
			first = false
		else:
			combined = combined.merge(mesh_aabb)
	return combined


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
	if _silhouette_enabled:
		_apply_silhouette_mode()


func _build_rig(app: CharacterAppearance) -> void:
	# Girth constants below were tuned at the 1.75 m reference height; scale with height too,
	# not just build, so a tall character doesn't get proportionally lankier than a short one.
	var height_scale := app.height_m / 1.75
	var girth := lerpf(0.8, 1.3, app.build) * height_scale
	var leg_length := app.height_m * 0.45
	var thigh_length := leg_length * 0.5
	var shin_length := leg_length * 0.5
	var torso_height := app.height_m * 0.315
	var neck_length := app.height_m * 0.022
	var head_size := app.height_m * 0.14 * app.head_scale
	var arm_length := app.height_m * 0.38
	var upper_arm_length := arm_length * 0.5
	var forearm_length := arm_length * 0.5
	var hip_half_width := 0.13 * girth
	var shoulder_half_width := hip_half_width * app.shoulder_hip_ratio
	# Chest is deliberately wider than the waist and shoulders are pulled out from
	# the torso centerline so the jacket, waist seam, and sleeves all read as
	# separate parts rather than one long box. See docs/character-appearance-visual-design.md.
	var chest_half_width := shoulder_half_width * 1.08
	var waist_half_width := hip_half_width * 0.95
	var stance_half_width := waist_half_width * 1.08
	var torso_depth := 0.15 * girth
	var limb_thickness := 0.085 * girth
	var shoulder_reach := chest_half_width + limb_thickness * 0.55

	var jacket_material := _make_material(app.clothing_primary_color)
	var trouser_material := _make_material(app.clothing_secondary_color)
	var accent_material := _make_material(app.accent_color)
	var skin_material := _make_material(app.skin_color)
	var hair_material := _make_material(app.hair_color)

	var pelvis := _add_pivot(self, "Pelvis", Vector3(0, leg_length, 0))
	_add_box(pelvis, Vector3(waist_half_width * 2.0, torso_height * 0.22, torso_depth), Vector3(0, torso_height * 0.11, 0), trouser_material)

	var torso := _add_pivot(pelvis, "Torso", Vector3(0, torso_height * 0.22, 0))
	_add_box(torso, Vector3(chest_half_width * 2.0, torso_height * 0.56, torso_depth), Vector3(0, torso_height * 0.52, 0), jacket_material)
	# Jacket waist taper: a second, narrower layer between the chest and the belt so the
	# torso reads as a tailored garment (chest -> taper -> belt), not one flat slab.
	var jacket_waist_half_width := chest_half_width * 0.9
	_add_box(torso, Vector3(jacket_waist_half_width * 2.0, torso_height * 0.24, torso_depth * 0.96), Vector3(0, torso_height * 0.12, 0), jacket_material)
	# Belt/hem line at the jacket-to-trousers seam (goal 1: a visible waist break).
	_add_box(torso, Vector3(jacket_waist_half_width * 2.05, torso_height * 0.06, torso_depth + 0.01), Vector3.ZERO, trouser_material)
	# High-visibility chest band: fully encircles the torso (front/back/sides), like the belt
	# below it, so it stays readable from any camera angle instead of vanishing in profile/rear.
	_add_box(torso, Vector3(chest_half_width * 2.05, torso_height * 0.1, torso_depth + 0.01), Vector3(0, torso_height * 0.34, 0), accent_material)

	# Local/remote identity color (set_identity_color) needs to read at gameplay distance from
	# any angle a teammate might see this character from, so it's applied to a front badge and a
	# larger back panel — both share one material so set_identity_color() recolors them together.
	var identity_material := _make_material(Color.WHITE)
	_add_box(torso, Vector3(chest_half_width * 0.7, torso_height * 0.14, 0.02), Vector3(0, torso_height * 0.55, -torso_depth * 0.5 - 0.01), identity_material)
	# Kept within chest_half_width so the panel stays flush with the torso's side silhouette
	# instead of overhanging and reading as a detached floating card from angled/side views.
	_add_box(torso, Vector3(chest_half_width * 0.9, torso_height * 0.3, 0.02), Vector3(0, torso_height * 0.55, torso_depth * 0.5 + 0.01), identity_material)
	_identity_material = identity_material

	var neck := _add_pivot(torso, "Neck", Vector3(0, torso_height * 0.8, 0))
	_add_box(neck, Vector3(head_size * 0.42, neck_length, head_size * 0.42), Vector3(0, neck_length * 0.5, 0), skin_material)
	var head := _add_pivot(neck, "Head", Vector3(0, neck_length, 0))
	_add_box(head, Vector3(head_size, head_size, head_size), Vector3(0, head_size * 0.5, 0), skin_material)
	if app.head_equipment == CharacterAppearance.HeadEquipment.NONE:
		_add_hair(head, app, head_size, hair_material)
	_add_head_equipment(head, app, head_size)
	_add_pivot(head, "HeadSocket", Vector3(0, head_size, 0))
	_add_pivot(pelvis, "HipSocket", Vector3.ZERO)

	_build_arm(torso, true, torso_height, upper_arm_length, forearm_length, limb_thickness, shoulder_reach, jacket_material, trouser_material, accent_material)
	_build_arm(torso, false, torso_height, upper_arm_length, forearm_length, limb_thickness, shoulder_reach, jacket_material, trouser_material, accent_material)
	_build_leg(pelvis, true, stance_half_width, thigh_length, shin_length, limb_thickness, trouser_material, accent_material)
	_build_leg(pelvis, false, stance_half_width, thigh_length, shin_length, limb_thickness, trouser_material, accent_material)


func _build_arm(torso: Node3D, is_left: bool, torso_height: float, upper_arm_length: float, forearm_length: float, limb_thickness: float, shoulder_reach: float, jacket_material: StandardMaterial3D, trouser_material: StandardMaterial3D, accent_material: StandardMaterial3D) -> void:
	var side_x := -1.0 if is_left else 1.0
	var suffix := "L" if is_left else "R"
	# Rest pose holds the arm slightly away from the torso (goal 5); locomotion only
	# ever touches rotation.x, so this Z-axis abduction is a fixed offset it never overwrites.
	var shoulder_rest := Vector3(0, 0, side_x * deg_to_rad(9))
	var shoulder := _add_pivot(torso, "Shoulder%s" % suffix, Vector3(side_x * shoulder_reach, torso_height * 0.76, 0), shoulder_rest)
	_add_box(shoulder, Vector3(limb_thickness * 1.55, upper_arm_length, limb_thickness * 1.55), Vector3(0, -upper_arm_length * 0.5, 0), jacket_material)
	var elbow_rest := Vector3(deg_to_rad(16), 0, 0)
	var elbow := _add_pivot(shoulder, "Elbow%s" % suffix, Vector3(0, -upper_arm_length, 0), elbow_rest)
	_add_box(elbow, Vector3(limb_thickness * 1.2, forearm_length * 0.82, limb_thickness * 1.2), Vector3(0, -forearm_length * 0.41, 0), jacket_material)
	# Reflective cuff band marks the sleeve-to-glove break at the wrist (goal 2).
	_add_box(elbow, Vector3(limb_thickness * 1.25, forearm_length * 0.16, limb_thickness * 1.25), Vector3(0, -forearm_length * 0.9, 0), accent_material)
	var hand := _add_pivot(elbow, "Hand%s" % suffix, Vector3(0, -forearm_length, 0))
	_add_box(hand, Vector3(limb_thickness * 1.2, limb_thickness * 1.4, limb_thickness * 1.0), Vector3(0, -limb_thickness * 0.65, 0), trouser_material)


func _build_leg(pelvis: Node3D, is_left: bool, stance_half_width: float, thigh_length: float, shin_length: float, limb_thickness: float, trouser_material: StandardMaterial3D, accent_material: StandardMaterial3D) -> void:
	var side_x := -1.0 if is_left else 1.0
	var suffix := "L" if is_left else "R"
	var hip := _add_pivot(pelvis, "Hip%s" % suffix, Vector3(side_x * stance_half_width, 0, 0))
	_add_box(hip, Vector3(limb_thickness * 1.75, thigh_length, limb_thickness * 1.75), Vector3(0, -thigh_length * 0.5, 0), trouser_material)
	var knee := _add_pivot(hip, "Knee%s" % suffix, Vector3(0, -thigh_length, 0))
	_add_box(knee, Vector3(limb_thickness * 1.45, shin_length * 0.84, limb_thickness * 1.45), Vector3(0, -shin_length * 0.42, 0), trouser_material)
	# Reflective ankle band: the "lower legs" safety-accent placement (goal 3).
	_add_box(knee, Vector3(limb_thickness * 1.55, shin_length * 0.14, limb_thickness * 1.55), Vector3(0, -shin_length * 0.91, 0), accent_material)
	# Toes angled very slightly outward at rest (goal 5); Foot is never touched by locomotion.
	var foot_rest := Vector3(0, side_x * deg_to_rad(7), 0)
	var foot := _add_pivot(knee, "Foot%s" % suffix, Vector3(0, -shin_length, 0), foot_rest)
	_add_box(foot, Vector3(limb_thickness * 1.7, limb_thickness * 1.0, limb_thickness * 2.8), Vector3(0, -limb_thickness * 0.45, -limb_thickness * 0.8), trouser_material)


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
			_add_rescue_helmet(head, head_size)
		CharacterAppearance.HeadEquipment.NONE:
			pass


## Low-segment faceted dome + brim (goal 4): a helmet silhouette, not a box stacked on a box.
func _add_rescue_helmet(head: Node3D, head_size: float) -> void:
	var shell_material := _make_material(RESCUE_HELMET_SHELL_COLOR)
	var brim_material := _make_material(RESCUE_HELMET_BRIM_COLOR)

	var dome := MeshInstance3D.new()
	dome.name = "HelmetDome"
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = head_size * 0.64
	dome_mesh.height = head_size * 0.64
	dome_mesh.radial_segments = 8
	dome_mesh.rings = 6
	dome_mesh.is_hemisphere = true
	dome.mesh = dome_mesh
	dome.position = Vector3(0, head_size * 0.98, 0)
	dome.material_override = shell_material
	head.add_child(dome)

	var brim := MeshInstance3D.new()
	brim.name = "HelmetBrim"
	var brim_mesh := CylinderMesh.new()
	brim_mesh.top_radius = head_size * 0.8
	brim_mesh.bottom_radius = head_size * 0.8
	brim_mesh.height = head_size * 0.07
	brim_mesh.radial_segments = 8
	brim.mesh = brim_mesh
	brim.position = Vector3(0, head_size * 0.94, 0)
	brim.material_override = brim_material
	head.add_child(brim)


func _apply_silhouette_mode() -> void:
	for mesh_instance in _find_mesh_instances(self):
		if _silhouette_enabled:
			if not mesh_instance.has_meta("_original_material"):
				mesh_instance.set_meta("_original_material", mesh_instance.material_override)
			mesh_instance.material_override = _get_silhouette_material()
		elif mesh_instance.has_meta("_original_material"):
			mesh_instance.material_override = mesh_instance.get_meta("_original_material")
			mesh_instance.remove_meta("_original_material")


func _get_silhouette_material() -> StandardMaterial3D:
	if _silhouette_material == null:
		_silhouette_material = StandardMaterial3D.new()
		_silhouette_material.albedo_color = Color.BLACK
		_silhouette_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _silhouette_material


func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child)
		result.append_array(_find_mesh_instances(child))
	return result


func _add_pivot(parent: Node3D, joint_name: String, local_position: Vector3, rest_rotation: Vector3 = Vector3.ZERO) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = joint_name
	pivot.position = local_position
	pivot.rotation = rest_rotation
	parent.add_child(pivot)
	_joints[joint_name] = pivot
	_rest_rotations[joint_name] = rest_rotation
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
