extends Node2D
class_name EnemyProjectile

var speed: float = GameConstants.ENEMY_PROJECTILE_SPEED
var hit_radius: float = GameConstants.ENEMY_PROJECTILE_HIT_RADIUS
var max_lifetime: float = GameConstants.ENEMY_PROJECTILE_MAX_LIFETIME
var damage: float = 0.0
var accuracy: float = 0.0
var target: Hero
var source_enemy: Enemy
var lifetime: float = 0.0
var trail_points: Array[Vector2] = []
var trail_max_points: int = 7

func setup(start_position: Vector2, target_hero: Hero, projectile_damage: float, projectile_accuracy: float, attacker: Enemy) -> void:
	global_position = start_position
	target = target_hero
	damage = projectile_damage
	accuracy = projectile_accuracy
	source_enemy = attacker
	lifetime = 0.0
	trail_points.clear()
	queue_redraw()

func _ready() -> void:
	z_index = 35

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return
	if not is_instance_valid(target) or target.hp <= 0.0:
		queue_free()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var step := speed * delta
	var effective_hit_radius := hit_radius + target.body_radius * 0.45
	if distance <= maxf(effective_hit_radius, step):
		_hit_target()
		return

	var direction := to_target.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_position += direction * step
	rotation = direction.angle()
	_update_trail()
	queue_redraw()

func _hit_target() -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var attacker: Enemy = null
	if is_instance_valid(source_enemy):
		attacker = source_enemy
	var result := await CombatResolver.resolve_enemy_attack(attacker, target, damage, accuracy)
	if is_instance_valid(target):
		target.receive_resolved_enemy_hit(result, attacker)
	queue_free()

func _update_trail() -> void:
	trail_points.append(global_position)
	if trail_points.size() > trail_max_points:
		trail_points.pop_front()

func _draw() -> void:
	for i in range(trail_points.size()):
		var alpha := float(i + 1) / float(trail_points.size() + 1)
		draw_circle(to_local(trail_points[i]), 5.0 * alpha, Color(1.0, 0.32, 0.22, 0.18 + alpha * 0.28))
	draw_circle(Vector2.ZERO, 13.0, Color(1.0, 0.18, 0.12, 0.22))
	draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.42, 0.22, 0.92))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.86, 0.56, 1.0))
