extends RefCounted
class_name EquipmentProgressRules

static func get_level(equipment_levels: Dictionary, equipment_id: StringName) -> int:
	return int(equipment_levels.get(equipment_id, 0))

static func effective_progress(level: int) -> float:
	return EquipmentRules.effective_progress(level)

static func soft_cap_progress(value: float, soft_cap: float, hard_cap: float) -> float:
	if value <= soft_cap:
		return minf(value, hard_cap)
	var overflow: float = value - soft_cap
	return minf(hard_cap, soft_cap + overflow * 0.5)

static func cap_hero_attack_speed(value: float) -> float:
	return soft_cap_progress(value, GameConstants.HERO_ATTACK_SPEED_SOFT_CAP, GameConstants.HERO_ATTACK_SPEED_HARD_CAP)

static func get_hero_move_speed(equipment_levels: Dictionary) -> float:
	var boots_tiers: float = floor(float(get_level(equipment_levels, &"boots")) / 100.0)
	var raw_speed: float = GameConstants.HERO_MOVE_SPEED + boots_tiers * GameConstants.HERO_BOOTS_MOVE_SPEED_PER_100
	return minf(GameConstants.HERO_MAX_MOVE_SPEED, raw_speed)

static func get_chest_hp_regen_percent_per_sec(equipment_levels: Dictionary) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"chest")) / 100.0)
	return soft_cap_progress(tiers * 0.00015, 0.006, 0.010)

static func get_helm_block_chance(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"helm")) / 100.0)
	return soft_cap_progress(tiers * 0.0025 + artifact_bonus, 0.20, 0.40)

static func get_chest_reflect_chance(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"chest")) / 100.0)
	return soft_cap_progress(tiers * 0.0030 + artifact_bonus, 0.25, 0.45)

static func get_gloves_reflect_ratio(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"gloves")) / 100.0)
	return soft_cap_progress(tiers * 0.0020 + artifact_bonus, 0.20, 0.35)

static func get_boots_haste_chance(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"boots")) / 100.0)
	return soft_cap_progress(tiers * 0.0025 + artifact_bonus, 0.20, 0.40)

static func get_boots_haste_duration(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"boots")) / 300.0)
	return 2.5 + tiers * 0.2 + artifact_bonus

static func get_ring_repeat_chance(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"ring")) / 100.0)
	return soft_cap_progress(tiers * 0.0013 + artifact_bonus, 0.12, 0.20)

static func get_amulet_teleport_chance(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"amulet")) / 100.0)
	return soft_cap_progress(tiers * 0.0014 + artifact_bonus, 0.10, 0.20)

static func get_amulet_skill_damage_bonus(equipment_levels: Dictionary) -> float:
	var t1000: float = floor(float(get_level(equipment_levels, &"amulet")) / 1000.0)
	return soft_cap_progress(t1000 * 0.015, 0.25, 0.45)

static func get_relic_skill_damage_bonus(equipment_levels: Dictionary) -> float:
	var level: int = get_level(equipment_levels, &"relic")
	var progress: float = effective_progress(level)
	var t1000: float = floor(float(level) / 1000.0)
	return soft_cap_progress(progress * 0.00018 + t1000 * 0.025, 0.60, 1.20)

static func get_relic_proc_bonus(equipment_levels: Dictionary) -> float:
	var t100: float = floor(float(get_level(equipment_levels, &"relic")) / 100.0)
	return soft_cap_progress(t100 * 0.0015, 0.18, 0.30)

static func get_relic_clone_chance(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"relic")) / 100.0)
	return soft_cap_progress(tiers * 0.0009 + artifact_bonus, 0.08, 0.18)

static func get_relic_clone_duration(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"relic")) / 100.0)
	return minf(10.0, 4.0 + tiers * 0.029 + artifact_bonus)

static func get_relic_clone_stat_multiplier(equipment_levels: Dictionary, artifact_bonus: float) -> float:
	var tiers: float = floor(float(get_level(equipment_levels, &"relic")) / 500.0)
	return minf(0.70, 0.40 + tiers * 0.005 + artifact_bonus)

static func roll_weapon_skill_offers(language: StringName) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	var school_ids: Array[StringName] = SchoolRules.SCHOOL_ORDER.duplicate()
	school_ids.shuffle()
	var offer_count: int = mini(3, school_ids.size())
	for i in range(offer_count):
		var school_id: StringName = school_ids[i] as StringName
		offers.append({
			"school_id": school_id,
			"text": format_weapon_school_offer_text(school_id, language),
		})
	return offers

static func format_weapon_school_offer_text(school_id: StringName, language: StringName) -> String:
	var school_name: String = get_school_display_name(school_id, language)
	if language == &"ru":
		return "%s: +1%% урон навыков, +0.5%% сила эффектов" % school_name
	return "%s: +1%% skill damage, +0.5%% effect power" % school_name

static func get_weapon_school_focus_summary(weapon_school_upgrade_levels: Dictionary, language: StringName) -> String:
	var parts: Array[String] = []
	for school_id in SchoolRules.SCHOOL_ORDER:
		var tiers: int = int(weapon_school_upgrade_levels.get(school_id, 0))
		if tiers <= 0:
			continue
		var school_name: String = get_school_display_name(school_id, language)
		parts.append("%s T%d" % [school_name, tiers])
	if parts.is_empty():
		return "нет" if language == &"ru" else "none"
	return ", ".join(parts)

static func get_school_display_name(school_id: StringName, language: StringName) -> String:
	if language != &"ru":
		return String(SchoolRules.SCHOOL_DEFINITIONS.get(school_id, {}).get("name", school_id))
	match school_id:
		SchoolRules.SCHOOL_FIRE:
			return "Огонь"
		SchoolRules.SCHOOL_WATER:
			return "Вода"
		SchoolRules.SCHOOL_EARTH:
			return "Земля"
		SchoolRules.SCHOOL_AIR:
			return "Воздух"
		SchoolRules.SCHOOL_LIGHTNING:
			return "Молния"
		_:
			return String(SchoolRules.SCHOOL_DEFINITIONS.get(school_id, {}).get("name", school_id))
