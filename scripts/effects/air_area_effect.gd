extends Node2D
class_name AirAreaEffect

enum AreaKind { GUST, CYCLONE, FLURRY }

var kind: AreaKind = AreaKind.GUST
var radius: float = 120.0
var duration: float = 0.55
var life_time: float = 0.0
var direction: Vector2 = Vector2.RIGHT

func setup(center_position: Vector2, area_kind: AreaKind, area_radius: float, area_duration: float = 0.55, air_direction: Vector2 = Vector2.RIGHT) -> void:
	global_position = center_position
	kind = area_kind
	radius = area_radius
	duration = area_duration
	direction = air_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()

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
		AreaKind.GUST:
			_draw_gust(alpha)
		AreaKind.CYCLONE:
			_draw_cyclone(alpha)
		AreaKind.FLURRY:
			_draw_flurry(alpha)

func _draw_gust(alpha: float) -> void:
	for i in range(5):
		var y := (float(i) - 2.0) * radius * 0.18
		var wave := sin(life_time * 12.0 + float(i)) * 10.0
		var from := Vector2(-radius * 0.45, y)
		var to := Vector2(radius * 0.62, y + wave)
		draw_line(from, to, Color(0.78, 0.92, 1.0, 0.62 * alpha), 3.0, true)
	draw_arc(Vector2.ZERO, radius * 0.42, -0.55, 0.55, 20, Color(0.90, 0.98, 1.0, 0.52 * alpha), 2.0, true)

func _draw_cyclone(alpha: float) -> void:
	for i in range(4):
		var r := radius * (0.28 + float(i) * 0.18) + sin(life_time * 8.0 + float(i)) * 5.0
		var start := life_time * 5.5 + float(i) * 0.7
		draw_arc(Vector2.ZERO, r, start, start + PI * 1.35, 48, Color(0.66, 0.88, 1.0, 0.58 * alpha), 2.4, true)
	draw_circle(Vector2.ZERO, radius * 0.22, Color(0.78, 0.94, 1.0, 0.10 * alpha))

func _draw_flurry(alpha: float) -> void:
	for i in range(9):
		var angle := TAU * float(i) / 9.0 + life_time * 5.0
		var from := Vector2(cos(angle), sin(angle)) * radius * 0.25
		var to := Vector2(cos(angle + 0.18), sin(angle + 0.18)) * radius
		draw_line(from, to, Color(0.84, 0.96, 1.0, 0.56 * alpha), 2.2, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(0.74, 0.90, 1.0, 0.45 * alpha), 2.0, true)
