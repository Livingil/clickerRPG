extends Node2D
class_name MagicProjectile

var speed: float = GameConstants.HERO_PROJECTILE_SPEED
var damage: float = 0.0
var is_crit: bool = false
var target: Enemy

func setup(target_enemy: Enemy, projectile_damage: float, crit: bool) -> void:
	target = target_enemy
	damage = projectile_damage
	is_crit = crit

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var step := speed * delta

	if distance <= step:
		target.take_damage(damage)
		queue_free()
		return

	global_position += to_target.normalized() * step
