extends AbilityBase
class_name FireCinderBurstAbility

const FireMeteorStrikeEffect = preload("res://scripts/effects/fire_meteor_strike.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 5.5
var splash_ratio: float = 0.82
var burning_splash_ratio: float = 1.08
var splash_range: float = 170.0
var burning_splash_range: float = 230.0
var cast_range: float = 420.0
var cast_in_progress: bool = false

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if cooldown_left > 0.0 or cast_in_progress:
		return
	if controller == null or controller.hero == null:
		return

	var target := _find_primary_target()
	if target == null:
		return

	cast_in_progress = true
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	var hit_any := false
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"cinder_burst")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"cinder_burst")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"cinder_burst")
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var target_was_burning := _is_burning(target)
	var effective_ratio := burning_splash_ratio if target_was_burning else splash_ratio
	var effective_range := burning_splash_range if target_was_burning else splash_range
	var base_damage := GameState.build_hero_stats().damage * effective_ratio * skill_damage_mult * skill_proc_mult
	for _i in range(repeat_count):
		hit_any = await CombatResolver.apply_school_hit(controller.hero.stats_component, target, SchoolRules.SCHOOL_FIRE, base_damage) or hit_any
		var splash_targets: Array[Enemy] = []
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			if enemy is not Enemy:
				continue

			var enemy_node := enemy as Enemy
			if enemy_node == target:
				continue

			if enemy_node.global_position.distance_to(target.global_position) <= effective_range:
				splash_targets.append(enemy_node)
		var hit_targets: Array[Enemy] = await CombatResolver.apply_school_hit_batch(controller.hero.stats_component, splash_targets, SchoolRules.SCHOOL_FIRE, base_damage)
		if hit_targets.size() > 0:
			if target_was_burning:
				for enemy_node in hit_targets:
					if is_instance_valid(enemy_node):
						enemy_node.apply_vulnerability_stack(SchoolRules.SCHOOL_FIRE)
			hit_any = true

	if hit_any:
		controller.hero.play_skill_cast(&"cinder_burst")
		_spawn_burst_vfx(target.global_position, effective_range)
		GameState.add_school_mastery_xp(SchoolRules.SCHOOL_FIRE, 2)
		cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Cinder Burst"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _is_burning(target: Enemy) -> bool:
	if target == null:
		return false
	return int(target.vulnerability_stacks.get(SchoolRules.SCHOOL_FIRE, 0)) > 0 or target.burn_time_left > 0.0

func _spawn_burst_vfx(center_position: Vector2, range_radius: float) -> void:
	if controller == null:
		return
	if not _is_inside_arena(center_position):
		return
	var burst := FireMeteorStrikeEffect.new() as FireMeteorStrike
	if burst == null:
		return
	burst.setup(center_position, range_radius * 0.48)
	controller.spawn_effect(burst)

func _is_inside_arena(world_position: Vector2) -> bool:
	return world_position.x >= GameConstants.ARENA_MIN.x and world_position.x <= GameConstants.ARENA_MAX.x and world_position.y >= GameConstants.ARENA_MIN.y and world_position.y <= GameConstants.ARENA_MAX.y
