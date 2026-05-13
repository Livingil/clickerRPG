extends Node2D
class_name MagicProjectile

const FireBurstRingScene = preload("res://scenes/effects/fire_burst_ring.tscn")

var speed: float = GameConstants.HERO_PROJECTILE_SPEED
var damage: float = 0.0
var is_crit: bool = false
var target: Enemy
var school_id: StringName = &"fire"
var accuracy: float = 0.0
@onready var body: Polygon2D = $Body
@onready var glow: Polygon2D = $Glow
@onready var trail: Line2D = $Trail
@onready var kenney_core: Sprite2D = $KenneyCore
@onready var kenney_glow: Sprite2D = $KenneyGlow
var trail_points: Array[Vector2] = []
var trail_max_points: int = 8

func setup(target_enemy: Enemy, projectile_damage: float, crit: bool, attack_school_id: StringName, attack_accuracy: float) -> void:
	target = target_enemy
	damage = projectile_damage
	is_crit = crit
	school_id = attack_school_id
	accuracy = attack_accuracy
	if is_node_ready():
		_apply_school_visual()

func _ready() -> void:
	trail_points.clear()
	if trail != null:
		trail.clear_points()
	_apply_school_visual()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var step := speed * delta

	if distance <= step:
		if is_crit:
			target.receive_school_crit_hit(damage, school_id, accuracy)
		else:
			target.receive_school_hit(damage, school_id, accuracy)
		_spawn_hit_flash()
		queue_free()
		return

	var direction := to_target.normalized()
	global_position += direction * step
	rotation = direction.angle()
	_update_trail()

func _update_trail() -> void:
	if trail == null:
		return
	trail_points.append(global_position)
	if trail_points.size() > trail_max_points:
		trail_points.pop_front()
	trail.clear_points()
	var alpha_step := 1.0 / maxf(1.0, float(trail_points.size()))
	for i in range(trail_points.size()):
		var local_point := to_local(trail_points[i])
		trail.add_point(local_point)
	var alpha := clampf(0.15 + alpha_step * float(trail_points.size()) * 0.6, 0.15, 0.8)
	var color := trail.default_color
	color.a = alpha
	trail.default_color = color

func _spawn_hit_flash() -> void:
	if not _is_inside_arena(global_position):
		return
	var flash := FireBurstRingScene.instantiate() as FireBurstRing
	if flash == null:
		return
	flash.setup(global_position, 28.0 if is_crit else 20.0)
	get_parent().add_child(flash)

func _is_inside_arena(world_position: Vector2) -> bool:
	return world_position.x >= GameConstants.ARENA_MIN.x and world_position.x <= GameConstants.ARENA_MAX.x and world_position.y >= GameConstants.ARENA_MIN.y and world_position.y <= GameConstants.ARENA_MAX.y

func _apply_school_visual() -> void:
	match school_id:
		&"fire":
			body.color = Color(1.0, 0.45, 0.18, 1.0)
			if glow != null:
				glow.visible = true
				glow.color = Color(1.0, 0.65, 0.24, 0.35)
			if kenney_core != null:
				kenney_core.visible = true
				kenney_core.modulate = Color(1.0, 0.72, 0.34, 0.92)
			if kenney_glow != null:
				kenney_glow.visible = true
				kenney_glow.modulate = Color(1.0, 0.54, 0.18, 0.45)
			if trail != null:
				trail.visible = true
				trail.width = 7.0 if is_crit else 6.0
				trail.default_color = Color(1.0, 0.5, 0.16, 0.75)
		&"water":
			body.color = Color(0.3, 0.68, 1.0, 1.0)
			if glow != null:
				glow.visible = true
				glow.color = Color(0.5, 0.82, 1.0, 0.32)
			if kenney_core != null:
				kenney_core.visible = true
				kenney_core.modulate = Color(0.56, 0.84, 1.0, 0.9)
			if kenney_glow != null:
				kenney_glow.visible = true
				kenney_glow.modulate = Color(0.58, 0.86, 1.0, 0.34)
			if trail != null:
				trail.visible = true
				trail.width = 5.0
				trail.default_color = Color(0.45, 0.78, 1.0, 0.65)
		&"earth":
			body.color = Color(0.63, 0.5, 0.34, 1.0)
			if glow != null:
				glow.visible = false
			if kenney_core != null:
				kenney_core.visible = false
			if kenney_glow != null:
				kenney_glow.visible = false
			if trail != null:
				trail.visible = false
		&"air":
			body.color = Color(0.84, 0.9, 1.0, 1.0)
			if glow != null:
				glow.visible = false
			if kenney_core != null:
				kenney_core.visible = false
			if kenney_glow != null:
				kenney_glow.visible = false
			if trail != null:
				trail.visible = false
		&"lightning":
			body.color = Color(1.0, 0.95, 0.3, 1.0)
			if glow != null:
				glow.visible = true
				glow.color = Color(1.0, 0.95, 0.45, 0.38)
			if kenney_core != null:
				kenney_core.visible = true
				kenney_core.modulate = Color(1.0, 0.95, 0.5, 0.95)
			if kenney_glow != null:
				kenney_glow.visible = true
				kenney_glow.modulate = Color(1.0, 0.98, 0.62, 0.42)
			if trail != null:
				trail.visible = true
				trail.width = 4.0
				trail.default_color = Color(1.0, 0.92, 0.42, 0.65)
