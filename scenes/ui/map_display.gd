extends Control

const WORLD_HALF_EXTENT := 150.0

var _player_position := Vector3.ZERO
var _player_yaw := 0.0


func set_player_state(position_value: Vector3, yaw: float) -> void:
	_player_position = position_value
	_player_yaw = yaw
	queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("d8d0a6"))
	var inset := Rect2(Vector2(12, 12), size - Vector2(24, 24))
	draw_rect(inset, Color("7fa45d"))
	_draw_mountains(inset)
	_draw_lake(inset)
	_draw_forest(inset)
	_draw_trail()
	_draw_marker(Vector2(-24, 32), Color("b83f35"), 8.0)
	_draw_marker(Vector2(58, -48), Color("f1d05a"), 8.0)
	_draw_player()


func _draw_mountains(inset: Rect2) -> void:
	var edge_color := Color("5d6870")
	draw_rect(Rect2(inset.position, Vector2(inset.size.x, 17)), edge_color)
	draw_rect(Rect2(Vector2(inset.position.x, inset.end.y - 17), Vector2(inset.size.x, 17)), edge_color)
	draw_rect(Rect2(inset.position, Vector2(17, inset.size.y)), edge_color)
	draw_rect(Rect2(Vector2(inset.end.x - 17, inset.position.y), Vector2(17, inset.size.y)), edge_color)


func _draw_lake(inset: Rect2) -> void:
	var lake_top_left := _map_point(Vector2(-79, 41))
	var lake_bottom_right := _map_point(Vector2(-15, 89))
	draw_rect(Rect2(lake_top_left, lake_bottom_right - lake_top_left), Color("3f83a3"))
	draw_circle(_map_point(Vector2(-47, 65)), 11.0, Color("749756"))


func _draw_forest(inset: Rect2) -> void:
	var forest_top_left := _map_point(Vector2(35, -104))
	var forest_bottom_right := _map_point(Vector2(112, -24))
	draw_rect(Rect2(forest_top_left, forest_bottom_right - forest_top_left), Color("356044"))


func _draw_trail() -> void:
	var trail := PackedVector2Array([
		_map_point(Vector2(-20, 24)),
		_map_point(Vector2(25, -15)),
		_map_point(Vector2(58, -48)),
	])
	draw_polyline(trail, Color("c8a66d"), 5.0, true)


func _draw_marker(world_position: Vector2, color: Color, radius: float) -> void:
	draw_circle(_map_point(world_position), radius, color)


func _draw_player() -> void:
	var map_position := _map_point(Vector2(_player_position.x, _player_position.z))
	var forward := Vector2(sin(_player_yaw), -cos(_player_yaw))
	var side := Vector2(-forward.y, forward.x)
	var points := PackedVector2Array([
		map_position + forward * 11.0,
		map_position - forward * 7.0 + side * 6.0,
		map_position - forward * 7.0 - side * 6.0,
	])
	draw_colored_polygon(points, Color("f7f5e8"))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color("28343b"), 2.0, true)


func _map_point(world_xz: Vector2) -> Vector2:
	return Vector2(
		remap(world_xz.x, -WORLD_HALF_EXTENT, WORLD_HALF_EXTENT, 12.0, size.x - 12.0),
		remap(world_xz.y, -WORLD_HALF_EXTENT, WORLD_HALF_EXTENT, 12.0, size.y - 12.0),
	)
