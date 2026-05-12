extends Node2D
class_name FireChainArc

const FireBurstRingScene = preload("res://scenes/effects/fire_burst_ring.tscn")

class PlasmaOrb:
	extends Node2D

	var base_radius: float = 12.0
	var core_color: Color = Color(1.0, 0.74, 0.34, 1.0)
	var glow_color: Color = Color(1.0, 0.5, 0.14, 0.34)
	var pulse_speed: float = 9.0
	var pulse_amount: float = 0.12
	var _time: float = 0.0

	func configure(radius: float, core: Color, glow: Color) -> void:
		base_radius = radius
		core_color = core
		glow_color = glow
		queue_redraw()

	func _process(delta: float) -> void:
		_time += delta * pulse_speed
		queue_redraw()

	func _draw() -> void:
		var pulse := 1.0 + sin(_time) * pulse_amount
		var r := base_radius * pulse
		draw_circle(Vector2.ZERO, r * 1.75, Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * 0.45))
		draw_circle(Vector2.ZERO, r * 1.25, glow_color)
		draw_circle(Vector2.ZERO, r, core_color)
		draw_circle(Vector2.ZERO, r * 0.58, Color(1.0, 0.93, 0.72, 0.92))
		draw_arc(Vector2.ZERO, r * 1.05, -0.6, 1.2, 20, Color(1.0, 0.82, 0.45, 0.6), 2.0, true)
		draw_arc(Vector2.ZERO, r * 0.9, 2.35, 3.95, 16, Color(1.0, 0.56, 0.2, 0.45), 1.6, true)

var chain_points: Array[Vector2] = []
var phase_time: float = 0.0
var phase_duration: float = 0.20
var bounce_duration: float = 0.24

var has_bounce: bool = false
var bounce_time: float = 0.0

var big_ball: PlasmaOrb
var mini_ball: PlasmaOrb
var trail: Line2D
var main_tail_color: Color = Color(1.0, 0.52, 0.16, 0.78)
var bounce_tail_color: Color = Color(1.0, 0.58, 0.2, 0.68)

var main_path: Array[Vector2] = []
var bounce_path: Array[Vector2] = []

func setup_points(points: Array[Vector2]) -> void:
	chain_points = points.duplicate()
	if is_node_ready():
		_build_visuals()

func _ready() -> void:
	if chain_points.size() < 2:
		queue_free()
		return
	_build_visuals()

func _physics_process(delta: float) -> void:
	if main_path.is_empty():
		return

	if phase_time < phase_duration:
		phase_time = minf(phase_duration, phase_time + delta)
		var t := phase_time / phase_duration
		_set_big_ball_progress(t)
		if phase_time >= phase_duration:
			_spawn_impact_ring(chain_points[1], 26.0)
		return

	if has_bounce and bounce_time < bounce_duration:
		bounce_time = minf(bounce_duration, bounce_time + delta)
		var t2 := bounce_time / bounce_duration
		_set_mini_ball_progress(t2)
		if bounce_time >= bounce_duration:
			_spawn_impact_ring(chain_points[2], 16.0)
		return

	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.14)
	fade.finished.connect(queue_free)
	set_physics_process(false)

func _build_visuals() -> void:
	for child in get_children():
		child.queue_free()

	has_bounce = chain_points.size() >= 3
	main_path = _build_linear_path(chain_points[0], chain_points[1], 10)
	if has_bounce:
		bounce_path = _build_bounce_path(chain_points[1], chain_points[2], 14)

	trail = Line2D.new()
	trail.width = 21.0
	trail.default_color = main_tail_color
	trail.antialiased = true
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_NONE
	trail.width_curve = _build_comet_width_curve()
	trail.gradient = _build_tail_gradient(main_tail_color)
	add_child(trail)

	big_ball = PlasmaOrb.new()
	big_ball.configure(19.5, Color(1.0, 0.72, 0.3, 0.98), Color(1.0, 0.45, 0.12, 0.36))
	add_child(big_ball)

	if has_bounce:
		mini_ball = PlasmaOrb.new()
		mini_ball.configure(10.5, Color(1.0, 0.62, 0.24, 0.95), Color(1.0, 0.48, 0.18, 0.28))
		mini_ball.visible = false
		add_child(mini_ball)

	phase_time = 0.0
	bounce_time = 0.0
	_update_main_trail(0)

func _set_big_ball_progress(value: float) -> void:
	var idx := int(round(clampf(value, 0.0, 1.0) * float(main_path.size() - 1)))
	idx = clampi(idx, 0, main_path.size() - 1)
	big_ball.global_position = main_path[idx]
	big_ball.rotation += 0.14
	_update_main_trail(idx)

func _set_mini_ball_progress(value: float) -> void:
	if mini_ball == null or bounce_path.is_empty():
		return
	mini_ball.visible = true
	var idx := int(round(clampf(value, 0.0, 1.0) * float(bounce_path.size() - 1)))
	idx = clampi(idx, 0, bounce_path.size() - 1)
	mini_ball.global_position = bounce_path[idx]
	mini_ball.rotation += 0.18
	_update_bounce_trail(idx)

func _update_main_trail(last_index: int) -> void:
	trail.clear_points()
	var from_idx := maxi(0, last_index - 6)
	for i in range(last_index, from_idx - 1, -1):
		trail.add_point(main_path[i])
	trail.width = 21.0 - 9.0 * (float(last_index) / maxf(1.0, float(main_path.size() - 1)))
	trail.width_curve = _build_comet_width_curve()
	trail.gradient = _build_tail_gradient(main_tail_color)

func _update_bounce_trail(last_index: int) -> void:
	trail.clear_points()
	var from_idx := maxi(0, last_index - 5)
	for i in range(last_index, from_idx - 1, -1):
		trail.add_point(bounce_path[i])
	trail.width = 12.0
	trail.default_color = bounce_tail_color
	trail.width_curve = _build_comet_width_curve()
	trail.gradient = _build_tail_gradient(bounce_tail_color)

func _build_linear_path(from_point: Vector2, to_point: Vector2, steps: int) -> Array[Vector2]:
	var path: Array[Vector2] = []
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		path.append(from_point.lerp(to_point, t))
	return path

func _build_bounce_path(from_point: Vector2, to_point: Vector2, steps: int) -> Array[Vector2]:
	var path: Array[Vector2] = []
	var midpoint := (from_point + to_point) * 0.5
	var direction := (to_point - from_point).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var height := clampf(from_point.distance_to(to_point) * 0.34, 30.0, 90.0)
	var apex := midpoint + perpendicular * -height
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var one_minus_t := 1.0 - t
		path.append(one_minus_t * one_minus_t * from_point + 2.0 * one_minus_t * t * apex + t * t * to_point)
	return path

func _spawn_impact_ring(ring_position: Vector2, radius: float) -> void:
	if not _is_inside_arena(ring_position):
		return
	var ring := FireBurstRingScene.instantiate() as FireBurstRing
	if ring == null:
		return
	ring.setup(ring_position, radius)
	add_child(ring)

func _is_inside_arena(world_position: Vector2) -> bool:
	return world_position.x >= GameConstants.ARENA_MIN.x and world_position.x <= GameConstants.ARENA_MAX.x and world_position.y >= GameConstants.ARENA_MIN.y and world_position.y <= GameConstants.ARENA_MAX.y

func _build_comet_width_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.65, 0.52))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func _build_tail_gradient(base_color: Color) -> Gradient:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1.0, 0.86, 0.48, 0.92),
		Color(base_color.r, base_color.g, base_color.b, 0.65),
		Color(base_color.r, base_color.g * 0.9, base_color.b * 0.9, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	return gradient
