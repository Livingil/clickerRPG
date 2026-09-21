extends RefCounted
class_name EnemyProjectileAttack

const EnemyProjectileScript = preload("res://scripts/effects/enemy_projectile.gd")

static func uses_projectile_attack(enemy_type: StringName, is_boss: bool) -> bool:
	return enemy_type == GameConstants.ENEMY_TYPE_RANGED and not is_boss

static func spawn_or_apply_contact_attack(attacker: Enemy, hero_target: Hero, damage: float, accuracy: float, body_radius: float) -> void:
	if attacker == null or hero_target == null:
		return

	var projectile: Node2D = EnemyProjectileScript.new() as Node2D
	if projectile == null:
		hero_target.receive_enemy_hit(damage, accuracy, attacker)
		return

	var parent: Node = _get_projectile_parent(attacker)
	if parent == null:
		parent = attacker.get_tree().current_scene
	if parent == null:
		hero_target.receive_enemy_hit(damage, accuracy, attacker)
		projectile.queue_free()
		return

	parent.add_child(projectile)
	var direction: Vector2 = (hero_target.global_position - attacker.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	projectile.setup(attacker.global_position + direction * body_radius, hero_target, damage, accuracy, attacker)

static func _get_projectile_parent(attacker: Enemy) -> Node:
	var enemy_parent: Node = attacker.get_parent()
	if enemy_parent != null:
		var battlefield: Node = enemy_parent.get_parent()
		if battlefield != null and battlefield.has_node("ProjectileContainer"):
			return battlefield.get_node("ProjectileContainer")
	return enemy_parent
