extends RefCounted
class_name InventoryProgressService

static func unlock_equipment(
	equipment_levels: Dictionary,
	equipment_unlocked: Dictionary,
	equipment_id: StringName,
	gold: int
) -> Dictionary:
	return _with_equipment_side_effects(EquipmentProgressService.unlock(equipment_levels, equipment_unlocked, equipment_id, gold), equipment_id)

static func unlock_equipment_on_game_state(game_state: Object, equipment_id: StringName) -> bool:
	var result: Dictionary = unlock_equipment(game_state.equipment_levels, game_state.equipment_unlocked, equipment_id, game_state.gold)
	if not bool(result.get("success", false)):
		return false
	apply_result_to_game_state(game_state, result, equipment_id)
	return true

static func buy_equipment_upgrade(
	equipment_levels: Dictionary,
	equipment_unlocked: Dictionary,
	equipment_id: StringName,
	gold: int,
	discount: float
) -> Dictionary:
	return _with_equipment_side_effects(EquipmentProgressService.buy_upgrade(equipment_levels, equipment_unlocked, equipment_id, gold, discount), equipment_id)

static func buy_equipment_upgrade_on_game_state(game_state: Object, equipment_id: StringName) -> bool:
	var result: Dictionary = buy_equipment_upgrade(
		game_state.equipment_levels,
		game_state.equipment_unlocked,
		equipment_id,
		game_state.gold,
		game_state.get_equipment_cost_discount()
	)
	if not bool(result.get("success", false)):
		return false
	apply_result_to_game_state(game_state, result, equipment_id)
	return true

static func buy_artifact_upgrade(
	artifact_levels: Dictionary,
	owned_artifacts: Array[StringName],
	artifact_id: StringName,
	essence: int
) -> Dictionary:
	var result: Dictionary = ArtifactProgressService.buy_upgrade(artifact_levels, owned_artifacts, artifact_id, essence)
	result["bonuses_changed"] = bool(result.get("success", false))
	return result

static func buy_artifact_upgrade_on_game_state(game_state: Object, artifact_id: StringName) -> bool:
	var result: Dictionary = buy_artifact_upgrade(game_state.artifact_levels, game_state.owned_artifacts, artifact_id, game_state.essence)
	if not bool(result.get("success", false)):
		return false
	apply_result_to_game_state(game_state, result, artifact_id)
	return true

static func register_apex_boss_kill(
	defeated_apex_wave_rewards: Array[int],
	artifact_levels: Dictionary,
	owned_artifacts: Array[StringName],
	wave_number: int,
	language: StringName
) -> Dictionary:
	if wave_number % 100 != 0 or defeated_apex_wave_rewards.has(wave_number):
		return {"success": false}
	defeated_apex_wave_rewards.append(wave_number)
	var artifact_report: Dictionary = ArtifactProgressService.grant_random_unowned(artifact_levels, owned_artifacts, language)
	var bonuses_changed: bool = not artifact_report.is_empty()
	if bonuses_changed:
		artifact_report["wave"] = wave_number
		artifact_report["event_key"] = "apex_reward_%d" % wave_number
	return {
		"success": true,
		"bonuses_changed": bonuses_changed,
		"artifact_report": artifact_report,
	}

static func register_apex_boss_kill_on_game_state(game_state: Object, wave_number: int) -> void:
	var result: Dictionary = register_apex_boss_kill(
		game_state.defeated_apex_wave_rewards,
		game_state.artifact_levels,
		game_state.owned_artifacts,
		wave_number,
		game_state.current_language
	)
	if not bool(result.get("success", false)):
		return
	if bool(result.get("bonuses_changed", false)):
		game_state._rebuild_all_bonuses()
		game_state.hero_stats_changed.emit()
	game_state.upgrades_changed.emit()
	emit_artifact_report_if_present(game_state, result)

static func apply_result_to_game_state(game_state: Object, result: Dictionary, equipment_or_artifact_id: StringName) -> void:
	game_state.gold = int(result.get("gold", game_state.gold))
	game_state.essence = int(result.get("essence", game_state.essence))
	if bool(result.get("weapon_offer_check", false)):
		game_state._try_generate_weapon_skill_offers(
			int(result.get("previous_level", game_state.get_equipment_level(equipment_or_artifact_id))),
			int(result.get("new_level", game_state.get_equipment_level(equipment_or_artifact_id)))
		)
	if bool(result.get("bonuses_changed", false)):
		game_state._rebuild_all_bonuses()
		game_state.hero_stats_changed.emit()
	game_state.resources_changed.emit(game_state.gold, game_state.essence)
	game_state.upgrades_changed.emit()

static func emit_artifact_report_if_present(game_state: Object, result: Dictionary) -> void:
	var artifact_report: Dictionary = result.get("artifact_report", {})
	if not artifact_report.is_empty():
		game_state.milestone_boss_reward_granted.emit(artifact_report)

static func build_equipment_ui_rows(
	equipment_levels: Dictionary,
	equipment_unlocked: Dictionary,
	gold: int,
	discount: float,
	language: StringName,
	hero_stats: CombatStats,
	weapon_school_upgrade_levels: Dictionary,
	artifact_proc_bonuses: Dictionary
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var context: Dictionary = EquipmentPresentationRules.build_context(
		equipment_levels,
		weapon_school_upgrade_levels,
		language,
		hero_stats,
		artifact_proc_bonuses
	)
	for equipment_id in EquipmentRules.get_ids():
		var level: int = EquipmentProgressRules.get_level(equipment_levels, equipment_id)
		var unlocked: bool = EquipmentProgressService.is_unlocked(equipment_unlocked, equipment_id)
		rows.append({
			"id": equipment_id,
			"name": EquipmentRules.get_display_name(equipment_id, language),
			"level": level,
			"unlocked": unlocked,
			"upgrade_cost": EquipmentProgressService.get_upgrade_cost(equipment_levels, equipment_id, discount),
			"unlock_cost": EquipmentRules.get_unlock_cost(equipment_id),
			"can_unlock": EquipmentProgressService.can_unlock(equipment_unlocked, equipment_id, gold),
			"base_boost_short": EquipmentPresentationRules.get_base_boost_short(equipment_id, level, context),
			"next_milestone_short": EquipmentRules.get_next_milestone_short_text(equipment_id, level, language),
			"next_level_boost": EquipmentPresentationRules.get_next_level_boost_text(equipment_id, level, language),
			"next_milestone": EquipmentRules.get_next_milestone_text(equipment_id, level, language),
			"periodic_milestones": EquipmentRules.get_periodic_milestones_text(equipment_id, language),
			"current_effect": EquipmentPresentationRules.get_current_effect_summary(equipment_id, level, context),
		})
	return rows

static func build_equipment_ui_rows_for_game_state(game_state: Object) -> Array[Dictionary]:
	return build_equipment_ui_rows(
		game_state.equipment_levels,
		game_state.equipment_unlocked,
		game_state.gold,
		game_state.get_equipment_cost_discount(),
		game_state.current_language,
		game_state.build_hero_stats(),
		game_state.weapon_school_upgrade_levels,
		EquipmentCombatProcService.build_artifact_proc_bonuses_from_game_state(game_state)
	)

static func build_artifact_ui_rows_for_game_state(game_state: Object) -> Array[Dictionary]:
	return ArtifactProgressService.build_ui_rows(
		game_state.artifact_levels,
		game_state.owned_artifacts,
		game_state.essence,
		game_state.current_language
	)

static func _with_equipment_side_effects(result: Dictionary, equipment_id: StringName) -> Dictionary:
	result["bonuses_changed"] = bool(result.get("success", false))
	result["weapon_offer_check"] = bool(result.get("success", false)) and equipment_id == &"weapon"
	return result
