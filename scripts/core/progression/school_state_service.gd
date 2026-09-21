extends RefCounted
class_name SchoolStateService

static func rebuild_state(
	school_mastery_xp: Dictionary,
	equipped_skill_ids: Array[StringName],
	highest_wave_reached: int,
	unlock_all: bool
) -> Dictionary:
	var allowed_slots: int = SchoolProgressRules.get_permanent_skill_slot_count(highest_wave_reached, unlock_all)
	return {
		"unlocked_global_skill_ids": SchoolProgressRules.rebuild_global_skill_pool(school_mastery_xp),
		"equipped_skill_ids": SchoolProgressRules.trim_equipped_skills_to_slots(equipped_skill_ids, allowed_slots),
	}

static func add_mastery_xp(
	school_mastery_xp: Dictionary,
	equipped_skill_ids: Array[StringName],
	school_id: StringName,
	value: int,
	xp_multiplier: float,
	highest_wave_reached: int,
	unlock_all: bool,
	language: StringName
) -> Dictionary:
	if not SchoolRules.SCHOOL_DEFINITIONS.has(school_id):
		return {"changed": false}
	var applied_value: int = maxi(0, int(round(float(value) * xp_multiplier)))
	if applied_value <= 0:
		return {"changed": false}

	var updated_xp: Dictionary = school_mastery_xp.duplicate(true)
	var old_core_level: int = SchoolProgressRules.get_school_core_mastery_level(school_id, updated_xp)
	var old_total_level: int = SchoolProgressRules.get_school_mastery_level(school_id, updated_xp)
	updated_xp[school_id] = SchoolProgressRules.get_school_mastery_xp(school_id, updated_xp) + applied_value
	var new_core_level: int = SchoolProgressRules.get_school_core_mastery_level(school_id, updated_xp)
	var new_total_level: int = SchoolProgressRules.get_school_mastery_level(school_id, updated_xp)
	var rebuilt: Dictionary = rebuild_state(updated_xp, equipped_skill_ids, highest_wave_reached, unlock_all)
	var report: Dictionary = {}
	if new_total_level > old_total_level:
		report = SchoolProgressRules.build_level_report(
			school_id,
			old_core_level,
			new_core_level,
			old_total_level,
			new_total_level,
			language
		)
	return {
		"changed": true,
		"level_changed": new_core_level != old_core_level or new_total_level != old_total_level,
		"school_mastery_xp": updated_xp,
		"unlocked_global_skill_ids": rebuilt.get("unlocked_global_skill_ids", []),
		"equipped_skill_ids": rebuilt.get("equipped_skill_ids", equipped_skill_ids),
		"report": report,
	}

static func set_active_school(active_school: StringName, school_id: StringName) -> Dictionary:
	if not SchoolRules.SCHOOL_DEFINITIONS.has(school_id):
		return {"changed": false, "active_school": active_school}
	return {"changed": active_school != school_id, "active_school": school_id}

static func add_mastery_xp_to_game_state(game_state: Object, school_id: StringName, value: int) -> void:
	var result: Dictionary = add_mastery_xp(
		game_state.school_mastery_xp,
		game_state.equipped_skill_ids,
		school_id,
		value,
		game_state.get_school_xp_multiplier(),
		game_state.highest_wave_reached,
		GameConstants.DEV_UNLOCK_ALL_SKILLS,
		game_state.current_language
	)
	if not bool(result.get("changed", false)):
		return
	game_state.school_mastery_xp = result.get("school_mastery_xp", game_state.school_mastery_xp)
	apply_result_to_game_state(game_state, result)
	game_state.school_mastery_changed.emit()
	if bool(result.get("level_changed", false)):
		var report: Dictionary = result.get("report", {})
		if not report.is_empty():
			game_state.school_mastery_level_reached.emit(report)

static func set_active_school_on_game_state(game_state: Object, school_id: StringName) -> void:
	var result: Dictionary = set_active_school(game_state.active_school, school_id)
	if not bool(result.get("changed", false)):
		return
	game_state.active_school = result.get("active_school", game_state.active_school)
	game_state._rebuild_school_state()

static func equip_skill_on_game_state(game_state: Object, slot_index: int, skill_id: StringName) -> bool:
	var result: Dictionary = equip_skill(
		game_state.equipped_skill_ids,
		game_state.get_available_skill_ids(),
		slot_index,
		skill_id,
		game_state.get_permanent_skill_slot_count()
	)
	return _apply_skill_slot_result(game_state, result)

static func equip_skill_to_first_open_slot_on_game_state(game_state: Object, skill_id: StringName) -> bool:
	var result: Dictionary = equip_skill_to_first_open_slot(
		game_state.equipped_skill_ids,
		game_state.get_available_skill_ids(),
		skill_id,
		game_state.get_permanent_skill_slot_count()
	)
	return _apply_skill_slot_result(game_state, result)

static func clear_skill_slot_on_game_state(game_state: Object, slot_index: int) -> bool:
	var result: Dictionary = clear_skill_slot(
		game_state.equipped_skill_ids,
		slot_index,
		game_state.get_permanent_skill_slot_count()
	)
	return _apply_skill_slot_result(game_state, result)

static func replace_skill_on_game_state(game_state: Object, slot_index: int, skill_id: StringName) -> bool:
	var result: Dictionary = replace_skill(
		game_state.equipped_skill_ids,
		game_state.get_available_skill_ids(),
		slot_index,
		skill_id,
		game_state.get_permanent_skill_slot_count()
	)
	return _apply_skill_slot_result(game_state, result)

static func rebuild_game_state_school_state(game_state: Object) -> void:
	apply_result_to_game_state(game_state, rebuild_state(
		game_state.school_mastery_xp,
		game_state.equipped_skill_ids,
		game_state.highest_wave_reached,
		GameConstants.DEV_UNLOCK_ALL_SKILLS
	))
	game_state.school_state_changed.emit()

static func apply_result_to_game_state(game_state: Object, result: Dictionary) -> void:
	if result.has("unlocked_global_skill_ids"):
		game_state.unlocked_global_skill_ids = result.get("unlocked_global_skill_ids", game_state.unlocked_global_skill_ids)
	if result.has("equipped_skill_ids"):
		game_state.equipped_skill_ids = result.get("equipped_skill_ids", game_state.equipped_skill_ids)

static func _apply_skill_slot_result(game_state: Object, result: Dictionary) -> bool:
	if not bool(result.get("success", false)):
		return false
	apply_result_to_game_state(game_state, result)
	game_state.school_state_changed.emit()
	return true

static func equip_skill(
	equipped_skill_ids: Array[StringName],
	available_skill_ids: Array[StringName],
	slot_index: int,
	skill_id: StringName,
	allowed_slots: int
) -> Dictionary:
	if not _can_place_skill(available_skill_ids, slot_index, skill_id, allowed_slots):
		return {"success": false}
	var updated: Array[StringName] = SchoolProgressRules.trim_equipped_skills_to_slots(equipped_skill_ids, allowed_slots)
	updated[slot_index] = skill_id
	return {"success": true, "equipped_skill_ids": updated}

static func equip_skill_to_first_open_slot(
	equipped_skill_ids: Array[StringName],
	available_skill_ids: Array[StringName],
	skill_id: StringName,
	allowed_slots: int
) -> Dictionary:
	var updated: Array[StringName] = SchoolProgressRules.trim_equipped_skills_to_slots(equipped_skill_ids, allowed_slots)
	for slot_index in range(allowed_slots):
		if updated[slot_index] == &"":
			return equip_skill(updated, available_skill_ids, slot_index, skill_id, allowed_slots)
	return {"success": false}

static func clear_skill_slot(equipped_skill_ids: Array[StringName], slot_index: int, allowed_slots: int) -> Dictionary:
	if slot_index < 0 or slot_index >= allowed_slots or slot_index >= equipped_skill_ids.size():
		return {"success": false}
	var updated: Array[StringName] = SchoolProgressRules.trim_equipped_skills_to_slots(equipped_skill_ids, allowed_slots)
	updated[slot_index] = &""
	return {"success": true, "equipped_skill_ids": updated}

static func replace_skill(
	equipped_skill_ids: Array[StringName],
	available_skill_ids: Array[StringName],
	slot_index: int,
	skill_id: StringName,
	allowed_slots: int
) -> Dictionary:
	return equip_skill(equipped_skill_ids, available_skill_ids, slot_index, skill_id, allowed_slots)

static func _can_place_skill(available_skill_ids: Array[StringName], slot_index: int, skill_id: StringName, allowed_slots: int) -> bool:
	if slot_index < 0 or slot_index >= allowed_slots:
		return false
	return available_skill_ids.has(skill_id)
