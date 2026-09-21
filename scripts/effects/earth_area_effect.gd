extends Node2D
class_name EarthAreaEffect

enum AreaKind { SPIKE, QUAKE, BASTION }

var kind: AreaKind = AreaKind.SPIKE
var radius: float = 100.0
var duration: float = 0.45
var life_time: float = 0.0

func setup(center_position: Vector2, area_kind: AreaKind, area_radius: float, area_duration: float = 0.45) -> void:
	global_position = center_position
	kind = area_kind
	radius = area_radius
	duration = area_duration

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	life_time += delta
	queue_redraw()
	if life_time >= duration:
		queue_free()

func _draw() -> void:
	var alpha := 1.0 - clampf(life_time / maxf(0.001, duration), 0.0, 1.0)
	match kind:
		AreaKind.SPIKE:
			_draw_spike(alpha)
		AreaKind.QUAKE:
			_draw_quake(alpha)
		AreaKind.BASTION:
			_draw_bastion(alpha)

func _draw_spike(alpha: float) -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius * 0.28, 0.0),
		Vector2(radius * 0.10, radius * 0.30),
		Vector2(-radius * 0.10, radius * 0.30),
		Vector2(-radius * 0.28, 0.0),
	])
	draw_colored_polygon(points, Color(0.60, 0.48, 0.32, 0.72 * alpha))
	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, Color(0.88, 0.74, 0.46, 0.85 * alpha), 2.0, true)

func _draw_quake(alpha: float) -> void:
	for i in range(3):
		var r := radius * (0.45 + float(i) * 0.22) + life_time * 34.0
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 54, Color(0.74, 0.62, 0.42, 0.58 * alpha), 3.0, true)
	for i in range(10):
		var angle := TAU * float(i) / 10.0
		var from := Vector2(cos(angle), sin(angle)) * radius * 0.28
		var to := Vector2(cos(angle + 0.08), sin(angle + 0.08)) * radius * 0.92
		draw_line(from, to, Color(0.48, 0.36, 0.22, 0.44 * alpha), 2.0, true)

func _draw_bastion(alpha: float) -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.36, 0.22, 0.18 * alpha))
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var pos := Vector2(cos(angle), sin(angle)) * radius * 0.82
		var stone := Rect2(pos - Vector2(9.0, 13.0), Vector2(18.0, 26.0))
		draw_rect(stone, Color(0.54, 0.45, 0.32, 0.72 * alpha), true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 60, Color(0.92, 0.78, 0.48, 0.72 * alpha), 2.5, true)
