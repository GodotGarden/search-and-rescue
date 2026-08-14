class_name ProceduralTree
extends StaticBody3D

const TRUNK_COLORS := [Color("5f432e"), Color("704c2f"), Color("4e392c")]
const NEEDLE_COLORS := [Color("28533f"), Color("326347"), Color("3d704d"), Color("214936")]


static func create(seed_value: int) -> ProceduralTree:
	var tree := ProceduralTree.new()
	tree.name = "GeneratedTree_%d" % seed_value
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	tree.rotation.y = random.randf_range(0.0, TAU)
	tree._build_pine(random)
	return tree


func _build_pine(random: RandomNumberGenerator) -> void:
	var height_scale := random.randf_range(0.8, 1.25)
	var trunk_height := random.randf_range(3.2, 4.8) * height_scale
	var trunk_radius := random.randf_range(0.32, 0.46) * height_scale
	var canopy_layers := random.randi_range(2, 4)
	var crown_radius := random.randf_range(2.5, 3.6) * height_scale

	_add_mesh(_cylinder_mesh(trunk_radius, trunk_radius * 0.82, trunk_height, 6), Vector3(0, trunk_height * 0.5, 0), TRUNK_COLORS[random.randi_range(0, TRUNK_COLORS.size() - 1)])
	_add_trunk_collision(trunk_radius * 1.15, trunk_height)

	for layer in range(canopy_layers):
		var layer_progress := float(layer) / maxf(float(canopy_layers - 1), 1.0)
		var layer_radius := lerpf(crown_radius, crown_radius * 0.42, layer_progress)
		var layer_height := random.randf_range(2.8, 3.9) * height_scale
		var layer_y := trunk_height * 0.58 + layer * (layer_height * 0.58)
		var material_color: Color = NEEDLE_COLORS[random.randi_range(0, NEEDLE_COLORS.size() - 1)]
		_add_mesh(_cylinder_mesh(0.08, layer_radius, layer_height, 7), Vector3(0, layer_y, 0), material_color)


func _add_mesh(mesh: PrimitiveMesh, local_position: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = local_position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	instance.material_override = material
	add_child(instance)


func _add_trunk_collision(radius: float, height_value: float) -> void:
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height_value
	collision.shape = shape
	collision.position.y = height_value * 0.5
	add_child(collision)


func _cylinder_mesh(top_radius: float, bottom_radius: float, height_value: float, sides: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height_value
	mesh.radial_segments = sides
	mesh.rings = 1
	return mesh
