extends AbilityBase
class_name FireCinderBurstAbility

var controller: AbilityController
var cooldown_left: float = 0.0
var cooldown_duration: float = 5.5
var splash_ratio: float = 0.9
var splash_range: float = 170.0
var cast_range: float = 420.0

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

	var target := _find_primary_target()
	if target == null:
		return

	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	var hit_any := false
	var base_damage := GameState.build_hero_stats().damage * splash_ratio

	target.take_school_damage(base_damage, SchoolRules.SCHOOL_FIRE)
	hit_any = true
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy is not Enemy:
			continue

		var enemy_node := enemy as Enemy
		if enemy_node == target:
			continue

		if enemy_node.global_position.distance_to(target.global_position) <= splash_range:
			enemy_node.take_school_damage(base_damage, SchoolRules.SCHOOL_FIRE)
			hit_any = true

	if hit_any:
		controller.hero.play_skill_cast(&"cinder_burst")
		_spawn_burst_vfx(target.global_position)
		GameState.add_active_school_mastery_xp(3)
		cooldown_left = cooldown_duration

func get_display_name() -> String:
	return "Cinder Burst"

func _find_primary_target() -> Enemy:
	var enemies := controller.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

func _spawn_burst_vfx(center_position: Vector2) -> void:
	if controller == null:
		return
	var burst := FireBurstRing.new()
	burst.setup(center_position, splash_range * 0.35)
	controller.spawn_effect(burst)
