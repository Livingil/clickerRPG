extends RefCounted
class_name SchoolProgressRules

static func build_active_school_summary(active_school: StringName, mastery_xp: Dictionary) -> Dictionary:
	var definition: Dictionary = get_school_definition(active_school)
	var mastery_level: int = get_school_mastery_level(active_school, mastery_xp)
	var xp: int = get_school_mastery_xp(active_school, mastery_xp)
	return {
		"id": active_school,
		"name": String(definition.get("name", "Unknown")),
		"core_label": String(definition.get("core_label", "Staff")),
		"mastery_level": mastery_level,
		"mastery_xp": xp,
		"current_level_floor_xp": SchoolRules.get_current_level_floor_xp(mastery_level),
		"next_level_xp": SchoolRules.get_next_level_xp(mastery_level),
	}

static func get_school_ids() -> Array[StringName]:
	return SchoolRules.SCHOOL_ORDER.duplicate()

static func get_school_definition(school_id: StringName) -> Dictionary:
	return SchoolRules.SCHOOL_DEFINITIONS.get(school_id, {})

static func get_school_mastery_xp(school_id: StringName, mastery_xp: Dictionary) -> int:
	return int(mastery_xp.get(school_id, 0))

static func get_school_mastery_level(school_id: StringName, mastery_xp: Dictionary) -> int:
	return SchoolRules.get_total_mastery_level_from_xp(get_school_mastery_xp(school_id, mastery_xp))

static func get_school_core_mastery_level(school_id: StringName, mastery_xp: Dictionary) -> int:
	return SchoolRules.get_core_mastery_level_from_xp(get_school_mastery_xp(school_id, mastery_xp))

static func get_school_mastery_skill_bonuses(school_id: StringName, core_level: int) -> Dictionary:
	var damage_bonus: float = 0.0
	var cooldown_reduction: float = 0.0
	var proc_bonus: float = 0.0
	var unique_bonus_text: String = ""

	if core_level >= 2:
		damage_bonus += 0.04
	if core_level >= 4:
		cooldown_reduction += 0.03
	if core_level >= 6:
		proc_bonus += 0.08
	if core_level >= 7:
		cooldown_reduction += 0.05
	if core_level >= 8:
		damage_bonus += 0.10
	if core_level >= 9:
		cooldown_reduction += 0.05
	if core_level >= 10:
		match school_id:
			SchoolRules.SCHOOL_FIRE:
				proc_bonus += 0.10
				unique_bonus_text = "Усиление горения"
			SchoolRules.SCHOOL_WATER:
				proc_bonus += 0.08
				unique_bonus_text = "Усиление заморозки"
			SchoolRules.SCHOOL_EARTH:
				damage_bonus += 0.12
				unique_bonus_text = "Пробитие брони"
			SchoolRules.SCHOOL_AIR:
				cooldown_reduction += 0.08
				unique_bonus_text = "Темп воздушных навыков"
			SchoolRules.SCHOOL_LIGHTNING:
				proc_bonus += 0.12
				unique_bonus_text = "Усиление цепного разряда"

	if core_level > 10:
		var post_levels: int = core_level - 10
		var first_chunk: int = min(post_levels, 60)
		var overflow: int = max(0, post_levels - 60)
		var effective_post: float = float(first_chunk) + float(overflow) * 0.5
		damage_bonus += effective_post * 0.015
		proc_bonus += effective_post * 0.01

	return {
		"damage_bonus": damage_bonus,
		"cooldown_reduction": cooldown_reduction,
		"proc_bonus": proc_bonus,
		"unique_bonus_text": unique_bonus_text,
	}

static func build_level_report(
	school_id: StringName,
	old_core_level: int,
	new_core_level: int,
	old_total_level: int,
	new_total_level: int,
	language: StringName
) -> Dictionary:
	if new_total_level <= old_total_level:
		return {}
	var definition: Dictionary = get_school_definition(school_id)
	var unlocked_skills: Array[String] = []
	var reward_lines: Array[String] = []
	for level in range(old_core_level + 1, new_core_level + 1):
		for skill_id_variant in definition.get("skills", []):
			var skill_id: StringName = skill_id_variant as StringName
			var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
			if int(skill_data.get("unlock_level", 999)) == level:
				unlocked_skills.append(String(skill_data.get("name", skill_id)))
		var reward_text: String = get_core_level_reward_text(school_id, level, language)
		if not reward_text.is_empty():
			reward_lines.append(reward_text)
	if new_total_level > 10:
		var old_post_level: int = max(10, old_total_level)
		var gained_post_levels: int = new_total_level - old_post_level
		if gained_post_levels > 0:
			reward_lines.append(get_post_level_reward_text(gained_post_levels, language))
	return {
		"school_id": school_id,
		"school_name": String(definition.get("name", "Unknown")),
		"old_core_level": old_core_level,
		"new_core_level": new_core_level,
		"old_total_level": old_total_level,
		"new_total_level": new_total_level,
		"unlocked_skills": unlocked_skills,
		"reward_lines": reward_lines,
		"has_new_skills": not unlocked_skills.is_empty(),
	}

static func get_core_level_reward_text(school_id: StringName, level: int, language: StringName) -> String:
	var is_ru: bool = language == &"ru"
	match level:
		1:
			return "Открыт первый навык школы" if is_ru else "First school skill unlocked"
		2:
			return "+4% к урону навыков школы" if is_ru else "+4% school skill damage"
		3:
			return "Открыт второй навык школы" if is_ru else "Second school skill unlocked"
		4:
			return "-3% к перезарядке навыков школы" if is_ru else "-3% school skill cooldown"
		5:
			return "Открыт третий навык школы" if is_ru else "Third school skill unlocked"
		6:
			return "+8% к силе эффектов школы" if is_ru else "+8% school effect power"
		7:
			return "-5% к перезарядке навыков школы" if is_ru else "-5% school skill cooldown"
		8:
			return "+10% к урону навыков школы" if is_ru else "+10% school skill damage"
		9:
			return "-5% к перезарядке навыков школы" if is_ru else "-5% school skill cooldown"
		10:
			return get_unique_reward_text(school_id, language)
		_:
			return ""

static func get_unique_reward_text(school_id: StringName, language: StringName) -> String:
	var is_ru: bool = language == &"ru"
	match school_id:
		SchoolRules.SCHOOL_FIRE:
			return "Уникальный бонус: сила горения" if is_ru else "Unique bonus: burn potency"
		SchoolRules.SCHOOL_WATER:
			return "Уникальный бонус: сила замедления" if is_ru else "Unique bonus: chill potency"
		SchoolRules.SCHOOL_EARTH:
			return "Уникальный бонус: пробитие брони" if is_ru else "Unique bonus: armor break"
		SchoolRules.SCHOOL_AIR:
			return "Уникальный бонус: темп воздушных навыков" if is_ru else "Unique bonus: air skill tempo"
		SchoolRules.SCHOOL_LIGHTNING:
			return "Уникальный бонус: усиление цепного разряда" if is_ru else "Unique bonus: chain burst"
		_:
			return "Уникальный бонус школы" if is_ru else "Unique school bonus"

static func get_post_level_reward_text(levels: int, language: StringName) -> String:
	var damage_percent: float = float(levels) * 1.5
	if language == &"ru":
		return "+%d пост-ур.: +%.1f%% урон навыков, +%d%% сила эффектов" % [levels, damage_percent, levels]
	return "+%d post-lv: +%.1f%% skill damage, +%d%% effect power" % [levels, damage_percent, levels]

static func get_permanent_skill_slot_count(highest_wave: int, unlock_all: bool) -> int:
	if unlock_all:
		return 4
	return SchoolRules.get_skill_slot_count_for_highest_wave(highest_wave)

static func get_available_skill_ids(
	active_school: StringName,
	mastery_xp: Dictionary,
	unlocked_global_skill_ids: Array[StringName],
	unlock_all: bool
) -> Array[StringName]:
	var available: Array[StringName] = []
	var active_school_skills: Array = get_school_definition(active_school).get("skills", [])
	for skill_id_variant in active_school_skills:
		var skill_id: StringName = skill_id_variant as StringName
		if is_skill_unlocked_for_school(skill_id, active_school, mastery_xp, unlock_all):
			available.append(skill_id)

	for skill_id in unlocked_global_skill_ids:
		if not available.has(skill_id):
			available.append(skill_id)

	return available

static func is_skill_unlocked_for_school(skill_id: StringName, active_school: StringName, mastery_xp: Dictionary, unlock_all: bool) -> bool:
	if unlock_all:
		return true
	var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
	var unlock_level: int = int(skill_data.get("unlock_level", 999))
	return get_school_core_mastery_level(active_school, mastery_xp) >= unlock_level

static func rebuild_global_skill_pool(mastery_xp: Dictionary) -> Array[StringName]:
	var unlocked: Array[StringName] = []
	for school_id: StringName in SchoolRules.SCHOOL_ORDER:
		if get_school_core_mastery_level(school_id, mastery_xp) < 10:
			continue
		var school_skills: Array = get_school_definition(school_id).get("skills", [])
		for skill_id_variant in school_skills:
			var skill_id: StringName = skill_id_variant as StringName
			if not unlocked.has(skill_id):
				unlocked.append(skill_id)
	return unlocked

static func trim_equipped_skills_to_slots(equipped_skill_ids: Array[StringName], allowed_slots: int) -> Array[StringName]:
	var trimmed: Array[StringName] = equipped_skill_ids.duplicate()
	while trimmed.size() > allowed_slots:
		trimmed.remove_at(trimmed.size() - 1)
	while trimmed.size() < allowed_slots:
		trimmed.append(&"")
	return trimmed
