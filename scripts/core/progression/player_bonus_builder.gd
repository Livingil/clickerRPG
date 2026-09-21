extends RefCounted
class_name PlayerBonusBuilder

static func build(
	equipment_levels: Dictionary,
	artifact_levels: Dictionary,
	owned_artifacts: Array[StringName]
) -> Dictionary:
	var bonuses: Dictionary = _empty_bonus_totals()
	_apply_equipment_bonuses(bonuses, equipment_levels)
	_apply_artifact_bonus_totals(bonuses, ArtifactProgressService.build_bonus_totals(artifact_levels, owned_artifacts))
	return bonuses

static func apply_to_game_state(game_state: Object, totals: Dictionary) -> void:
	game_state.bonus_totals = totals.duplicate(true)

static func _empty_bonus_totals() -> Dictionary:
	return {
		"damage": 0.0,
		"max_hp": 0.0,
		"attack_speed": 0.0,
		"crit_chance": 0.0,
		"crit_multiplier": 0.0,
		"defense": 0.0,
		"evasion": 0.0,
		"accuracy": 0.0,
		"artifact_bonus_block_chance": 0.0,
		"artifact_bonus_reflect_chance": 0.0,
		"artifact_bonus_reflect_ratio": 0.0,
		"artifact_bonus_haste_chance": 0.0,
		"artifact_bonus_haste_duration": 0.0,
		"artifact_bonus_repeat_chance": 0.0,
		"artifact_bonus_teleport_chance": 0.0,
		"artifact_bonus_clone_chance": 0.0,
		"artifact_bonus_clone_duration": 0.0,
		"artifact_bonus_clone_stat_multiplier": 0.0,
		"artifact_bonus_skill_damage_mult": 0.0,
		"artifact_bonus_skill_proc_mult": 0.0,
		"artifact_bonus_boss_timer_sec": 0.0,
		"artifact_bonus_gold_mult": 0.0,
		"artifact_bonus_echo_mult": 0.0,
		"artifact_bonus_essence_mult": 0.0,
		"artifact_bonus_boss_damage_reduction": 0.0,
		"artifact_bonus_boss_damage_mult": 0.0,
		"artifact_bonus_school_xp_mult": 0.0,
		"artifact_bonus_equipment_discount": 0.0,
		"equipment_bonus_skill_damage_mult": 0.0,
		"equipment_bonus_skill_proc_mult": 0.0,
	}

static func _apply_equipment_bonuses(bonuses: Dictionary, equipment_levels: Dictionary) -> void:
	var weapon_level: int = _equipment_level(equipment_levels, &"weapon")
	var helm_level: int = _equipment_level(equipment_levels, &"helm")
	var chest_level: int = _equipment_level(equipment_levels, &"chest")
	var gloves_level: int = _equipment_level(equipment_levels, &"gloves")
	var boots_level: int = _equipment_level(equipment_levels, &"boots")
	var ring_level: int = _equipment_level(equipment_levels, &"ring")
	var amulet_level: int = _equipment_level(equipment_levels, &"amulet")
	var relic_level: int = _equipment_level(equipment_levels, &"relic")

	var weapon_progress: float = EquipmentProgressRules.effective_progress(weapon_level)
	var helm_progress: float = EquipmentProgressRules.effective_progress(helm_level)
	var chest_progress: float = EquipmentProgressRules.effective_progress(chest_level)
	var gloves_progress: float = EquipmentProgressRules.effective_progress(gloves_level)
	var boots_progress: float = EquipmentProgressRules.effective_progress(boots_level)
	var ring_progress: float = EquipmentProgressRules.effective_progress(ring_level)
	var amulet_progress: float = EquipmentProgressRules.effective_progress(amulet_level)
	var relic_progress: float = EquipmentProgressRules.effective_progress(relic_level)

	var helm_100: float = floor(float(helm_level) / 100.0)
	var chest_100: float = floor(float(chest_level) / 100.0)
	var gloves_100: float = floor(float(gloves_level) / 100.0)
	var ring_100: float = floor(float(ring_level) / 100.0)
	var amulet_100: float = floor(float(amulet_level) / 100.0)
	var relic_100: float = floor(float(relic_level) / 100.0)

	bonuses["damage"] += weapon_progress * 0.18
	bonuses["max_hp"] += helm_progress * 0.48
	bonuses["defense"] += helm_progress * 0.045
	bonuses["defense"] += helm_100 * 0.42
	bonuses["max_hp"] += chest_progress * 0.85
	bonuses["defense"] += chest_progress * 0.075
	bonuses["defense"] += chest_100 * 0.62
	bonuses["attack_speed"] += gloves_progress * 0.0012 + gloves_100 * 0.006
	bonuses["evasion"] += boots_progress * 0.040
	bonuses["accuracy"] += ring_progress * 0.045
	bonuses["crit_chance"] += EquipmentProgressRules.soft_cap_progress(ring_progress * 0.000006 + ring_100 * 0.004, 0.45, 0.72)
	bonuses["damage"] += amulet_progress * 0.035
	bonuses["crit_multiplier"] += EquipmentProgressRules.soft_cap_progress(amulet_progress * 0.00035 + amulet_100 * 0.003, 2.50, 4.50)
	bonuses["accuracy"] += relic_progress * 0.030 + relic_100 * 0.20

	var weapon_1000: float = floor(float(weapon_level) / 1000.0)
	var helm_1000: float = floor(float(helm_level) / 1000.0)
	var chest_1000: float = floor(float(chest_level) / 1000.0)
	var gloves_1000: float = floor(float(gloves_level) / 1000.0)
	var boots_1000: float = floor(float(boots_level) / 1000.0)
	var ring_1000: float = floor(float(ring_level) / 1000.0)
	bonuses["damage"] += weapon_1000 * 14.0
	bonuses["max_hp"] += helm_1000 * 42.0
	bonuses["defense"] += helm_1000 * 5.0
	bonuses["max_hp"] += chest_1000 * 68.0
	bonuses["defense"] += chest_1000 * 7.0
	bonuses["attack_speed"] += gloves_1000 * 0.035
	bonuses["evasion"] += boots_1000 * 3.5
	bonuses["crit_chance"] += EquipmentProgressRules.soft_cap_progress(ring_1000 * 0.006, 0.18, 0.28)
	bonuses["equipment_bonus_skill_damage_mult"] += EquipmentProgressRules.get_amulet_skill_damage_bonus(equipment_levels)
	bonuses["equipment_bonus_skill_damage_mult"] += EquipmentProgressRules.get_relic_skill_damage_bonus(equipment_levels)
	bonuses["equipment_bonus_skill_proc_mult"] += EquipmentProgressRules.get_relic_proc_bonus(equipment_levels)

static func _apply_artifact_bonus_totals(bonuses: Dictionary, artifact_totals: Dictionary) -> void:
	for stat_variant in artifact_totals.keys():
		var stat: String = String(stat_variant)
		bonuses[stat] = float(bonuses.get(stat, 0.0)) + float(artifact_totals.get(stat, 0.0))

static func _equipment_level(equipment_levels: Dictionary, equipment_id: StringName) -> int:
	return int(equipment_levels.get(equipment_id, 0))
