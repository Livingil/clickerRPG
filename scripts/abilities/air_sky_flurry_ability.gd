extends AbilityBase
class_name AirSkyFlurryAbility

const AirAreaEffectScript = preload("res://scripts/effects/air_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 8.5
var cast_range: float = 460.0
var area_radius: float = 230.0
var damage_ratio: float = 0.50
var ranged_damage_ratio: float = 0.72
var strike_count: int = 3
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
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"sky_flurry")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"sky_flurry")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"sky_flurry")
	var hero_damage := GameState.build_hero_stats().damage
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var hit_any := false
	for _repeat in range(repeat_count):
		for _strike in range(strike_count):
			var target := _find_primary_target()
			if target == null:
				continue
			var hit_ratio := ranged_damage_ratio if _is_priority_ranged(target) else damage_ratio
			var damage := hero_damage * hit_ratio * skill_damage_mult * skill_proc_mult
			var hit := await CombatResolver.apply_school_hit(controller.hero.stats_component, target, SchoolRules.SCHOOL_AIR, damage)
			if hit:
				if _is_priority_ranged(target):
					target.apply_vulnerability_stack(SchoolRules.SCHOOL_AIR)
					target.delay_next_attack(SchoolRules.AIR_ATTACK_DELAY_ON_CONTROL * 1.6)
				else:
					target.delay_next_attack(SchoolRules.AIR_ATTACK_DELAY_ON_CONTROL)
				target.apply_knockback_from(controller.hero.global_position, SchoolRules.AIR_FLURRY_KNOCKBACK)
				hit_any = true

	if not hit_any:
		cast_in_progress = false
		return
	controller.hero.play_skill_cast(&"sky_flurry")
	_spawn_flurry(controller.hero.global_position)
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_AIR, 5)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Sky Flurry"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	var ranged_target := _find_ranged_target(enemies)
	if ranged_target != null:
		return ranged_target
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _find_ranged_target(enemies: Array[Node]) -> Enemy:
	var best: Enemy = null
	var best_distance_sq := cast_range * cast_range
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy is not Enemy:
			continue
		var enemy_node := enemy as Enemy
		if not _is_priority_ranged(enemy_node):
			continue
		var distance_sq := controller.hero.global_position.distance_squared_to(enemy_node.global_position)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best = enemy_node
	return best

func _is_priority_ranged(enemy: Enemy) -> bool:
	return enemy != null and not enemy.is_boss and enemy.normal_enemy_type == GameConstants.ENEMY_TYPE_RANGED

func _spawn_flurry(center_position: Vector2) -> void:
	var flurry := AirAreaEffectScript.new()
	flurry.setup(center_position, AirAreaEffectScript.AreaKind.FLURRY, area_radius, 0.78)
	controller.spawn_effect(flurry)
