extends Node2D
class_name FireMeteorStrike

var target_position: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var impact_radius: float = 64.0

var flight_duration: float = 0.34
var impact_duration: float = 0.34
var flight_time: float = 0.0
var impact_time: float = 0.0
var impacted: bool = false

var velocity_dir: Vector2 = Vector2.DOWN

func setup(center_position: Vector2, radius: float) -> void:
	target_position = center_position
	impact_radius = maxf(36.0, radius)
	start_position = center_position + Vector2(randf_range(-28.0, 28.0), -360.0)
	global_position = start_position
	queue_redraw()

func _ready() -> void:
	if global_position == Vector2.ZERO and target_position != Vector2.ZERO:
		global_position = start_position
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not impacted:
		flight_time = minf(flight_duration, flight_time + delta)
		var t := flight_time / flight_duration
		var curve_drop := sin(t * PI) * 18.0
		var new_pos := start_position.lerp(target_position, t) + Vector2(curve_drop * 0.22, 0.0)
		velocity_dir = (new_pos - global_position).normalized()
		global_position = new_pos
		queue_redraw()
		if flight_time >= flight_duration:
			impacted = true
			global_position = target_position
			_spawn_impact_ring()
		return

	impact_time = minf(impact_duration, impact_time + delta)
	modulate.a = lerpf(1.0, 0.0, impact_time / impact_duration)
	queue_redraw()
	if impact_time >= impact_duration:
		queue_free()

func _draw() -> void:
	if not impacted:
		_draw_meteor_flight()
	else:
		_draw_impact_afterglow()

func _draw_meteor_flight() -> void:
	var tail_len := 110.0
	var tail_w := 22.0
	var back := -velocity_dir.normalized()
	var side := Vector2(-back.y, back.x)

	var p0 := Vector2.ZERO
	var p1 := back * tail_len + side * tail_w
	var p2 := back * tail_len - side * tail_w
	draw_colored_polygon(PackedVector2Array([p0, p1, p2]), Color(1.0, 0.42, 0.12, 0.42))

	draw_line(Vector2.ZERO, back * (tail_len * 0.94), Color(1.0, 0.76, 0.35, 0.72), 7.0, true)
	draw_line(Vector2.ZERO, back * (tail_len * 0.66), Color(1.0, 0.92, 0.64, 0.88), 3.0, true)

	draw_circle(Vector2.ZERO, 22.0, Color(1.0, 0.48, 0.14, 0.42))
	draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.66, 0.25, 0.95))
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.93, 0.74, 0.95))

func _draw_impact_afterglow() -> void:
	var t := impact_time / maxf(0.001, impact_duration)
	var outer_r := lerpf(impact_radius * 0.55, impact_radius * 1.15, t)
	var inner_r := lerpf(impact_radius * 0.22, impact_radius * 0.7, t)
	var alpha := 1.0 - t

	draw_circle(Vector2.ZERO, outer_r, Color(1.0, 0.3, 0.08, 0.16 * alpha))
	draw_arc(Vector2.ZERO, outer_r, 0.0, TAU, 40, Color(1.0, 0.52, 0.15, 0.95 * alpha), 4.0)
	draw_circle(Vector2.ZERO, inner_r, Color(1.0, 0.84, 0.45, 0.18 * alpha))

func _spawn_impact_ring() -> void:
	var ring := FireBurstRing.new()
	ring.setup(target_position, impact_radius * 0.62)
	add_child(ring)
