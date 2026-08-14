extends Node3D

const ProceduralTree := preload("res://scripts/world/procedural_tree.gd")

const GROUND_COLOR := Color("668a4e")
const TRAIL_COLOR := Color("b99c6b")
const ROCK_COLOR := Color("56636a")
const WATER_COLOR := Color("3b7fa5")
const FOREST_SEED := 904201


func _ready() -> void:
	_build_blockout()


func get_spawn_transform(spawn_index: int) -> Transform3D:
	var marker := $SpawnHost if spawn_index == 0 else $SpawnClient
	return marker.global_transform


func _build_blockout() -> void:
	_add_environment()
	_add_box("WalkableGround", Vector3(0, -1.0, 0), Vector3(300, 2, 300), GROUND_COLOR)
	_add_box("RescueCentre", Vector3(-24, 3, 32), Vector3(18, 6, 12), Color("e0d4bd"))
	_add_box("Helipad", Vector3(-9, 0.12, 31), Vector3(14, 0.25, 14), Color("46545a"))
	_add_box("Trailhead", Vector3(2, 1.5, 21), Vector3(3, 3, 3), Color("b34736"))
	_add_box("Lookout", Vector3(67, 5, -30), Vector3(8, 10, 8), Color("a27650"))
	_add_box("Village", Vector3(-80, 3, -70), Vector3(36, 6, 24), Color("d2af7a"))
	_add_box("HealthCentre", Vector3(-63, 4, -38), Vector3(20, 8, 12), Color("e6e2d2"))
	_add_box("Meadow", Vector3(12, 0.12, -7), Vector3(110, 0.24, 95), Color("8ead5c"), false)
	_add_box("Trail", Vector3(25, 0.3, -15), Vector3(5, 0.12, 100), TRAIL_COLOR, false)
	_add_box("LakeWater", Vector3(-47, 0.05, 65), Vector3(64, 0.5, 48), WATER_COLOR, false)
	_add_box("LakeIsland", Vector3(-47, 1.6, 65), Vector3(15, 3, 12), Color("69884e"))
	_add_lake_shoreline()
	_add_box("WetlandEdge", Vector3(-78, 0.15, 42), Vector3(32, 0.3, 20), Color("5b876a"), false)
	_add_slope("GentleSlope", Vector3(52, 1.8, -18), Vector3(34, 3, 42), -12.0, Color("789457"))
	_add_boundaries()
	_add_forest()
	_add_label("TRAILHEAD", Vector3(2, 4, 21))
	_add_label("LOOKOUT", Vector3(67, 11, -30))
	_add_label("TRAIL DESTINATION", $TrailDestination.position + Vector3(0, 2, 0))


func _add_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("9dc8df")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7e6e7")
	environment.ambient_light_energy = 0.65
	environment.fog_enabled = true
	environment.fog_light_color = Color("b8d1d5")
	environment.fog_density = 0.002
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.3
	add_child(sun)


func _add_boundaries() -> void:
	for index in range(9):
		var offset := -120.0 + index * 30.0
		_add_box("NorthMountain%d" % index, Vector3(offset, 11, -132), Vector3(28, 22, 24), ROCK_COLOR)
		_add_box("EastCliff%d" % index, Vector3(132, 9, offset), Vector3(24, 18, 28), ROCK_COLOR)
		_add_box("SouthRidge%d" % index, Vector3(offset, 10, 132), Vector3(28, 20, 20), ROCK_COLOR)
		_add_box("WestCliff%d" % index, Vector3(-132, 9, offset), Vector3(20, 18, 28), ROCK_COLOR)


func _add_forest() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = FOREST_SEED
	for index in range(52):
		var tree := ProceduralTree.create(FOREST_SEED + index)
		tree.position = Vector3(
			random.randf_range(35.0, 112.0),
			0.0,
			random.randf_range(-104.0, -24.0),
		)
		add_child(tree)


func _add_lake_shoreline() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = FOREST_SEED + 1
	for index in range(8):
		var horizontal_position := -78.0 + index * 9.0
		var vertical_position := 43.0 + index * 6.5
		_add_shore_rock("LakeNorthRock%d" % index, Vector3(horizontal_position, 1.3, 41.0 + random.randf_range(-1.5, 1.5)), random)
		_add_shore_rock("LakeSouthRock%d" % index, Vector3(horizontal_position, 1.3, 89.0 + random.randf_range(-1.5, 1.5)), random)
		_add_shore_rock("LakeWestRock%d" % index, Vector3(-79.0 + random.randf_range(-1.5, 1.5), 1.3, vertical_position), random)
		_add_shore_rock("LakeEastRock%d" % index, Vector3(-15.0 + random.randf_range(-1.5, 1.5), 1.3, vertical_position), random)


func _add_shore_rock(label: String, world_position: Vector3, random: RandomNumberGenerator) -> void:
	# Each rock overlaps its neighbors so there is no walkable gap around the lake.
	var size := Vector3(random.randf_range(10.0, 12.0), random.randf_range(2.4, 4.0), random.randf_range(8.0, 10.0))
	_add_box(label, world_position, size, ROCK_COLOR)


func _add_slope(label: String, world_position: Vector3, size: Vector3, angle_degrees: float, color: Color) -> void:
	var node := _add_box(label, world_position, size, color)
	node.get_parent().rotation_degrees.x = angle_degrees


func _add_box(label: String, world_position: Vector3, size: Vector3, color: Color, has_collision := true) -> MeshInstance3D:
	var parent: Node3D = self
	if has_collision:
		var body := StaticBody3D.new()
		body.name = "%sCollision" % label
		body.position = world_position
		add_child(body)
		parent = body
	else:
		var visual_parent := Node3D.new()
		visual_parent.name = "%sVisual" % label
		visual_parent.position = world_position
		add_child(visual_parent)
		parent = visual_parent
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	if has_collision:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		parent.add_child(collision)
	return mesh_instance


func _add_label(text_value: String, world_position: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = world_position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.01
	label.outline_size = 3
	add_child(label)
