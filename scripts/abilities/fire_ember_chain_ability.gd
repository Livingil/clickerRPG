extends AbilityBase
class_name FireEmberChainAbility

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 3.0
var chain_ratio: float = 1.0
var chain_range: float = 260.0
var cast_range: float = 420.0
var single_target_ratio: float = 1.15

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
	var chain_target := _find_chain_target(primary_target)
	controller.hero.play_skill_cast(&"ember_chain")
	if chain_target == null:
		var single_damage := GameState.build_hero_stats().damage * single_target_ratio
		primary_target.receive_school_hit(single_damage, SchoolRules.SCHOOL_FIRE, controller.hero.stats_component.get_accuracy())
		_spawn_chain_vfx([
			controller.hero.global_position,
			primary_target.global_position,
		])
	else:
		var base_damage := GameState.build_hero_stats().damage * chain_ratio
		primary_target.receive_school_hit(base_damage, SchoolRules.SCHOOL_FIRE, controller.hero.stats_component.get_accuracy())
		chain_target.receive_school_hit(base_damage, SchoolRules.SCHOOL_FIRE, controller.hero.stats_component.get_accuracy())
		_spawn_chain_vfx([
			controller.hero.global_position,
			primary_target.global_position,
			chain_target.global_position,
		])
	GameState.add_active_school_mastery_xp(3)
	cooldown_left = cooldown_duration

func get_display_name() -> String:
	return "Ember Chain"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _find_chain_target(primary_target: Enemy) -> Enemy:
	if controller.hero == null:
		return null
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	var candidates: Array[Node] = []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy == primary_target:
			continue
		candidates.append(enemy)

	return TargetSelector.closest_enemy_in_range(primary_target.global_position, candidates, chain_range) as Enemy

func _spawn_chain_vfx(points: Array[Vector2]) -> void:
	if controller == null:
		return
	var arc := FireChainArc.new()
	arc.setup_points(points)
	controller.spawn_effect(arc)
