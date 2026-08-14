extends Control

var _player_yaw := 0.0


func set_heading(yaw: float) -> void:
	_player_yaw = yaw
	queue_redraw()


func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	draw_circle(centre, radius, Color("1c2528"))
	draw_arc(centre, radius, 0.0, TAU, 48, Color("d7d4af"), 4.0, true)
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var direction := Vector2(sin(angle), -cos(angle))
		var tick_length := 15.0 if index % 4 == 0 else 8.0
		draw_line(centre + direction * (radius - tick_length), centre + direction * radius, Color("d7d4af"), 2.0)
	var north := Vector2(sin(_player_yaw), -cos(_player_yaw))
	draw_line(centre, centre + north * (radius * 0.75), Color("d44839"), 8.0, true)
	draw_line(centre, centre - north * (radius * 0.48), Color("d7d4af"), 5.0, true)
	draw_circle(centre, 8.0, Color("f7f5e8"))
