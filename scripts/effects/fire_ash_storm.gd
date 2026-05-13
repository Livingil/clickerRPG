extends Node2D
class_name FireAshStorm

const TEX_FIRE: Texture2D = preload("res://third_party/kenney-particle-pack/addons/kenney_particle_pack/fire_01.png")
const TEX_SPARK: Texture2D = preload("res://third_party/kenney-particle-pack/addons/kenney_particle_pack/spark_04.png")
const TEX_SMOKE: Texture2D = preload("res://third_party/kenney-particle-pack/addons/kenney_particle_pack/smoke_05.png")
const TEX_FLARE: Texture2D = preload("res://third_party/kenney-particle-pack/addons/kenney_particle_pack/flare_01.png")

var cone_direction: Vector2 = Vector2.UP
var cone_range: float = 250.0
var half_angle_rad: float = deg_to_rad(34.0)

var windup_duration: float = 0.10
var travel_duration: float = 0.28
var fade_duration: float = 0.22
var life_time: float = 0.0
var total_duration: float = 0.60

var front_radius: float = 0.0
var wall_thickness: float = 42.0
var wall_slots: Array[Dictionary] = []

func setup(origin_position: Vector2, direction: Vector2, max_range: float, half_angle_deg: float) -> void:
	global_position = origin_position
	cone_direction = direction.normalized()
	if cone_direction == Vector2.ZERO:
		cone_direction = Vector2.UP
	cone_range = max_range
	half_angle_rad = deg_to_rad(half_angle_deg)
	rotation = cone_direction.angle()

func _ready() -> void:
	total_duration = windup_duration + travel_duration + fade_duration
	_spawn_origin_flash()
	_create_particle_systems()
	queue_redraw()

func _process(delta: float) -> void:
	life_time += delta
	_update_timing_state()
	_update_emitters()
	queue_redraw()
	if life_time >= total_duration:
		queue_free()

func _draw() -> void:
	var power := _current_power()
	if power <= 0.0:
		return
	var front_half_w := front_radius * tan(half_angle_rad)

	# Semi-circular fire wall (moving front).
	_draw_wall_band(front_radius, front_half_w, power)
	_draw_cone_fill(power)
	_draw_edge_traces(front_radius, front_half_w, power)

func _update_timing_state() -> void:
	if life_time < windup_duration:
		modulate.a = smoothstep(0.0, windup_duration, life_time)
		front_radius = cone_range * 0.12
		return

	if life_time < windup_duration + travel_duration:
		var t := (life_time - windup_duration) / maxf(0.001, travel_duration)
		front_radius = lerpf(cone_range * 0.12, cone_range, t)
		modulate.a = 1.0
		return

	var tf := (life_time - windup_duration - travel_duration) / maxf(0.001, fade_duration)
	modulate.a = 1.0 - clampf(tf, 0.0, 1.0)
	front_radius = cone_range

func _current_power() -> float:
	if life_time < windup_duration:
		return smoothstep(0.0, windup_duration, life_time)
	if life_time < windup_duration + travel_duration:
		return 1.0
	var tf := (life_time - windup_duration - travel_duration) / maxf(0.001, fade_duration)
	return 1.0 - clampf(tf, 0.0, 1.0)

func _draw_wall_band(radius: float, half_width: float, power: float) -> void:
	var inner_r := maxf(8.0, radius - wall_thickness * 0.5)
	var outer_r := radius + wall_thickness * 0.5
	var segments := 30
	var points := PackedVector2Array()

	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(-half_angle_rad, half_angle_rad, t)
		points.append(Vector2(cos(angle), sin(angle)) * outer_r)
	for i in range(segments, -1, -1):
		var t := float(i) / float(segments)
		var angle := lerpf(-half_angle_rad, half_angle_rad, t)
		points.append(Vector2(cos(angle), sin(angle)) * inner_r)

	draw_colored_polygon(points, Color(1.0, 0.36, 0.08, 0.26 * power))
	_draw_arc_segment(radius, Color(1.0, 0.82, 0.44, 0.9 * power), 5.0)
	_draw_arc_segment(inner_r, Color(1.0, 0.62, 0.2, 0.45 * power), 2.0)

func _draw_cone_fill(power: float) -> void:
	var half_w := front_radius * tan(half_angle_rad)
	var poly := PackedVector2Array([
		Vector2.ZERO,
		Vector2(front_radius, -half_w),
		Vector2(front_radius, half_w),
	])
	draw_colored_polygon(poly, Color(1.0, 0.2, 0.05, 0.12 * power))

func _draw_edge_traces(radius: float, half_width: float, power: float) -> void:
	var edge_a := Vector2(radius, -half_width)
	var edge_b := Vector2(radius, half_width)
	draw_line(Vector2.ZERO, edge_a, Color(1.0, 0.72, 0.28, 0.35 * power), 2.5, true)
	draw_line(Vector2.ZERO, edge_b, Color(1.0, 0.72, 0.28, 0.35 * power), 2.5, true)

func _draw_arc_segment(radius: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	var segments := 30
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(-half_angle_rad, half_angle_rad, t)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width, true)

func _spawn_origin_flash() -> void:
	var flash := Sprite2D.new()
	flash.texture = TEX_FLARE
	flash.modulate = Color(1.0, 0.64, 0.22, 0.45)
	flash.scale = Vector2(0.36, 0.36)
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "scale", Vector2(0.86, 0.86), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.22)

func _create_particle_systems() -> void:
	wall_slots.clear()
	var slot_count := 14
	for i in range(slot_count):
		var flame := _make_emitter(TEX_FIRE, 16, 0.30, 12.0, 80.0, 180.0, Color(1.0, 0.76, 0.3, 0.72), Color(1.0, 0.28, 0.08, 0.0))
		var spark := _make_emitter(TEX_SPARK, 14, 0.24, 14.0, 96.0, 220.0, Color(1.0, 0.9, 0.56, 0.92), Color(1.0, 0.42, 0.12, 0.0))
		var smoke := _make_emitter(TEX_SMOKE, 12, 0.40, 18.0, 50.0, 122.0, Color(0.9, 0.35, 0.16, 0.24), Color(0.24, 0.14, 0.14, 0.0))
		add_child(flame)
		add_child(spark)
		add_child(smoke)
		wall_slots.append({
			"flame": flame,
			"spark": spark,
			"smoke": smoke,
			"t": float(i) / float(slot_count - 1),
		})

func _update_emitters() -> void:
	var power := _current_power()
	for slot in wall_slots:
		var t := float(slot["t"])
		var angle := lerpf(-half_angle_rad, half_angle_rad, t)
		var pos := Vector2(cos(angle), sin(angle)) * front_radius
		var normal := Vector2(cos(angle), sin(angle))
		var flame := slot["flame"] as GPUParticles2D
		var spark := slot["spark"] as GPUParticles2D
		var smoke := slot["smoke"] as GPUParticles2D
		if flame != null:
			flame.position = pos
			flame.rotation = normal.angle()
			flame.amount_ratio = clampf(power, 0.08, 1.0)
			flame.emitting = power > 0.05
		if spark != null:
			spark.position = pos
			spark.rotation = normal.angle()
			spark.amount_ratio = clampf(power, 0.08, 1.0)
			spark.emitting = power > 0.05
		if smoke != null:
			smoke.position = pos
			smoke.rotation = normal.angle()
			smoke.amount_ratio = clampf(power, 0.08, 1.0)
			smoke.emitting = power > 0.05

func _make_emitter(
	texture: Texture2D,
	amount: int,
	lifetime: float,
	spread_deg: float,
	vel_min: float,
	vel_max: float,
	start_color: Color,
	end_color: Color
) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.texture = texture
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = false
	p.emitting = true
	p.local_coords = true

	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(1.0, 0.0, 0.0)
	m.spread = spread_deg
	m.initial_velocity_min = vel_min
	m.initial_velocity_max = vel_max
	m.gravity = Vector3(0.0, 160.0, 0.0)
	m.scale_min = 0.15
	m.scale_max = 0.44
	m.color = start_color
	var ramp := GradientTexture1D.new()
	ramp.gradient = Gradient.new()
	ramp.gradient.colors = PackedColorArray([start_color, end_color])
	m.color_ramp = ramp
	p.process_material = m
	return p
