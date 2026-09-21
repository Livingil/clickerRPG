extends AbilityBase
class_name EarthQuakeRingAbility

const EarthAreaEffectScript = preload("res://scripts/effects/earth_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 6.3
var cast_range: float = 440.0
var area_radius: float = 215.0
var damage_ratio: float = 0.58
var knockback_distance: float = 120.0
var cast_in_progress: bool = false

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if cooldown_left > 0.0 or cast_in_progress:
		return
	if controller == null or controller.hero == null:
		return
	if _find_primary_target() == null:
		return

	cast_in_progress = true
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"quake_ring")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"quake_ring")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"quake_ring")
	var hit_damage := GameState.build_hero_stats().damage * damage_ratio * skill_damage_mult * skill_proc_mult
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var hit_any := false
	for _i in range(repeat_count):
		hit_any = await _hit_enemies_around(controller.hero.global_position, hit_damage) or hit_any

	if not hit_any:
		cast_in_progress = false
		return
	controller.hero.play_skill_cast(&"quake_ring")
	_spawn_quake(controller.hero.global_position)
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_EARTH, 2)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Quake Ring"

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
				enemy_node.apply_knockback_from(center_position, knockback_distance)
	return hit_targets.size() > 0

func _spawn_quake(center_position: Vector2) -> void:
	var quake := EarthAreaEffectScript.new()
	quake.setup(center_position, EarthAreaEffectScript.AreaKind.QUAKE, area_radius, 0.65)
	controller.spawn_effect(quake)
