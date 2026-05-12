extends Node2D
class_name FireAshStorm

var cone_direction: Vector2 = Vector2.UP
var cone_range: float = 250.0
var half_angle_rad: float = deg_to_rad(34.0)
var ember_lines: Array[Dictionary] = []
var fill_polygon: PackedVector2Array = PackedVector2Array()

func setup(origin_position: Vector2, direction: Vector2, max_range: float, half_angle_deg: float) -> void:
	global_position = origin_position
	cone_direction = direction.normalized()
	if cone_direction == Vector2.ZERO:
		cone_direction = Vector2.UP
	cone_range = max_range
	half_angle_rad = deg_to_rad(half_angle_deg)
	_build_embers()
	_build_fill_polygon()
	if is_inside_tree():
		queue_redraw()

func _ready() -> void:
	if ember_lines.is_empty():
		_build_embers()
	if fill_polygon.is_empty():
		_build_fill_polygon()
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)

func _draw() -> void:
	if fill_polygon.size() >= 3:
		draw_colored_polygon(fill_polygon, Color(1.0, 0.34, 0.08, 0.16))
	_draw_cone_arc(cone_range, Color(1.0, 0.58, 0.14, 0.95), 4.0)
	_draw_cone_arc(cone_range * 0.62, Color(1.0, 0.84, 0.35, 0.8), 2.0)
	for ember in ember_lines:
		var from_point: Vector2 = ember["from"]
		var to_point: Vector2 = ember["to"]
		var color: Color = ember["color"]
		var width: float = ember["width"]
		draw_line(from_point, to_point, color, width, true)

func _build_embers() -> void:
	ember_lines.clear()
	var ember_count := 14
	var base_angle := cone_direction.angle()
	for index in range(ember_count):
		var t := float(index) / maxf(1.0, float(ember_count - 1))
		var ember_angle := base_angle + lerpf(-half_angle_rad * 0.92, half_angle_rad * 0.92, t) + randf_range(-0.06, 0.06)
		var dist := randf_range(cone_range * 0.18, cone_range * 0.96)
		var center := Vector2.RIGHT.rotated(ember_angle) * dist
		var direction := Vector2.RIGHT.rotated(ember_angle + randf_range(-0.12, 0.12))
		var streak_length := randf_range(cone_range * 0.12, cone_range * 0.24)
		var from_point := center - direction * (streak_length * 0.25)
		var to_point := center + direction * (streak_length * 0.75)
		ember_lines.append({
			"from": from_point,
			"to": to_point,
			"color": Color(1.0, randf_range(0.45, 0.8), randf_range(0.08, 0.22), 0.92),
			"width": randf_range(2.0, 4.0),
		})

func _build_fill_polygon() -> void:
	fill_polygon.clear()
	fill_polygon.append(Vector2.ZERO)
	var segments := 22
	var base_angle := cone_direction.angle()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := base_angle + lerpf(-half_angle_rad, half_angle_rad, t)
		fill_polygon.append(Vector2.RIGHT.rotated(angle) * cone_range)

func _draw_cone_arc(radius: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	var segments := 26
	var base_angle := cone_direction.angle()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := base_angle + lerpf(-half_angle_rad, half_angle_rad, t)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width, true)
