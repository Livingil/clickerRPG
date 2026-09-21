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
var cone_edge_padding: float = 4.0
var cast_in_progress: bool = false

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if cooldown_left > 0.0 or cast_in_progress:
		return
	if controller == null or controller.hero == null:
		return

	var primary_target := _find_primary_target()
	if primary_target == null:
		return

	cast_in_progress = true
	var hero_position := controller.hero.global_position
	var aim_direction := (primary_target.global_position - hero_position).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.UP

	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	var hit_count := 0
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"ash_storm")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"ash_storm")
	var storm_damage := GameState.build_hero_stats().damage * storm_ratio * skill_damage_mult * GameState.get_skill_proc_multiplier(&"ash_storm")
	var cone_dot_threshold := cos(deg_to_rad(cone_half_angle_deg))
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1

	for _i in range(repeat_count):
		var targets: Array[Enemy] = []
		var directions: Dictionary = {}
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

			targets.append(enemy_node)
			directions[enemy_node] = dir_to_enemy
		var hit_targets: Array[Enemy] = await CombatResolver.apply_school_hit_batch(controller.hero.stats_component, targets, SchoolRules.SCHOOL_FIRE, storm_damage)
		if hit_targets.size() > 0:
			hit_count += hit_targets.size()
			for enemy_node in hit_targets:
				if is_instance_valid(enemy_node):
					_apply_knockback_to_cone_edge(enemy_node, hero_position, directions[enemy_node])

	if hit_count <= 0:
		cast_in_progress = false
		return

	controller.hero.play_skill_cast(&"ash_storm")
	_spawn_storm_vfx(hero_position, aim_direction)
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_FIRE, 5)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

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

func _apply_knockback_to_cone_edge(enemy: Enemy, hero_position: Vector2, direction: Vector2) -> void:
	if enemy == null:
		return
	var target_radius := maxf(0.0, cone_range - enemy.body_radius - cone_edge_padding)
	enemy.global_position = hero_position + direction * target_radius
	enemy.clamp_to_arena()
