extends Node3D

## Dev harness for previewing procedural CharacterModel appearances outside of gameplay:
## renders one or more CharacterAppearance resources side by side and saves a screenshot.
## Run: godot --path . res://scenes/dev/character_preview.tscn --resolution 1600x1000 --quit-after 15
## Override any @export below via CLI user args, e.g.:
## -- output_path=/tmp/out.png appearance_paths=res://resources/character/appearance_tall_guide.tres

const CharacterAppearance := preload("res://scripts/character/character_appearance.gd")
const CharacterModelScene := preload("res://scenes/character/CharacterModel.tscn")

@export_dir var appearance_dir: String = "res://resources/character/"
## Explicit resource list; overrides appearance_dir (all *.tres in it, sorted) when non-empty.
@export var appearance_paths: Array[String] = []
@export var output_path: String = "res://dev-output/character_preview.png"
@export var spacing: float = 1.4
@export var camera_position: Vector3 = Vector3(0, 1.1, -3.4)
@export var camera_target: Vector3 = Vector3(0, 1.0, 0)
@export var ground_size: float = 10.0
## Horizontal speed (m/s) fed to each model's locomotion; 0 keeps the idle rest pose.
@export var simulate_walk_speed: float = 0.0
## False feeds grounded=false to locomotion every frame, blending to the airborne/jump pose.
@export var simulate_grounded: bool = true
@export var capture_delay_frames: int = 8
@export var quit_after_capture: bool = true

var _frames := 0
var _models: Array = []


func _ready() -> void:
	_parse_cli_overrides()
	_build_environment()
	_build_models()
	_build_camera()


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
				var typed_paths: Array[String] = []
				for path in value.split(","):
					typed_paths.append(path)
				appearance_paths = typed_paths
			"output_path":
				output_path = value
			"spacing":
				spacing = value.to_float()
			"ground_size":
				ground_size = value.to_float()
			"camera_position":
				camera_position = _parse_vector3(value, camera_position)
			"camera_target":
				camera_target = _parse_vector3(value, camera_target)
			"simulate_walk_speed":
				simulate_walk_speed = value.to_float()
			"simulate_grounded":
				simulate_grounded = value.to_lower() != "false"
			"capture_delay_frames":
				capture_delay_frames = value.to_int()
			_:
				push_warning("Unknown character_preview override: %s" % key)


func _parse_vector3(value: String, fallback: Vector3) -> Vector3:
	var parts := value.split(",")
	if parts.size() != 3:
		push_warning("Expected \"x,y,z\" for a Vector3 override, got: %s" % value)
		return fallback
	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())


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


func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.6, 0.65)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	environment.ambient_light_energy = 0.9
	env.environment = environment
	add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-30), 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)

	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(ground_size, ground_size)
	ground.mesh = ground_mesh
	ground.material_override = _make_ground_material()
	add_child(ground)


func _make_ground_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.42, 0.44, 0.4)
	material.roughness = 1.0
	return material


func _build_models() -> void:
	var paths := _resolve_appearance_paths()
	if paths.is_empty():
		push_warning("character_preview: no CharacterAppearance resources found (dir=%s)" % appearance_dir)
	var i := 0
	for path in paths:
		var appearance: CharacterAppearance = load(path)
		if appearance == null:
			push_warning("Skipping non-CharacterAppearance resource: %s" % path)
			continue
		var model := CharacterModelScene.instantiate()
		add_child(model)
		model.position = Vector3((i - (paths.size() - 1) / 2.0) * spacing, 0, 0)
		model.appearance = appearance
		model.build(appearance)
		_models.append(model)
		i += 1


func _build_camera() -> void:
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = camera_position
	camera.look_at(camera_target, Vector3.UP)
	camera.current = true


func _physics_process(_delta: float) -> void:
	for model in _models:
		model.set_locomotion_input(Vector3(0, 0, -simulate_walk_speed), simulate_grounded)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == capture_delay_frames:
		DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
		var image := get_viewport().get_texture().get_image()
		var err := image.save_png(output_path)
		if err == OK:
			print("Saved preview screenshot to %s" % ProjectSettings.globalize_path(output_path))
		else:
			push_error("Failed to save preview screenshot to %s (error %d)" % [output_path, err])
	if quit_after_capture and _frames >= capture_delay_frames + 2:
		get_tree().quit()
