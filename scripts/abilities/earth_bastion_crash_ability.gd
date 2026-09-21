extends AbilityBase
class_name EarthBastionCrashAbility

const EarthAreaEffectScript = preload("res://scripts/effects/earth_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 8.6
var active_time_left: float = 0.0
var active_duration: float = 4.0
var tick_interval: float = 0.8
var tick_left: float = 0.0
var cast_range: float = 460.0
var area_radius: float = 150.0
var damage_ratio: float = 0.44
var tick_in_progress: bool = false

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if active_time_left > 0.0:
		_tick_bastion(delta)
		return
	if cooldown_left > 0.0:
		return
	if controller == null or controller.hero == null:
		return
	if _find_primary_target() == null:
		return

	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"bastion_crash")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"bastion_crash")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"bastion_crash")
	var hit_damage := GameState.build_hero_stats().damage * damage_ratio * skill_damage_mult * skill_proc_mult
	await _hit_enemies_around(controller.hero.global_position, hit_damage)

	controller.hero.apply_bastion()
	controller.hero.play_skill_cast(&"bastion_crash")
	_spawn_bastion(controller.hero.global_position)
	active_time_left = active_duration
	tick_left = tick_interval
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_EARTH, 5)
	cooldown_left = cooldown_duration * skill_cd_mult

func get_display_name() -> String:
	return "Bastion Crash"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _hit_enemies_around(center_position: Vector2, damage: float) -> bool:
	var targets: Array[Enemy] = []
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy is not Enemy:
			continue
		var enemy_node := enemy as Enemy
		if enemy_node.global_position.distance_to(center_position) > area_radius:
			continue
		targets.append(enemy_node)
	var hit_targets: Array[Enemy] = await CombatResolver.apply_school_hit_batch(controller.hero.stats_component, targets, SchoolRules.SCHOOL_EARTH, damage)
	if hit_targets.size() > 0:
		for enemy_node in hit_targets:
			if is_instance_valid(enemy_node):
				enemy_node.apply_vulnerability_stack(SchoolRules.SCHOOL_EARTH)
	return hit_targets.size() > 0

func _tick_bastion(delta: float) -> void:
	active_time_left = maxf(0.0, active_time_left - delta)
	tick_left = maxf(0.0, tick_left - delta)
	if tick_left > 0.0:
		return
	if tick_in_progress:
		return
	tick_left = tick_interval
	tick_in_progress = true
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"bastion_crash")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"bastion_crash")
	var tick_damage := GameState.build_hero_stats().damage * damage_ratio * 0.55 * skill_damage_mult * skill_proc_mult
	await _hit_enemies_around(controller.hero.global_position, tick_damage)
	tick_in_progress = false

func _spawn_bastion(center_position: Vector2) -> void:
	var bastion := EarthAreaEffectScript.new()
	bastion.setup(center_position, EarthAreaEffectScript.AreaKind.BASTION, area_radius, active_duration)
	controller.spawn_effect(bastion)
