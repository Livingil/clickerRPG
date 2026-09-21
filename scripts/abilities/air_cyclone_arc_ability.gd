extends AbilityBase
class_name AirCycloneArcAbility

const AirAreaEffectScript = preload("res://scripts/effects/air_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 6.2
var cast_range: float = 440.0
var area_radius: float = 205.0
var damage_ratio: float = 0.62
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
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"cyclone_arc")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"cyclone_arc")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"cyclone_arc")
	var damage := GameState.build_hero_stats().damage * damage_ratio * skill_damage_mult * skill_proc_mult
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var hit_any := false
	for _i in range(repeat_count):
		hit_any = await _hit_enemies_around(target.global_position, damage) or hit_any

	if not hit_any:
		cast_in_progress = false
		return
	controller.hero.play_skill_cast(&"cyclone_arc")
	_spawn_cyclone(target.global_position)
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_AIR, 2)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Cyclone Arc"

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
	var hit_targets: Array[Enemy] = await CombatResolver.apply_school_hit_batch(controller.hero.stats_component, targets, SchoolRules.SCHOOL_AIR, damage)
	if hit_targets.size() > 0:
		for enemy_node in hit_targets:
			if is_instance_valid(enemy_node):
				enemy_node.apply_vulnerability_stack(SchoolRules.SCHOOL_AIR)
				enemy_node.delay_next_attack(SchoolRules.AIR_ATTACK_DELAY_ON_CONTROL)
				enemy_node.apply_pull_towards(center_position, SchoolRules.AIR_CYCLONE_PULL)
	return hit_targets.size() > 0

func _spawn_cyclone(center_position: Vector2) -> void:
	var cyclone := AirAreaEffectScript.new()
	cyclone.setup(center_position, AirAreaEffectScript.AreaKind.CYCLONE, area_radius, 0.70)
	controller.spawn_effect(cyclone)
