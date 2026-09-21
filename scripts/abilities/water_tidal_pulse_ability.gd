extends AbilityBase
class_name WaterTidalPulseAbility

const WaterAreaEffectScript = preload("res://scripts/effects/water_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 6.5
var cast_range: float = 440.0
var area_radius: float = 165.0
var area_duration: float = 4.0
var tick_interval: float = 0.65
var tick_ratio: float = 0.30
var heal_ratio_per_hit: float = 0.002
var heal_cap_ratio_per_tick: float = 0.0055

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if cooldown_left > 0.0:
		return
	if controller == null or controller.hero == null:
		return

	var target := _find_primary_target()
	if target == null:
		return

	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"tidal_pulse")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"tidal_pulse")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"tidal_pulse")
	var tick_damage := GameState.build_hero_stats().damage * tick_ratio * skill_damage_mult * skill_proc_mult
	var heal_per_hit := controller.hero.max_hp * heal_ratio_per_hit
	var heal_cap := controller.hero.max_hp * heal_cap_ratio_per_tick
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	for _i in range(repeat_count):
		_spawn_tide(target.global_position, tick_damage, heal_per_hit, heal_cap)

	controller.hero.play_skill_cast(&"tidal_pulse")
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_WATER, 2)
	cooldown_left = cooldown_duration * skill_cd_mult

func get_display_name() -> String:
	return "Tidal Pulse"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _spawn_tide(center_position: Vector2, tick_damage: float, heal_per_hit: float, heal_cap: float) -> void:
	var tide := WaterAreaEffectScript.new()
	tide.setup(
		center_position,
		WaterAreaEffectScript.AreaKind.TIDAL,
		area_radius,
		area_duration,
		tick_interval,
		tick_damage,
		controller.hero.stats_component.get_accuracy(),
		controller.hero,
		heal_per_hit,
		heal_cap
	)
	controller.spawn_effect(tide)
