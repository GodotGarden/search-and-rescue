extends Node3D

## Dev harness for previewing procedural CharacterModel appearances outside of gameplay.
## See docs/specifications/procedural-preview-lab.md for the design this implements.
##
## Two modes:
## - Row mode (default): renders one or more CharacterAppearance resources side by side.
##   Run: godot --path . res://scenes/dev/character_preview.tscn --resolution 1600x1000 --quit-after 15
## - Batch case mode: set `cases` to one or more PreviewCase resource paths; each runs in
##   sequence with its own appearance, pose, camera view, and stage preset, writing a PNG +
##   JSON metadata sidecar per case.
##   Run: godot --path . res://scenes/dev/character_preview.tscn --quit-after 60 \
##        -- cases=res://resources/preview_cases/responder_default_front.tres,res://resources/preview_cases/responder_default_walk_contact.tres
##
## Override any @export below via CLI user args, e.g.:
## -- output_path=/tmp/out.png appearance_paths=res://resources/character/appearance_tall_guide.tres

const CharacterAppearance := preload("res://scripts/character/character_appearance.gd")
const CharacterModelScene := preload("res://scenes/character/CharacterModel.tscn")
const PreviewCase := preload("res://scripts/dev/preview_case.gd")

## Vertical FOV used when framing fit-to-subject camera views (not the gameplay-camera preset).
const FIT_FOV_DEGREES := 50.0
## Extra breathing room around the fitted subject, as a multiple of the tight-fit distance.
const FIT_MARGIN := 1.3
## Mirrors scenes/player/Responder.tscn's CameraPivot/SpringArm3D/Camera3D for the
## gameplay-camera preset: spring_length=4.5, CameraPivot rotation.x=-0.2, fov=70.
const GAMEPLAY_SPRING_LENGTH := 4.5
const GAMEPLAY_PIVOT_PITCH := -0.2
const GAMEPLAY_CAMERA_FOV := 70.0

@export_dir var appearance_dir: String = "res://resources/character/"
## Row mode: explicit resource list; overrides appearance_dir (all *.tres in it, sorted) when non-empty.
@export var appearance_paths: Array[String] = []
## Batch mode: one or more PreviewCase resource paths. Non-empty switches the harness to batch mode.
@export var cases: Array[String] = []
@export var output_path: String = "res://dev-output/character_preview.png"
@export var spacing: float = 1.4

@export var stage_preset: PreviewCase.StagePreset = PreviewCase.StagePreset.NEUTRAL_REVIEW
@export var camera_view: PreviewCase.CameraView = PreviewCase.CameraView.FRONT
## False uses camera_position/camera_target verbatim instead of fitting to the subject's bounds.
@export var use_fit_camera: bool = true
@export var camera_position: Vector3 = Vector3(0, 1.1, -3.4)
@export var camera_target: Vector3 = Vector3(0, 1.0, 0)

@export var ground_size: float = 10.0
@export var show_grid: bool = true

## Row mode pose, applied once (not simulated) unless live_playback is true. Normalized 0..1
## gait phase; see "Character animation contract" in docs/specifications/procedural-preview-lab.md.
@export_range(0.0, 1.0) var pose_phase: float = 0.0
@export var pose_speed: float = 0.0
@export var pose_grounded: bool = true
## True continuously drives locomotion instead of holding pose_phase — for eyeballing a walk/run
## cycle in a windowed run. Capture then grabs whatever phase playback has reached, so this is not
## reproducible; leave false for deterministic captures.
@export var live_playback: bool = false

## Frames to wait after building/posing before capturing, so shadows/materials settle. Not a
## pose-timing mechanism (see character animation contract above).
@export var capture_settle_frames: int = 8
@export var quit_after_capture: bool = true

var _environment: Environment
var _light: DirectionalLight3D
var _ground: MeshInstance3D
var _grid: MeshInstance3D
var _camera: Camera3D

# Row mode state.
var _models: Array = []
var _row_appearance_paths: Array[String] = []
var _row_frames := 0

# Batch mode state.
var _batch_cases: Array[PreviewCase] = []
var _batch_index := -1
var _batch_model: Node3D = null
var _batch_settle_frame := 0

var _mode := "row"


func _ready() -> void:
	_parse_cli_overrides()
	_build_environment()
	if not cases.is_empty():
		_mode = "batch"
		_start_batch_mode()
	else:
		_mode = "row"
		_start_row_mode()


func _parse_cli_overrides() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		if parts.size() != 2:
			continue
		var key := parts[0]
		var value := parts[1]
		match key:
			"appearance_dir":
				appearance_dir = value
			"appearance_paths":
				appearance_paths = _split_to_string_array(value)
			"cases":
				cases = _split_to_string_array(value)
			"output_path":
				output_path = value
			"spacing":
				spacing = value.to_float()
			"stage_preset":
				stage_preset = _parse_enum_value(PreviewCase.StagePreset.keys(), value, stage_preset, "stage_preset") as PreviewCase.StagePreset
			"camera_view":
				camera_view = _parse_enum_value(PreviewCase.CameraView.keys(), value, camera_view, "camera_view") as PreviewCase.CameraView
			"use_fit_camera":
				use_fit_camera = value.to_lower() != "false"
			"camera_position":
				camera_position = _parse_vector3(value, camera_position)
			"camera_target":
				camera_target = _parse_vector3(value, camera_target)
			"ground_size":
				ground_size = value.to_float()
			"show_grid":
				show_grid = value.to_lower() != "false"
			"pose_phase":
				pose_phase = value.to_float()
			"pose_speed":
				pose_speed = value.to_float()
			"pose_grounded":
				pose_grounded = value.to_lower() != "false"
			"live_playback":
				live_playback = value.to_lower() == "true"
			"capture_settle_frames":
				capture_settle_frames = value.to_int()
			_:
				push_warning("Unknown character_preview override: %s" % key)


func _split_to_string_array(value: String) -> Array[String]:
	var typed: Array[String] = []
	for part in value.split(","):
		typed.append(part)
	return typed


func _parse_enum_value(keys: PackedStringArray, value: String, fallback: int, field_name: String) -> int:
	var idx := keys.find(value.to_upper())
	if idx == -1:
		push_warning("Unknown %s override: %s" % [field_name, value])
		return fallback
	return idx


func _parse_vector3(value: String, fallback: Vector3) -> Vector3:
	var parts := value.split(",")
	if parts.size() != 3:
		push_warning("Expected \"x,y,z\" for a Vector3 override, got: %s" % value)
		return fallback
	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())


# --- Shared stage -----------------------------------------------------------------------------


func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment = environment
	add_child(env)
	_environment = environment

	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-30), 0)
	light.light_energy = 1.2
	add_child(light)
	_light = light

	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(ground_size, ground_size)
	ground.mesh = ground_mesh
	ground.material_override = _make_ground_material()
	add_child(ground)
	_ground = ground

	_grid = _build_ground_grid()
	add_child(_grid)

	var camera := Camera3D.new()
	add_child(camera)
	camera.current = true
	_camera = camera


func _make_ground_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.42, 0.44, 0.4)
	material.roughness = 1.0
	return material


func _build_ground_grid() -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	var points := PackedVector3Array()
	var half := ground_size * 0.5
	var step := 1.0
	var y := 0.002
	var x := -half
	while x <= half + 0.001:
		points.append(Vector3(x, y, -half))
		points.append(Vector3(x, y, half))
		x += step
	var z := -half
	while z <= half + 0.001:
		points.append(Vector3(-half, y, z))
		points.append(Vector3(half, y, z))
		z += step
	arrays[Mesh.ARRAY_VERTEX] = points
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	var grid := MeshInstance3D.new()
	grid.name = "Grid"
	grid.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.2)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid.material_override = material
	return grid


func _apply_stage_preset(preset: PreviewCase.StagePreset) -> void:
	match preset:
		PreviewCase.StagePreset.SILHOUETTE:
			_environment.background_color = Color(0.92, 0.93, 0.95)
			_environment.ambient_light_color = Color(1, 1, 1)
			_environment.ambient_light_energy = 1.4
			_light.shadow_enabled = false
			_ground.visible = false
			_grid.visible = false
		_:
			_environment.background_color = Color(0.55, 0.6, 0.65)
			_environment.ambient_light_color = Color(0.6, 0.6, 0.65)
			_environment.ambient_light_energy = 0.9
			_light.shadow_enabled = true
			_ground.visible = true
			_grid.visible = show_grid


# --- Camera framing ----------------------------------------------------------------------------


func _compute_view_transform(aabb: AABB, view: PreviewCase.CameraView) -> Dictionary:
	var center := aabb.get_center()
	var extent := maxf(aabb.get_longest_axis_size() * 0.5, 0.2)
	var distance := (extent / tan(deg_to_rad(FIT_FOV_DEGREES * 0.5))) * FIT_MARGIN
	var eye_height := center.y + aabb.size.y * 0.08
	var cam_position: Vector3
	match view:
		PreviewCase.CameraView.REAR:
			cam_position = Vector3(center.x, eye_height, center.z + distance)
		PreviewCase.CameraView.SIDE_LEFT:
			cam_position = Vector3(center.x - distance, eye_height, center.z)
		PreviewCase.CameraView.SIDE_RIGHT:
			cam_position = Vector3(center.x + distance, eye_height, center.z)
		PreviewCase.CameraView.THREE_QUARTER:
			var dir := Vector3(0.65, 0.0, -0.76).normalized()
			cam_position = Vector3(center.x, eye_height, center.z) + dir * distance
		_: # FRONT
			cam_position = Vector3(center.x, eye_height, center.z - distance)
	return {"position": cam_position, "target": center}


## Approximates scenes/player/Responder.tscn's third-person chase camera around this model.
func _compute_gameplay_camera(model: Node3D) -> Dictionary:
	var head_socket: Node3D = model.get_head_socket()
	var pivot_height: float = head_socket.global_position.y if head_socket != null else model.global_position.y + 1.5
	var pivot_position := Vector3(model.global_position.x, pivot_height, model.global_position.z)
	var forward := Vector3(0, sin(GAMEPLAY_PIVOT_PITCH), -cos(GAMEPLAY_PIVOT_PITCH))
	var cam_position := pivot_position - forward * GAMEPLAY_SPRING_LENGTH
	return {"position": cam_position, "target": pivot_position}


func _world_aabb(model: Node3D) -> AABB:
	var local_aabb: AABB = model.get_visual_aabb()
	return AABB(local_aabb.position + model.global_position, local_aabb.size)


func _apply_camera(view: Dictionary, fov: float) -> void:
	_camera.position = view.position
	_camera.look_at(view.target, Vector3.UP)
	_camera.fov = fov


# --- Row mode ------------------------------------------------------------------------------


func _resolve_appearance_paths() -> Array[String]:
	if not appearance_paths.is_empty():
		return appearance_paths
	var paths: Array[String] = []
	var dir := DirAccess.open(appearance_dir)
	if dir == null:
		push_error("Cannot open appearance_dir: %s" % appearance_dir)
		return paths
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			paths.append(appearance_dir.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


func _start_row_mode() -> void:
	_apply_stage_preset(stage_preset)
	var candidate_paths := _resolve_appearance_paths()
	if candidate_paths.is_empty():
		push_warning("character_preview: no CharacterAppearance resources found (dir=%s)" % appearance_dir)

	# Load valid appearances first so a skipped/invalid resource doesn't leave uneven spacing
	# in the row (see "Immediate improvements to the current harness").
	var valid_appearances: Array = []
	var valid_paths: Array[String] = []
	for path in candidate_paths:
		var appearance: CharacterAppearance = load(path)
		if appearance == null:
			push_warning("Skipping non-CharacterAppearance resource: %s" % path)
			continue
		valid_appearances.append(appearance)
		valid_paths.append(path)

	var count := valid_appearances.size()
	for i in range(count):
		var model := CharacterModelScene.instantiate()
		# Set appearance before add_child so _ready() builds the requested appearance once,
		# instead of building the default appearance and immediately rebuilding it.
		model.appearance = valid_appearances[i]
		add_child(model)
		model.position = Vector3((i - (count - 1) / 2.0) * spacing, 0, 0)
		if not live_playback:
			model.set_exact_pose(pose_phase, pose_speed, pose_grounded)
		model.set_silhouette_mode(stage_preset == PreviewCase.StagePreset.SILHOUETTE)
		_models.append(model)
	_row_appearance_paths = valid_paths

	_position_row_camera()


func _position_row_camera() -> void:
	if not use_fit_camera:
		_apply_camera({"position": camera_position, "target": camera_target}, _camera.fov)
		return
	if _models.is_empty():
		return
	if stage_preset == PreviewCase.StagePreset.GAMEPLAY_CAMERA and _models.size() == 1:
		_apply_camera(_compute_gameplay_camera(_models[0]), GAMEPLAY_CAMERA_FOV)
		return
	var combined: AABB = _world_aabb(_models[0])
	for i in range(1, _models.size()):
		combined = combined.merge(_world_aabb(_models[i]))
	_apply_camera(_compute_view_transform(combined, camera_view), FIT_FOV_DEGREES)


func _physics_process(_delta: float) -> void:
	if _mode == "row" and live_playback:
		for model in _models:
			model.set_locomotion_input(Vector3(0, 0, -pose_speed), pose_grounded)


func _process_row_frame() -> void:
	_row_frames += 1
	if _row_frames == capture_settle_frames:
		var appearances_meta: Array = []
		for i in range(_models.size()):
			var appearance: CharacterAppearance = _models[i].appearance
			appearances_meta.append({
				"appearance_path": _row_appearance_paths[i] if i < _row_appearance_paths.size() else "",
				"generator_version": appearance.generator_version,
				"payload": _json_safe_payload(appearance.to_payload()),
			})
		_capture_and_write(output_path, {
			"mode": "row",
			"appearances": appearances_meta,
			"camera_view": PreviewCase.CameraView.keys()[camera_view].to_lower(),
			"stage_preset": PreviewCase.StagePreset.keys()[stage_preset].to_lower(),
			"pose_phase": pose_phase,
			"pose_speed": pose_speed,
			"pose_grounded": pose_grounded,
			"live_playback": live_playback,
		})
	if quit_after_capture and _row_frames >= capture_settle_frames + 2:
		get_tree().quit()


# --- Batch case mode -------------------------------------------------------------------------


func _load_cases() -> Array[PreviewCase]:
	var result: Array[PreviewCase] = []
	for path in cases:
		var preview_case: PreviewCase = load(path)
		if preview_case == null:
			push_warning("Skipping invalid PreviewCase resource: %s" % path)
			continue
		result.append(preview_case)
	return result


func _start_batch_mode() -> void:
	_batch_cases = _load_cases()
	if _batch_cases.is_empty():
		push_warning("character_preview: no valid PreviewCase resources loaded from `cases`")
		if quit_after_capture:
			get_tree().quit()
		return
	_advance_batch_case()


func _advance_batch_case() -> void:
	if _batch_model != null:
		_batch_model.queue_free()
		_batch_model = null
	_batch_index += 1
	if _batch_index >= _batch_cases.size():
		if quit_after_capture:
			get_tree().quit()
		return
	_setup_batch_case(_batch_cases[_batch_index])
	_batch_settle_frame = 0


func _setup_batch_case(preview_case: PreviewCase) -> void:
	var appearance: CharacterAppearance = load(preview_case.appearance_path)
	if appearance == null:
		push_warning("Skipping case '%s': cannot load appearance %s" % [preview_case.case_name, preview_case.appearance_path])
		_advance_batch_case()
		return

	_apply_stage_preset(preview_case.stage_preset)

	var model := CharacterModelScene.instantiate()
	model.appearance = appearance
	add_child(model)
	model.position = Vector3.ZERO
	model.set_exact_pose(preview_case.pose_phase, preview_case.pose_speed, preview_case.pose_grounded)
	model.set_silhouette_mode(preview_case.stage_preset == PreviewCase.StagePreset.SILHOUETTE)
	_batch_model = model

	if preview_case.stage_preset == PreviewCase.StagePreset.GAMEPLAY_CAMERA:
		_apply_camera(_compute_gameplay_camera(model), GAMEPLAY_CAMERA_FOV)
	else:
		_apply_camera(_compute_view_transform(_world_aabb(model), preview_case.camera_view), FIT_FOV_DEGREES)


func _process_batch_frame() -> void:
	if _batch_index < 0 or _batch_index >= _batch_cases.size():
		return
	_batch_settle_frame += 1
	if _batch_settle_frame == capture_settle_frames:
		var preview_case: PreviewCase = _batch_cases[_batch_index]
		var appearance: CharacterAppearance = _batch_model.appearance
		_capture_and_write(preview_case.get_output_path(), {
			"mode": "case",
			"case_name": preview_case.case_name,
			"appearance_path": preview_case.appearance_path,
			"generator_version": appearance.generator_version,
			"payload": _json_safe_payload(appearance.to_payload()),
			"camera_view": preview_case.get_camera_view_name(),
			"stage_preset": preview_case.get_stage_preset_name(),
			"pose_phase": preview_case.pose_phase,
			"pose_speed": preview_case.pose_speed,
			"pose_grounded": preview_case.pose_grounded,
		})
	elif _batch_settle_frame > capture_settle_frames:
		_advance_batch_case()


# --- Capture -----------------------------------------------------------------------------------


func _process(_delta: float) -> void:
	if _mode == "batch":
		_process_batch_frame()
	else:
		_process_row_frame()


func _json_safe_payload(payload: Dictionary) -> Dictionary:
	var safe := {}
	for key in payload.keys():
		var value = payload[key]
		safe[key] = value.to_html() if value is Color else value
	return safe


func _capture_and_write(destination: String, metadata: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(destination)
	if err != OK:
		push_error("Failed to save preview screenshot to %s (error %d)" % [destination, err])
		return
	print("Saved preview screenshot to %s" % ProjectSettings.globalize_path(destination))

	metadata["output_path"] = ProjectSettings.globalize_path(destination)
	metadata["captured_at"] = Time.get_datetime_string_from_system(true)
	var json_path := destination.get_basename() + ".json"
	var file := FileAccess.open(json_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write metadata sidecar to %s" % json_path)
		return
	file.store_string(JSON.stringify(metadata, "\t"))
	file.close()
