extends Node
class_name AbilityController

const FireAshStormAbilityScript = preload("res://scripts/abilities/fire_ash_storm_ability.gd")
const WaterFrostOrbAbilityScript = preload("res://scripts/abilities/water_frost_orb_ability.gd")
const WaterTidalPulseAbilityScript = preload("res://scripts/abilities/water_tidal_pulse_ability.gd")
const WaterBlizzardAbilityScript = preload("res://scripts/abilities/water_blizzard_ability.gd")
const EarthStoneSpikeAbilityScript = preload("res://scripts/abilities/earth_stone_spike_ability.gd")
const EarthQuakeRingAbilityScript = preload("res://scripts/abilities/earth_quake_ring_ability.gd")
const EarthBastionCrashAbilityScript = preload("res://scripts/abilities/earth_bastion_crash_ability.gd")
const AirRazorGustAbilityScript = preload("res://scripts/abilities/air_razor_gust_ability.gd")
const AirCycloneArcAbilityScript = preload("res://scripts/abilities/air_cyclone_arc_ability.gd")
const AirSkyFlurryAbilityScript = preload("res://scripts/abilities/air_sky_flurry_ability.gd")
const LightningSparkJumpAbilityScript = preload("res://scripts/abilities/lightning_spark_jump_ability.gd")
const LightningVoltLanceAbilityScript = preload("res://scripts/abilities/lightning_volt_lance_ability.gd")
const LightningThunderCrownAbilityScript = preload("res://scripts/abilities/lightning_thunder_crown_ability.gd")

const GENERIC_SKILL_RUNTIME := {
	&"frost_orb": {"cooldown": 4.0, "ratio": 1.0, "range": 420.0, "radius": 0.0, "xp": 2},
	&"tidal_pulse": {"cooldown": 6.0, "ratio": 0.9, "range": 420.0, "radius": 165.0, "xp": 2},
	&"glacial_field": {"cooldown": 8.0, "ratio": 1.2, "range": 480.0, "radius": 190.0, "xp": 5},
	&"stone_spike": {"cooldown": 4.0, "ratio": 1.15, "range": 420.0, "radius": 0.0, "xp": 2},
	&"quake_ring": {"cooldown": 6.0, "ratio": 0.95, "range": 420.0, "radius": 175.0, "xp": 2},
	&"bastion_crash": {"cooldown": 8.0, "ratio": 1.35, "range": 460.0, "radius": 135.0, "xp": 5},
	&"razor_gust": {"cooldown": 3.8, "ratio": 0.95, "range": 440.0, "radius": 0.0, "xp": 2},
	&"cyclone_arc": {"cooldown": 6.2, "ratio": 0.85, "range": 440.0, "radius": 185.0, "xp": 2},
	&"sky_flurry": {"cooldown": 8.5, "ratio": 1.25, "range": 460.0, "radius": 115.0, "xp": 5},
	&"spark_jump": {"cooldown": 3.5, "ratio": 1.0, "range": 440.0, "radius": 0.0, "xp": 2},
	&"volt_lance": {"cooldown": 5.8, "ratio": 1.15, "range": 460.0, "radius": 62.0, "xp": 2},
	&"thunder_crown": {"cooldown": 9.0, "ratio": 0.45, "range": 470.0, "radius": 205.0, "xp": 2},
}

var active_abilities: Array[AbilityBase] = []
var active_skill_ids: Array[StringName] = []
var hero: Hero
var battlefield: Battlefield

func _ready() -> void:
	var root := get_parent()
	if root != null:
		hero = root.get_node_or_null("Hero") as Hero
		battlefield = root.get_node_or_null("Battlefield") as Battlefield
	GameState.school_state_changed.connect(_rebuild_active_abilities)
	_rebuild_active_abilities()

func _process(delta: float) -> void:
	for ability in active_abilities:
		ability.tick(delta)

func get_active_ability_names() -> Array[String]:
	var names: Array[String] = []
	for ability in active_abilities:
		names.append(ability.get_display_name())
	return names

func spawn_effect(effect: Node2D) -> void:
	if effect == null:
		return
	if battlefield == null:
		return
	battlefield.effects_container.add_child(effect)

func _rebuild_active_abilities() -> void:
	var desired_skill_ids := GameState.get_equipped_skill_ids()
	if desired_skill_ids == active_skill_ids:
		return

	active_skill_ids = desired_skill_ids.duplicate()
	active_abilities.clear()
	for skill_id in active_skill_ids:
		_append_ability_from_skill_id(skill_id)

func _append_ability_from_skill_id(skill_id: StringName) -> void:
	match skill_id:
		&"ember_chain":
			active_abilities.append(FireEmberChainAbility.new(self))
		&"cinder_burst":
			active_abilities.append(FireCinderBurstAbility.new(self))
		&"ash_storm":
			active_abilities.append(FireAshStormAbilityScript.new(self))
		&"frost_orb":
			active_abilities.append(WaterFrostOrbAbilityScript.new(self))
		&"tidal_pulse":
			active_abilities.append(WaterTidalPulseAbilityScript.new(self))
		&"glacial_field":
			active_abilities.append(WaterBlizzardAbilityScript.new(self))
		&"stone_spike":
			active_abilities.append(EarthStoneSpikeAbilityScript.new(self))
		&"quake_ring":
			active_abilities.append(EarthQuakeRingAbilityScript.new(self))
		&"bastion_crash":
			active_abilities.append(EarthBastionCrashAbilityScript.new(self))
		&"razor_gust":
			active_abilities.append(AirRazorGustAbilityScript.new(self))
		&"cyclone_arc":
			active_abilities.append(AirCycloneArcAbilityScript.new(self))
		&"sky_flurry":
			active_abilities.append(AirSkyFlurryAbilityScript.new(self))
		&"spark_jump":
			active_abilities.append(LightningSparkJumpAbilityScript.new(self))
		&"volt_lance":
			active_abilities.append(LightningVoltLanceAbilityScript.new(self))
		&"thunder_crown":
			active_abilities.append(LightningThunderCrownAbilityScript.new(self))
		_:
			if SchoolRules.SKILL_DEFINITIONS.has(skill_id):
				active_abilities.append(GenericSchoolDamageAbility.new(self, skill_id))

class GenericSchoolDamageAbility:
	extends AbilityBase

	var controller: AbilityController
	var skill_id: StringName = &""
	var school_id: StringName = &""
	var cooldown_left: float = 0.0
	var cooldown_duration: float = 4.0
	var damage_ratio: float = 1.0
	var cast_range: float = 420.0
	var splash_radius: float = 0.0
	var mastery_xp: int = 2
	var cast_in_progress: bool = false

	func _init(owner_controller: AbilityController, owner_skill_id: StringName) -> void:
		controller = owner_controller
		skill_id = owner_skill_id
		var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
		school_id = skill_data.get("school", GameState.active_school) as StringName
		var runtime_data: Dictionary = AbilityController.GENERIC_SKILL_RUNTIME.get(skill_id, {})
		cooldown_duration = float(runtime_data.get("cooldown", cooldown_duration))
		damage_ratio = float(runtime_data.get("ratio", damage_ratio))
		cast_range = float(runtime_data.get("range", cast_range))
		splash_radius = float(runtime_data.get("radius", splash_radius))
		mastery_xp = int(runtime_data.get("xp", mastery_xp))

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
		var hit_any := false
		var skill_damage_mult := GameState.get_skill_damage_multiplier(skill_id)
		var skill_cd_mult := GameState.get_skill_cooldown_multiplier(skill_id)
		var skill_proc_mult := GameState.get_skill_proc_multiplier(skill_id)
		var damage := GameState.build_hero_stats().damage * damage_ratio * skill_damage_mult * skill_proc_mult
		var repeat_count := 2 if GameState.should_trigger_repeat_action() else 1
		for _i in range(repeat_count):
			if splash_radius <= 0.0:
				hit_any = await CombatResolver.apply_school_hit(controller.hero.stats_component, primary_target, school_id, damage) or hit_any
			else:
				hit_any = await _hit_enemies_around(primary_target.global_position, damage) or hit_any

		if not hit_any:
			cast_in_progress = false
			return
		controller.hero.play_skill_cast(skill_id)
		GameState.add_school_mastery_xp(school_id, mastery_xp)
		cooldown_left = cooldown_duration * skill_cd_mult
		cast_in_progress = false

	func get_display_name() -> String:
		return String(SchoolRules.SKILL_DEFINITIONS.get(skill_id, {}).get("name", skill_id))

	func _find_primary_target() -> Enemy:
		var enemies := controller.get_tree().get_nodes_in_group("enemies")
		return TargetSelector.closest_enemy_in_range(controller.hero.global_position, enemies, cast_range) as Enemy

	func _hit_enemies_around(center_position: Vector2, damage: float) -> bool:
		var targets: Array[Enemy] = []
		var enemies := controller.get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			if enemy is not Enemy:
				continue
			var enemy_node := enemy as Enemy
			if enemy_node.global_position.distance_to(center_position) > splash_radius:
				continue
			targets.append(enemy_node)
		var hit_targets: Array[Enemy] = await CombatResolver.apply_school_hit_batch(controller.hero.stats_component, targets, school_id, damage)
		return hit_targets.size() > 0
