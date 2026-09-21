extends AbilityBase
class_name LightningSparkJumpAbility

const LightningAreaEffectScript = preload("res://scripts/effects/lightning_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 3.5
var cast_range: float = 440.0
var chain_range: float = 270.0
var damage_ratios: Array[float] = [1.0, 0.70, 0.50]
var cast_in_progress: bool = false

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if cooldown_left > 0.0 or cast_in_progress:
		return
	if controller == null or controller.hero == null:
		return

	var targets := _build_chain_targets()
	if targets.is_empty():
		return

	cast_in_progress = true
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"spark_jump")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"spark_jump")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"spark_jump")
	var base_damage := GameState.build_hero_stats().damage * skill_damage_mult * skill_proc_mult
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var hit_any := false
	for _repeat in range(repeat_count):
		for i in range(targets.size()):
			var target := targets[i]
			if not is_instance_valid(target):
				continue
			var ratio := damage_ratios[min(i, damage_ratios.size() - 1)]
			hit_any = await CombatResolver.apply_school_hit(controller.hero.stats_component, target, SchoolRules.SCHOOL_LIGHTNING, base_damage * ratio) or hit_any

	if not hit_any:
		cast_in_progress = false
		return
	controller.hero.play_skill_cast(&"spark_jump")
	_spawn_arc(targets)
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_LIGHTNING, 2)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Spark Jump"

func _build_chain_targets() -> Array[Enemy]:
	var result: Array[Enemy] = []
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	var primary := TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy
	if primary == null:
		return result
	result.append(primary)
	while result.size() < damage_ratios.size():
		var next_target := _find_next_chain_target(result[result.size() - 1], result)
		if next_target == null:
			break
		result.append(next_target)
	return result

func _find_next_chain_target(source: Enemy, used_targets: Array[Enemy]) -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	var best: Enemy = null
	var best_distance_sq := chain_range * chain_range
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy is not Enemy:
			continue
		var enemy_node := enemy as Enemy
		if used_targets.has(enemy_node):
			continue
		var distance_sq := source.global_position.distance_squared_to(enemy_node.global_position)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best = enemy_node
	return best

func _spawn_arc(targets: Array[Enemy]) -> void:
	var arc_points: Array[Vector2] = [controller.hero.global_position]
	for target in targets:
		if is_instance_valid(target):
			arc_points.append(target.global_position)
	var effect := LightningAreaEffectScript.new()
	effect.setup_arc(arc_points, 0.34)
	controller.spawn_effect(effect)
