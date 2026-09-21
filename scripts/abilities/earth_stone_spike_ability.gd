extends AbilityBase
class_name EarthStoneSpikeAbility

const EarthAreaEffectScript = preload("res://scripts/effects/earth_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 4.2
var cast_range: float = 430.0
var damage_ratio: float = 1.15
var frozen_bonus: float = 1.3
var spike_radius: float = 72.0
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
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"stone_spike")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"stone_spike")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"stone_spike")
	var hit_damage := GameState.build_hero_stats().damage * damage_ratio * skill_damage_mult * skill_proc_mult
	if target.is_control_locked():
		hit_damage *= frozen_bonus

	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var hit_any := false
	for _i in range(repeat_count):
		var hit := await CombatResolver.apply_school_hit(controller.hero.stats_component, target, SchoolRules.SCHOOL_EARTH, hit_damage)
		if hit:
			target.apply_vulnerability_stack(SchoolRules.SCHOOL_EARTH)
			hit_any = true

	if not hit_any:
		cast_in_progress = false
		return
	controller.hero.play_skill_cast(&"stone_spike")
	_spawn_spike(target.global_position)
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_EARTH, 2)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Stone Spike"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _spawn_spike(center_position: Vector2) -> void:
	var spike := EarthAreaEffectScript.new()
	spike.setup(center_position, EarthAreaEffectScript.AreaKind.SPIKE, spike_radius, 0.55)
	controller.spawn_effect(spike)
