extends Node2D
class_name LightningAreaEffect

enum EffectKind { ARC, LANCE, CROWN }

var kind: EffectKind = EffectKind.ARC
var duration: float = 0.35
var life_time: float = 0.0
var points: Array[Vector2] = []
var radius: float = 150.0
var follow_target: Node2D = null

func setup_arc(arc_points: Array[Vector2], effect_duration: float = 0.32) -> void:
	kind = EffectKind.ARC
	points = arc_points.duplicate()
	duration = effect_duration

func setup_lance(from_position: Vector2, to_position: Vector2, effect_duration: float = 0.28) -> void:
	kind = EffectKind.LANCE
	points = [from_position, to_position]
	duration = effect_duration

func setup_crown(target: Node2D, crown_radius: float, effect_duration: float) -> void:
	kind = EffectKind.CROWN
	follow_target = target
	radius = crown_radius
	duration = effect_duration
	if follow_target != null:
		global_position = follow_target.global_position

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	life_time += delta
	if follow_target != null and is_instance_valid(follow_target):
		global_position = follow_target.global_position
	queue_redraw()
	if life_time >= duration:
		queue_free()

func _draw() -> void:
	var alpha := 1.0 - clampf(life_time / maxf(0.001, duration), 0.0, 1.0)
	match kind:
		EffectKind.ARC:
			_draw_arc_chain(alpha)
		EffectKind.LANCE:
			_draw_lance(alpha)
		EffectKind.CROWN:
			_draw_crown(alpha)

func _draw_arc_chain(alpha: float) -> void:
	if points.size() < 2:
		return
	for i in range(points.size() - 1):
		_draw_jagged_line(to_local(points[i]), to_local(points[i + 1]), Color(1.0, 0.94, 0.35, 0.85 * alpha), 4.0)
		_draw_jagged_line(to_local(points[i]), to_local(points[i + 1]), Color(0.50, 0.78, 1.0, 0.55 * alpha), 8.0)

func _draw_lance(alpha: float) -> void:
	if points.size() < 2:
		return
	var from_position := to_local(points[0])
	var to_position := to_local(points[1])
	draw_line(from_position, to_position, Color(1.0, 0.94, 0.32, 0.90 * alpha), 5.0, true)
	draw_line(from_position, to_position, Color(0.45, 0.72, 1.0, 0.42 * alpha), 13.0, true)
	for i in range(4):
		var t := float(i + 1) / 5.0
		var center := from_position.lerp(to_position, t)
		draw_circle(center, 8.0 + sin(life_time * 20.0 + float(i)) * 2.0, Color(1.0, 0.96, 0.48, 0.45 * alpha))

func _draw_crown(alpha: float) -> void:
	for i in range(3):
		var r := radius * (0.55 + float(i) * 0.17)
		var start := life_time * 5.5 + float(i) * 1.4
		draw_arc(Vector2.ZERO, r, start, start + PI * 1.15, 48, Color(1.0, 0.92, 0.28, 0.48 * alpha), 2.5, true)
	for i in range(8):
		var angle := TAU * float(i) / 8.0 + life_time * 3.8
		var from_position := Vector2(cos(angle), sin(angle)) * radius * 0.35
		var to_position := Vector2(cos(angle + 0.08), sin(angle + 0.08)) * radius
		draw_line(from_position, to_position, Color(0.60, 0.82, 1.0, 0.32 * alpha), 2.0, true)

func _draw_jagged_line(from_position: Vector2, to_position: Vector2, color: Color, width: float) -> void:
	var direction := to_position - from_position
	var length := direction.length()
	if length <= 0.001:
		return
	var normal := direction.orthogonal().normalized()
	var previous := from_position
	for i in range(1, 7):
		var t := float(i) / 6.0
		var offset := 0.0
		if i < 6:
			offset = sin(life_time * 32.0 + float(i) * 2.1) * 10.0
		var next := from_position.lerp(to_position, t) + normal * offset
		draw_line(previous, next, color, width, true)
		previous = next
