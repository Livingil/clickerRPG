extends AbilityBase
class_name LightningThunderCrownAbility

const LightningAreaEffectScript = preload("res://scripts/effects/lightning_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 9.0
var active_time_left: float = 0.0
var active_duration: float = 6.0
var tick_interval: float = 0.65
var tick_left: float = 0.0
var cast_range: float = 470.0
var area_radius: float = 205.0
var damage_ratio: float = 0.45
var tick_in_progress: bool = false

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if active_time_left > 0.0:
		_tick_active(delta)
		return
	if cooldown_left > 0.0:
		return
	if controller == null or controller.hero == null:
		return
	if _find_primary_target() == null:
		return

	active_time_left = active_duration
	tick_left = 0.0
	cooldown_left = cooldown_duration * GameState.get_skill_cooldown_multiplier(&"thunder_crown")
	controller.hero.play_skill_cast(&"thunder_crown")
	_spawn_crown()
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_LIGHTNING, 2)

func get_display_name() -> String:
	return "Thunder Crown"

func _tick_active(delta: float) -> void:
	active_time_left = maxf(0.0, active_time_left - delta)
	tick_left = maxf(0.0, tick_left - delta)
	if tick_left > 0.0:
		return
	if tick_in_progress:
		return
	tick_left = tick_interval
	tick_in_progress = true
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"thunder_crown")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"thunder_crown")
	var damage := GameState.build_hero_stats().damage * damage_ratio * skill_damage_mult * skill_proc_mult
	await _hit_enemies_around(controller.hero.global_position, damage)
	tick_in_progress = false

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
	var hit_targets: Array[Enemy] = await CombatResolver.apply_school_hit_batch(controller.hero.stats_component, targets, SchoolRules.SCHOOL_LIGHTNING, damage)
	return hit_targets.size() > 0

func _spawn_crown() -> void:
	var effect := LightningAreaEffectScript.new()
	effect.setup_crown(controller.hero, area_radius, active_duration)
	controller.spawn_effect(effect)
