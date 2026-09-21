extends AbilityBase
class_name AirRazorGustAbility

const AirAreaEffectScript = preload("res://scripts/effects/air_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 3.8
var cast_range: float = 440.0
var damage_ratio: float = 0.95
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
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"razor_gust")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"razor_gust")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"razor_gust")
	var damage := GameState.build_hero_stats().damage * damage_ratio * skill_damage_mult * skill_proc_mult
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var hit_any := false
	for _i in range(repeat_count):
		var hit := await CombatResolver.apply_school_hit(controller.hero.stats_component, target, SchoolRules.SCHOOL_AIR, damage)
		if hit:
			target.delay_next_attack(SchoolRules.AIR_ATTACK_DELAY_ON_CONTROL)
			target.apply_knockback_from(controller.hero.global_position, SchoolRules.AIR_GUST_KNOCKBACK)
			hit_any = true

	if not hit_any:
		cast_in_progress = false
		return
	controller.hero.play_skill_cast(&"razor_gust")
	_spawn_gust(controller.hero.global_position, target.global_position)
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_AIR, 2)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Razor Gust"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _spawn_gust(origin: Vector2, target_position: Vector2) -> void:
	var gust := AirAreaEffectScript.new()
	var direction := target_position - origin
	gust.setup((origin + target_position) * 0.5, AirAreaEffectScript.AreaKind.GUST, 115.0, 0.45, direction)
	controller.spawn_effect(gust)
