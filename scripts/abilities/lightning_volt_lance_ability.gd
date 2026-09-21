extends AbilityBase
class_name LightningVoltLanceAbility

const LightningAreaEffectScript = preload("res://scripts/effects/lightning_area_effect.gd")

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 5.8
var cast_range: float = 460.0
var lance_width: float = 62.0
var damage_ratio: float = 1.15
var cast_in_progress: bool = false

func _init(owner_controller: AbilityController) -> void:
	controller = owner_controller

func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if cooldown_left > 0.0 or cast_in_progress:
		return
	if controller == null or controller.hero == null:
		return

	var primary := _find_primary_target()
	if primary == null:
		return

	cast_in_progress = true
	var skill_damage_mult := GameState.get_skill_damage_multiplier(&"volt_lance")
	var skill_cd_mult := GameState.get_skill_cooldown_multiplier(&"volt_lance")
	var skill_proc_mult := GameState.get_skill_proc_multiplier(&"volt_lance")
	var damage := GameState.build_hero_stats().damage * damage_ratio * skill_damage_mult * skill_proc_mult
	var from_position := controller.hero.global_position
	var direction := (primary.global_position - from_position).normalized()
	var to_position := from_position + direction * cast_range
	var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
	var hit_any := false
	for _repeat in range(repeat_count):
		hit_any = await _hit_enemies_on_line(from_position, to_position, damage) or hit_any

	if not hit_any:
		cast_in_progress = false
		return
	controller.hero.play_skill_cast(&"volt_lance")
	_spawn_lance(from_position, to_position)
	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_LIGHTNING, 2)
	cooldown_left = cooldown_duration * skill_cd_mult
	cast_in_progress = false

func get_display_name() -> String:
	return "Volt Lance"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _hit_enemies_on_line(from_position: Vector2, to_position: Vector2, damage: float) -> bool:
	var targets: Array[Enemy] = []
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy is not Enemy:
			continue
		var enemy_node := enemy as Enemy
		if _distance_to_segment(enemy_node.global_position, from_position, to_position) > lance_width:
			continue
		targets.append(enemy_node)
	var hit_targets: Array[Enemy] = await CombatResolver.apply_school_hit_batch(controller.hero.stats_component, targets, SchoolRules.SCHOOL_LIGHTNING, damage)
	return hit_targets.size() > 0

func _distance_to_segment(point: Vector2, from_position: Vector2, to_position: Vector2) -> float:
	var segment := to_position - from_position
	var segment_length_sq := segment.length_squared()
	if segment_length_sq <= 0.001:
		return point.distance_to(from_position)
	var t := clampf((point - from_position).dot(segment) / segment_length_sq, 0.0, 1.0)
	return point.distance_to(from_position + segment * t)

func _spawn_lance(from_position: Vector2, to_position: Vector2) -> void:
	var effect := LightningAreaEffectScript.new()
	effect.setup_lance(from_position, to_position, 0.30)
	controller.spawn_effect(effect)
