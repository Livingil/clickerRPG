extends AbilityBase
class_name FireAshStormAbility

const FireAshStormEffect = preload("res://scripts/effects/fire_ash_storm.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 8.0
var cast_range: float = 480.0
var cone_range: float = 250.0
var cone_half_angle_deg: float = 34.0
var storm_ratio: float = 1.25
var knockback_distance: float = 58.0

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if cooldown_left > 0.0:
		return
	if controller == null or controller.hero == null:
		return
	if GameState.active_school != SchoolRules.SCHOOL_FIRE:
		return

	var primary_target := _find_primary_target()
	if primary_target == null:
		return

	var hero_position := controller.hero.global_position
	var aim_direction := (primary_target.global_position - hero_position).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.UP

	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	var hit_count := 0
	var storm_damage := GameState.build_hero_stats().damage * storm_ratio
	var cone_dot_threshold := cos(deg_to_rad(cone_half_angle_deg))

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy is not Enemy:
			continue

		var enemy_node := enemy as Enemy
		var to_enemy := enemy_node.global_position - hero_position
		var distance := to_enemy.length()
		if distance <= 0.001 or distance > cone_range:
			continue
		var dir_to_enemy := to_enemy / distance
		if dir_to_enemy.dot(aim_direction) < cone_dot_threshold:
			continue

		var hit := enemy_node.receive_school_hit(storm_damage, SchoolRules.SCHOOL_FIRE, controller.hero.stats_component.get_accuracy())
		if hit:
			_apply_knockback(enemy_node, dir_to_enemy)
			hit_count += 1

	if hit_count <= 0:
		return

	controller.hero.play_skill_cast(&"ash_storm")
	_spawn_storm_vfx(hero_position, aim_direction)
	GameState.add_active_school_mastery_xp(5)
	cooldown_left = cooldown_duration

func get_display_name() -> String:
	return "Ash Storm"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _spawn_storm_vfx(origin_position: Vector2, aim_direction: Vector2) -> void:
	if controller == null:
		return
	var storm := FireAshStormEffect.new()
	storm.setup(origin_position, aim_direction, cone_range, cone_half_angle_deg)
	controller.spawn_effect(storm)

func _apply_knockback(enemy: Enemy, direction: Vector2) -> void:
	if enemy == null:
		return
	enemy.global_position += direction * knockback_distance
	enemy.clamp_to_arena()
