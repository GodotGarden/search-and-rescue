class_name ProceduralRock
extends StaticBody3D

const ROCK_COLORS := [Color("56636a"), Color("636f5c"), Color("6b6153"), Color("4d585e")]


static func create(seed_value: int) -> ProceduralRock:
	var rock := ProceduralRock.new()
	rock.name = "GeneratedRock_%d" % seed_value
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	rock.rotation.y = random.randf_range(0.0, TAU)
	rock._build_cluster(random)
	return rock


func _build_cluster(random: RandomNumberGenerator) -> void:
	var scale_factor := random.randf_range(0.7, 1.6)
	var main_size := Vector3(
		random.randf_range(1.1, 1.9),
		random.randf_range(0.8, 1.5),
		random.randf_range(1.0, 1.8),
	) * scale_factor
	var main_color: Color = ROCK_COLORS[random.randi_range(0, ROCK_COLORS.size() - 1)]

	_add_mesh(_boulder_mesh(main_size), Vector3(0, main_size.y * 0.5, 0), main_color, random.randf_range(0.0, TAU))
	_add_cluster_collision(main_size)

	var chip_count := random.randi_range(0, 2)
	for index in range(chip_count):
		var chip_size := main_size * random.randf_range(0.3, 0.55)
		var angle := random.randf_range(0.0, TAU)
		var distance := (main_size.x + main_size.z) * 0.35 * random.randf_range(0.7, 1.05)
		var chip_position := Vector3(cos(angle) * distance, chip_size.y * 0.5, sin(angle) * distance)
		var chip_color: Color = ROCK_COLORS[random.randi_range(0, ROCK_COLORS.size() - 1)]
		_add_mesh(_boulder_mesh(chip_size), chip_position, chip_color, random.randf_range(0.0, TAU))


func _add_mesh(mesh: PrimitiveMesh, local_position: Vector3, color: Color, yaw: float) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = local_position
	instance.rotation.y = yaw
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	instance.material_override = material
	add_child(instance)


func _add_cluster_collision(main_size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = main_size
	collision.shape = shape
	collision.position.y = main_size.y * 0.5
	add_child(collision)


func _boulder_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh
