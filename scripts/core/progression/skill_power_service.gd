extends RefCounted
class_name SkillPowerService

static func get_damage_multiplier(
	skill_id: StringName,
	equipment_levels: Dictionary,
	school_mastery_xp: Dictionary,
	weapon_school_upgrade_levels: Dictionary,
	equipment_bonus_skill_damage_mult: float,
	artifact_bonus_skill_damage_mult: float
) -> float:
	var weapon_level: int = EquipmentProgressRules.get_level(equipment_levels, &"weapon")
	var milestone_1000: float = floor(float(weapon_level) / 1000.0)
	var skill_school: StringName = _get_skill_school(skill_id)
	var school_bonus: Dictionary = _get_school_mastery_skill_bonuses(skill_school, school_mastery_xp)
	var weapon_school_tiers: int = int(weapon_school_upgrade_levels.get(skill_school, 0))
	var weapon_global_bonus: float = EquipmentProgressRules.soft_cap_progress(milestone_1000 * 0.03, 0.45, 0.90)
	var school_focus_bonus: float = EquipmentProgressRules.soft_cap_progress(float(weapon_school_tiers) * 0.01, 0.50, 1.00)
	var base_mult: float = 1.0 + weapon_global_bonus + school_focus_bonus + equipment_bonus_skill_damage_mult + artifact_bonus_skill_damage_mult
	return base_mult * (1.0 + float(school_bonus.get("damage_bonus", 0.0)))

static func get_damage_multiplier_for_game_state(game_state: Object, skill_id: StringName) -> float:
	return get_damage_multiplier(
		skill_id,
		game_state.equipment_levels,
		game_state.school_mastery_xp,
		game_state.weapon_school_upgrade_levels,
		game_state.get_bonus_total("equipment_bonus_skill_damage_mult"),
		game_state.get_bonus_total("artifact_bonus_skill_damage_mult")
	)

static func get_cooldown_multiplier(skill_id: StringName, equipment_levels: Dictionary, school_mastery_xp: Dictionary) -> float:
	var weapon_level: int = EquipmentProgressRules.get_level(equipment_levels, &"weapon")
	var milestone_1000: float = floor(float(weapon_level) / 1000.0)
	var skill_school: StringName = _get_skill_school(skill_id)
	var school_bonus: Dictionary = _get_school_mastery_skill_bonuses(skill_school, school_mastery_xp)
	var weapon_cd_reduction: float = EquipmentProgressRules.soft_cap_progress(milestone_1000 * 0.01, 0.25, 0.45)
	var base_cd: float = 1.0 - weapon_cd_reduction
	var school_reduction: float = clampf(float(school_bonus.get("cooldown_reduction", 0.0)), 0.0, 0.35)
	return maxf(0.35, base_cd * (1.0 - school_reduction))

static func get_cooldown_multiplier_for_game_state(game_state: Object, skill_id: StringName) -> float:
	return get_cooldown_multiplier(skill_id, game_state.equipment_levels, game_state.school_mastery_xp)

static func get_proc_multiplier(
	skill_id: StringName,
	school_mastery_xp: Dictionary,
	weapon_school_upgrade_levels: Dictionary,
	equipment_bonus_skill_proc_mult: float,
	artifact_bonus_skill_proc_mult: float
) -> float:
	var skill_school: StringName = _get_skill_school(skill_id)
	var school_bonus: Dictionary = _get_school_mastery_skill_bonuses(skill_school, school_mastery_xp)
	var weapon_school_tiers: int = int(weapon_school_upgrade_levels.get(skill_school, 0))
	var school_focus_proc: float = EquipmentProgressRules.soft_cap_progress(float(weapon_school_tiers) * 0.005, 0.25, 0.50)
	var base_proc: float = 1.0 + school_focus_proc + equipment_bonus_skill_proc_mult + artifact_bonus_skill_proc_mult
	return base_proc * (1.0 + float(school_bonus.get("proc_bonus", 0.0)))

static func get_proc_multiplier_for_game_state(game_state: Object, skill_id: StringName) -> float:
	return get_proc_multiplier(
		skill_id,
		game_state.school_mastery_xp,
		game_state.weapon_school_upgrade_levels,
		game_state.get_bonus_total("equipment_bonus_skill_proc_mult"),
		game_state.get_bonus_total("artifact_bonus_skill_proc_mult")
	)

static func maybe_roll_weapon_skill_offers(
	pending_weapon_skill_offers: Array[Dictionary],
	previous_level: int,
	new_level: int,
	language: StringName
) -> Array[Dictionary]:
	var previous_milestone: int = int(floor(float(previous_level) / 100.0))
	var new_milestone: int = int(floor(float(new_level) / 100.0))
	if new_milestone <= previous_milestone or not pending_weapon_skill_offers.is_empty():
		return pending_weapon_skill_offers.duplicate(true)
	return EquipmentProgressRules.roll_weapon_skill_offers(language)

static func apply_weapon_skill_offer(
	pending_weapon_skill_offers: Array[Dictionary],
	weapon_school_upgrade_levels: Dictionary,
	offer_index: int
) -> Dictionary:
	if offer_index < 0 or offer_index >= pending_weapon_skill_offers.size():
		return {"success": false}
	var offer: Dictionary = pending_weapon_skill_offers[offer_index]
	var school_id: StringName = offer.get("school_id", &"") as StringName
	if school_id == &"" or not SchoolRules.SCHOOL_DEFINITIONS.has(school_id):
		return {"success": false}
	var updated_levels: Dictionary = weapon_school_upgrade_levels.duplicate(true)
	updated_levels[school_id] = int(updated_levels.get(school_id, 0)) + 1
	return {
		"success": true,
		"weapon_school_upgrade_levels": updated_levels,
		"pending_weapon_skill_offers": [],
		"school_id": school_id,
	}

static func apply_weapon_skill_offer_on_game_state(game_state: Object, offer_index: int) -> bool:
	var result: Dictionary = apply_weapon_skill_offer(
		game_state.pending_weapon_skill_offers,
		game_state.weapon_school_upgrade_levels,
		offer_index
	)
	if not bool(result.get("success", false)):
		return false
	game_state.weapon_school_upgrade_levels = result.get("weapon_school_upgrade_levels", game_state.weapon_school_upgrade_levels)
	game_state.pending_weapon_skill_offers = result.get("pending_weapon_skill_offers", [])
	game_state._rebuild_all_bonuses()
	game_state.hero_stats_changed.emit()
	game_state.upgrades_changed.emit()
	return true

static func _get_skill_school(skill_id: StringName) -> StringName:
	if SchoolRules.SKILL_DEFINITIONS.has(skill_id):
		return SchoolRules.SKILL_DEFINITIONS[skill_id].get("school", SchoolRules.SCHOOL_FIRE) as StringName
	return SchoolRules.SCHOOL_FIRE

static func _get_school_mastery_skill_bonuses(school_id: StringName, school_mastery_xp: Dictionary) -> Dictionary:
	var level: int = SchoolProgressRules.get_school_core_mastery_level(school_id, school_mastery_xp)
	return SchoolProgressRules.get_school_mastery_skill_bonuses(school_id, level)
