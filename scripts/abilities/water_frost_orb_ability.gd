extends AbilityBase
class_name WaterFrostOrbAbility

const WaterAreaEffectScript = preload("res://scripts/effects/water_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 4.2
var cast_range: float = 430.0
var damage_ratio: float = 1.05
var puddle_radius: float = 92.0
var puddle_duration: float = 3.5
var puddle_tick_interval: float = 0.55
var puddle_tick_ratio: float = 0.18
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
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"frost_orb")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"frost_orb")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"frost_orb")
	var hit_damage := GameState.build_hero_stats().damage * damage_ratio * skill_damage_mult * skill_proc_mult
	var puddle_damage := GameState.build_hero_stats().damage * puddle_tick_ratio * skill_damage_mult * skill_proc_mult
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var hit_any := false
	for _i in range(repeat_count):
		var hit := await CombatResolver.apply_school_hit(controller.hero.stats_component, target, SchoolRules.SCHOOL_WATER, hit_damage)
		if hit:
			target.force_freeze(0.35)
			hit_any = true

	if not hit_any:
		cast_in_progress = false
		return
	controller.hero.play_skill_cast(&"frost_orb")
	_spawn_puddle(target.global_position, puddle_damage)
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_WATER, 2)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Frost Orb"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _spawn_puddle(center_position: Vector2, tick_damage: float) -> void:
	var puddle := WaterAreaEffectScript.new()
	puddle.setup(
		center_position,
		WaterAreaEffectScript.AreaKind.PUDDLE,
		puddle_radius,
		puddle_duration,
		puddle_tick_interval,
		tick_damage,
		controller.hero.stats_component.get_accuracy()
	)
	controller.spawn_effect(puddle)
