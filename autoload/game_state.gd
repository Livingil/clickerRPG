extends Node

signal resources_changed(gold: int, essence: int)
signal echo_changed(collected_echo: int, active_echo_power: int)
signal hero_stats_changed
signal upgrades_changed
signal school_state_changed
signal prestige_performed

const UPGRADE_DAMAGE: StringName = &"damage"
const UPGRADE_ATTACK_SPEED: StringName = &"attack_speed"
const UPGRADE_CRIT_CHANCE: StringName = &"crit_chance"
const UPGRADE_CRIT_MULTIPLIER: StringName = &"crit_multiplier"

var gold: int = 0
var essence: int = 0
var echo_collected: int = 0
var echo_power: int = 0
var highest_wave_reached: int = 1
var active_school: StringName = SchoolRules.SCHOOL_FIRE
var school_mastery_xp: Dictionary = {}
var unlocked_global_skill_ids: Array[StringName] = []
var equipped_skill_ids: Array[StringName] = []

var bonus_damage: float = 0.0
var bonus_attack_speed: float = 0.0
var bonus_crit_chance: float = 0.0
var bonus_crit_multiplier: float = 0.0

var upgrade_levels: Dictionary = {
	UPGRADE_DAMAGE: 0,
	UPGRADE_ATTACK_SPEED: 0,
	UPGRADE_CRIT_CHANCE: 0,
	UPGRADE_CRIT_MULTIPLIER: 0,
}

var upgrade_definitions: Dictionary = {
	UPGRADE_DAMAGE: {
		"name": "Damage",
		"base_cost": 20,
		"cost_scale": 1.35,
		"value_per_level": 4.0,
	},
	UPGRADE_ATTACK_SPEED: {
		"name": "Attack Speed",
		"base_cost": 25,
		"cost_scale": 1.4,
		"value_per_level": 0.12,
	},
	UPGRADE_CRIT_CHANCE: {
		"name": "Crit Chance",
		"base_cost": 30,
		"cost_scale": 1.45,
		"value_per_level": 0.02,
	},
	UPGRADE_CRIT_MULTIPLIER: {
		"name": "Crit Mult",
		"base_cost": 40,
		"cost_scale": 1.5,
		"value_per_level": 0.15,
	},
}

func _ready() -> void:
	for school_id: StringName in SchoolRules.SCHOOL_ORDER:
		school_mastery_xp[school_id] = 0
	SignalBus.wave_changed.connect(_on_wave_changed)
	_rebuild_school_state()

func add_gold(value: int) -> void:
	gold += value
	resources_changed.emit(gold, essence)

func add_essence(value: int) -> void:
	essence += value
	resources_changed.emit(gold, essence)

func add_echo(value: int) -> void:
	echo_collected += value
	echo_changed.emit(echo_collected, echo_power)

func build_hero_stats() -> CombatStats:
	var stats := CombatStats.new()
	stats.damage = GameConstants.HERO_BASE_DAMAGE + bonus_damage + get_active_echo_damage_bonus()
	stats.attack_speed = GameConstants.HERO_BASE_ATTACK_SPEED + bonus_attack_speed + get_active_echo_attack_speed_bonus()
	stats.crit_chance = clampf(GameConstants.HERO_BASE_CRIT_CHANCE + bonus_crit_chance, 0.0, 1.0)
	stats.crit_multiplier = maxf(1.0, GameConstants.HERO_BASE_CRIT_MULTIPLIER + bonus_crit_multiplier)
	return stats

func get_hero_dps() -> float:
	return build_hero_stats().compute_dps()

func get_school_ids() -> Array[StringName]:
	return SchoolRules.SCHOOL_ORDER.duplicate()

func get_school_definition(school_id: StringName) -> Dictionary:
	return SchoolRules.SCHOOL_DEFINITIONS.get(school_id, {})

func get_active_school_summary() -> Dictionary:
	var definition := get_school_definition(active_school)
	var mastery_level := get_school_mastery_level(active_school)
	var mastery_xp := get_school_mastery_xp(active_school)
	return {
		"id": active_school,
		"name": String(definition.get("name", "Unknown")),
		"core_label": String(definition.get("core_label", "Staff")),
		"mastery_level": mastery_level,
		"mastery_xp": mastery_xp,
		"current_level_floor_xp": SchoolRules.get_current_level_floor_xp(mastery_level),
		"next_level_xp": SchoolRules.get_next_level_xp(mastery_level),
	}

func get_school_mastery_xp(school_id: StringName) -> int:
	return int(school_mastery_xp.get(school_id, 0))

func get_school_mastery_level(school_id: StringName) -> int:
	return SchoolRules.get_total_mastery_level_from_xp(get_school_mastery_xp(school_id))

func get_school_core_mastery_level(school_id: StringName) -> int:
	return SchoolRules.get_core_mastery_level_from_xp(get_school_mastery_xp(school_id))

func add_active_school_mastery_xp(value: int) -> void:
	school_mastery_xp[active_school] = get_school_mastery_xp(active_school) + value
	_rebuild_school_state()

func get_mastery_xp_for_enemy(boss_kind: StringName) -> int:
	match boss_kind:
		&"wave":
			return 10
		&"mini":
			return 25
		&"grand":
			return 60
		_:
			return 0

func set_active_school(school_id: StringName) -> void:
	if not SchoolRules.SCHOOL_DEFINITIONS.has(school_id):
		return
	active_school = school_id
	_rebuild_school_state()

func get_permanent_skill_slot_count() -> int:
	return SchoolRules.get_skill_slot_count_for_highest_wave(highest_wave_reached)

func get_available_skill_ids() -> Array[StringName]:
	var available: Array[StringName] = []
	var active_school_skills: Array = get_school_definition(active_school).get("skills", [])
	for skill_id_variant in active_school_skills:
		var skill_id := skill_id_variant as StringName
		if _is_skill_unlocked_for_active_school(skill_id):
			available.append(skill_id)

	for skill_id in unlocked_global_skill_ids:
		if not available.has(skill_id):
			available.append(skill_id)

	return available

func get_equipped_skill_ids() -> Array[StringName]:
	return equipped_skill_ids.duplicate()

func equip_skill(slot_index: int, skill_id: StringName) -> bool:
	if slot_index < 0 or slot_index >= get_permanent_skill_slot_count():
		return false
	if not get_available_skill_ids().has(skill_id):
		return false
	while equipped_skill_ids.size() < get_permanent_skill_slot_count():
		equipped_skill_ids.append(&"")
	equipped_skill_ids[slot_index] = skill_id
	school_state_changed.emit()
	return true

func equip_skill_to_first_open_slot(skill_id: StringName) -> bool:
	for slot_index in range(get_permanent_skill_slot_count()):
		if slot_index >= equipped_skill_ids.size():
			return equip_skill(slot_index, skill_id)
		if equipped_skill_ids[slot_index] == &"":
			return equip_skill(slot_index, skill_id)
	return false

func clear_skill_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= get_permanent_skill_slot_count():
		return false
	if slot_index >= equipped_skill_ids.size():
		return false
	equipped_skill_ids[slot_index] = &""
	school_state_changed.emit()
	return true

func replace_skill(slot_index: int, skill_id: StringName) -> bool:
	if slot_index < 0 or slot_index >= get_permanent_skill_slot_count():
		return false
	if not get_available_skill_ids().has(skill_id):
		return false
	while equipped_skill_ids.size() < get_permanent_skill_slot_count():
		equipped_skill_ids.append(&"")
	equipped_skill_ids[slot_index] = skill_id
	school_state_changed.emit()
	return true

func get_available_skill_ui_data() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var has_open_slot := false
	var slot_count := get_permanent_skill_slot_count()
	for slot_index in range(get_permanent_skill_slot_count()):
		if slot_index >= equipped_skill_ids.size() or equipped_skill_ids[slot_index] == &"":
			has_open_slot = true
			break
	for skill_id in get_available_skill_ids():
		var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
		var equipped := equipped_skill_ids.has(skill_id)
		var unlock_level := int(skill_data.get("unlock_level", 0))
		var can_equip := equipped or slot_count > 0
		var state_text := "Need Wave %d slot" % SchoolRules.SLOT_WAVE_UNLOCKS[0]
		if equipped:
			state_text = "Equipped"
		elif slot_count > 0 and has_open_slot:
			state_text = "Available"
		elif slot_count > 0:
			state_text = "Select To Replace"
		rows.append({
			"id": skill_id,
			"name": String(skill_data.get("name", skill_id)),
			"equipped": equipped,
			"can_equip": can_equip,
			"unlock_level": unlock_level,
			"state_text": state_text,
		})
	return rows

func get_ability_panel_rows() -> Array[String]:
	var rows: Array[String] = []
	var slot_count := get_permanent_skill_slot_count()
	rows.append("Unlocks at mastery 1 / 5 / 10")
	rows.append("Equipped:")
	for slot_index in range(4):
		var slot_label := "Locked"
		if slot_index < slot_count:
			var equipped_skill_id: StringName = &""
			if slot_index < equipped_skill_ids.size():
				equipped_skill_id = equipped_skill_ids[slot_index]
			slot_label = "Empty"
			if equipped_skill_id != &"":
				var equipped_skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(equipped_skill_id, {})
				slot_label = String(equipped_skill_data.get("name", equipped_skill_id))
		rows.append("Slot %d: %s" % [slot_index + 1, slot_label])

	return rows

func activate_collected_echo() -> void:
	if echo_collected <= 0:
		return
	echo_power += echo_collected
	echo_collected = 0
	echo_changed.emit(echo_collected, echo_power)
	hero_stats_changed.emit()

func get_active_echo_damage_bonus() -> float:
	return echo_power * 0.3

func get_active_echo_attack_speed_bonus() -> float:
	return floor(float(echo_power) / 20.0) * 0.03

func get_active_echo_bonus_summary() -> String:
	return "+%.1f dmg  +%.2f atk/s" % [
		get_active_echo_damage_bonus(),
		get_active_echo_attack_speed_bonus(),
	]

func get_collected_echo_bonus_summary() -> String:
	return "+%.1f dmg  +%.2f atk/s after death" % [
		echo_collected * 0.3,
		floor(float(echo_collected) / 20.0) * 0.03,
	]

func get_echo_gain_for_enemy(boss_kind: StringName) -> int:
	match boss_kind:
		&"wave":
			return 4
		&"mini":
			return 12
		&"grand":
			return 24
		_:
			return 1

func get_upgrade_ids() -> Array[StringName]:
	return [
		UPGRADE_DAMAGE,
		UPGRADE_ATTACK_SPEED,
		UPGRADE_CRIT_CHANCE,
		UPGRADE_CRIT_MULTIPLIER,
	]

func get_upgrade_level(upgrade_id: StringName) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))

func get_upgrade_cost(upgrade_id: StringName) -> int:
	var definition: Dictionary = upgrade_definitions.get(upgrade_id, {})
	var base_cost: int = int(definition.get("base_cost", 10))
	var cost_scale: float = float(definition.get("cost_scale", 1.25))
	var level := get_upgrade_level(upgrade_id)
	return int(round(base_cost * pow(cost_scale, level)))

func can_buy_upgrade(upgrade_id: StringName) -> bool:
	return gold >= get_upgrade_cost(upgrade_id)

func buy_upgrade(upgrade_id: StringName) -> bool:
	if not upgrade_definitions.has(upgrade_id):
		return false
	if not can_buy_upgrade(upgrade_id):
		return false

	gold -= get_upgrade_cost(upgrade_id)
	upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	_apply_upgrade_bonuses()
	resources_changed.emit(gold, essence)
	hero_stats_changed.emit()
	upgrades_changed.emit()
	return true

func get_upgrade_ui_data(upgrade_id: StringName) -> Dictionary:
	var definition: Dictionary = upgrade_definitions.get(upgrade_id, {})
	return {
		"id": upgrade_id,
		"name": String(definition.get("name", "Upgrade")),
		"level": get_upgrade_level(upgrade_id),
		"cost": get_upgrade_cost(upgrade_id),
		"affordable": can_buy_upgrade(upgrade_id),
		"next_bonus_text": _build_upgrade_bonus_text(upgrade_id),
	}

func _build_upgrade_bonus_text(upgrade_id: StringName) -> String:
	var definition: Dictionary = upgrade_definitions.get(upgrade_id, {})
	var value_per_level: float = float(definition.get("value_per_level", 0.0))

	match upgrade_id:
		UPGRADE_DAMAGE:
			return "+%.0f damage" % value_per_level
		UPGRADE_ATTACK_SPEED:
			return "+%.2f atk/s" % value_per_level
		UPGRADE_CRIT_CHANCE:
			return "+%.0f%% crit" % (value_per_level * 100.0)
		UPGRADE_CRIT_MULTIPLIER:
			return "+%.0f%% crit dmg" % (value_per_level * 100.0)
		_:
			return ""

func _apply_upgrade_bonuses() -> void:
	bonus_damage = get_upgrade_level(UPGRADE_DAMAGE) * float(upgrade_definitions[UPGRADE_DAMAGE]["value_per_level"])
	bonus_attack_speed = get_upgrade_level(UPGRADE_ATTACK_SPEED) * float(upgrade_definitions[UPGRADE_ATTACK_SPEED]["value_per_level"])
	bonus_crit_chance = get_upgrade_level(UPGRADE_CRIT_CHANCE) * float(upgrade_definitions[UPGRADE_CRIT_CHANCE]["value_per_level"])
	bonus_crit_multiplier = get_upgrade_level(UPGRADE_CRIT_MULTIPLIER) * float(upgrade_definitions[UPGRADE_CRIT_MULTIPLIER]["value_per_level"])

func perform_prestige() -> void:
	gold = 0
	essence = 0
	echo_collected = 0
	echo_power = 0
	for upgrade_id: StringName in get_upgrade_ids():
		upgrade_levels[upgrade_id] = 0
	_apply_upgrade_bonuses()
	resources_changed.emit(gold, essence)
	echo_changed.emit(echo_collected, echo_power)
	hero_stats_changed.emit()
	upgrades_changed.emit()
	prestige_performed.emit()
	school_state_changed.emit()

func _on_wave_changed(current_wave: int) -> void:
	if current_wave > highest_wave_reached:
		highest_wave_reached = current_wave
		_rebuild_school_state()

func _rebuild_school_state() -> void:
	_rebuild_global_skill_pool()
	_trim_equipped_skills_to_permanent_slots()
	school_state_changed.emit()

func _rebuild_global_skill_pool() -> void:
	unlocked_global_skill_ids.clear()
	for school_id: StringName in SchoolRules.SCHOOL_ORDER:
		if get_school_core_mastery_level(school_id) < 10:
			continue
		var school_skills: Array = get_school_definition(school_id).get("skills", [])
		for skill_id_variant in school_skills:
			var skill_id := skill_id_variant as StringName
			if not unlocked_global_skill_ids.has(skill_id):
				unlocked_global_skill_ids.append(skill_id)

func _trim_equipped_skills_to_permanent_slots() -> void:
	var allowed_slots := get_permanent_skill_slot_count()
	while equipped_skill_ids.size() > allowed_slots:
		equipped_skill_ids.remove_at(equipped_skill_ids.size() - 1)
	while equipped_skill_ids.size() < allowed_slots:
		equipped_skill_ids.append(&"")

func _is_skill_unlocked_for_active_school(skill_id: StringName) -> bool:
	var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
	var unlock_level := int(skill_data.get("unlock_level", 999))
	return get_school_core_mastery_level(active_school) >= unlock_level
