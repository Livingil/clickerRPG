extends AbilityBase
class_name WaterBlizzardAbility

const WaterAreaEffectScript = preload("res://scripts/effects/water_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 10.5
var cast_range: float = 520.0
var duration: float = 3.8
var tick_interval: float = 0.85
var tick_ratio: float = 0.24

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if cooldown_left > 0.0:
		return
	if controller == null or controller.hero == null:
		return
	if _find_primary_target() == null:
		return

	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"glacial_field")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"glacial_field")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"glacial_field")
	var tick_damage := GameState.build_hero_stats().damage * tick_ratio * skill_damage_mult * skill_proc_mult
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	for _i in range(repeat_count):
		_spawn_blizzard(tick_damage)

	controller.hero.play_skill_cast(&"glacial_field")
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_WATER, 5)
	cooldown_left = cooldown_duration * skill_cd_mult

func get_display_name() -> String:
	return "Blizzard"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _spawn_blizzard(tick_damage: float) -> void:
	var blizzard := WaterAreaEffectScript.new()
	blizzard.setup(
		GameConstants.ARENA_MIN,
		WaterAreaEffectScript.AreaKind.BLIZZARD,
		0.0,
		duration,
		tick_interval,
		tick_damage,
		controller.hero.stats_component.get_accuracy()
	)
	controller.spawn_effect(blizzard)
