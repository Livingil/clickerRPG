extends AbilityBase
class_name FireEmberChainAbility

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 3.0
var cast_range: float = 420.0
var base_hit_ratio: float = 1.05
var burning_hit_ratio: float = 1.35
var spread_ratio: float = 0.35
var spread_range: float = 220.0
var max_spread_targets: int = 3
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
	var was_burning := _is_burning(primary_target)
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"ember_chain")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"ember_chain")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"ember_chain")
	var hero_damage := GameState.build_hero_stats().damage
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var hit_any := false
	for _i in range(repeat_count):
		var hit_ratio := burning_hit_ratio if was_burning else base_hit_ratio
		var hit_damage := hero_damage * hit_ratio * skill_damage_mult * skill_proc_mult
		var primary_hit := await CombatResolver.apply_school_hit(controller.hero.stats_component, primary_target, SchoolRules.SCHOOL_FIRE, hit_damage)
		hit_any = primary_hit or hit_any
		if primary_hit and was_burning:
			hit_any = await _spread_embers(primary_target, hero_damage * spread_ratio * skill_damage_mult * skill_proc_mult) or hit_any

	if hit_any:
		controller.hero.play_skill_cast(&"ember_chain")
		_spawn_mark_vfx(primary_target.global_position, was_burning)
		GameState.add_school_mastery_xp(SchoolRules.SCHOOL_FIRE, 2)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Ember Mark"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _is_burning(target: Enemy) -> bool:
	if target == null:
		return false
	return int(target.vulnerability_stacks.get(SchoolRules.SCHOOL_FIRE, 0)) > 0 or target.burn_time_left > 0.0

func _spread_embers(primary_target: Enemy, spread_damage: float) -> bool:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	var candidates: Array[Enemy] = []
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy is not Enemy:
			continue
		var enemy_node := enemy as Enemy
		if enemy_node == primary_target:
			continue
		if enemy_node.global_position.distance_to(primary_target.global_position) > spread_range:
			continue
		candidates.append(enemy_node)

	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.global_position.distance_squared_to(primary_target.global_position) < b.global_position.distance_squared_to(primary_target.global_position)
	)
	var spread_count := mini(max_spread_targets, candidates.size())
	var targets: Array[Enemy] = []
	for i in range(spread_count):
		targets.append(candidates[i])
	var hit_targets: Array[Enemy] = await CombatResolver.apply_school_hit_batch(controller.hero.stats_component, targets, SchoolRules.SCHOOL_FIRE, spread_damage)
	return hit_targets.size() > 0

func _spawn_mark_vfx(target_position: Vector2, spread_triggered: bool) -> void:
	if controller == null:
		return
	var arc := FireChainArc.new()
	arc.setup_points([
		controller.hero.global_position,
		target_position,
	])
	controller.spawn_effect(arc)
	if spread_triggered:
		var burst := preload("res://scenes/effects/fire_burst_ring.tscn").instantiate() as FireBurstRing
		if burst != null:
			burst.setup(target_position, spread_range * 0.35)
			controller.spawn_effect(burst)
