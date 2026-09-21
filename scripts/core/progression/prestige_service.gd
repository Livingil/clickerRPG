extends RefCounted
class_name PrestigeService

static func build_preview_report(
	highest_wave_reached: int,
	prestige_count: int,
	prestige_shards: int,
	prestige_shards_earned_total: int,
	current_school_xp_multiplier: float,
	language: StringName
) -> Dictionary:
	var gained_shards: int = PrestigeRules.get_shards_for_wave(highest_wave_reached)
	return {
		"gained_shards": gained_shards,
		"wave": highest_wave_reached,
		"prestige_count_before": prestige_count,
		"available_shards_before": prestige_shards,
		"earned_total_before": prestige_shards_earned_total,
		"school_xp_multiplier_before": current_school_xp_multiplier,
		"school_xp_multiplier_after": PrestigeRules.get_school_xp_multiplier_for_total_shards(prestige_shards_earned_total + gained_shards),
		"milestones": PrestigeRules.get_new_milestone_lines(prestige_count + 1, language),
	}

static func apply_prestige(
	report: Dictionary,
	prestige_count: int,
	prestige_shards: int,
	prestige_shards_earned_total: int,
	school_xp_multiplier_after: float
) -> Dictionary:
	var gained_shards: int = int(report.get("gained_shards", 0))
	var next_count: int = prestige_count + 1
	var next_shards: int = prestige_shards + gained_shards
	var next_earned_total: int = prestige_shards_earned_total + gained_shards
	var next_report: Dictionary = report.duplicate(true)
	next_report["prestige_count"] = next_count
	next_report["available_shards_after"] = next_shards
	next_report["school_xp_multiplier_after"] = school_xp_multiplier_after
	return {
		"prestige_count": next_count,
		"prestige_shards": next_shards,
		"prestige_shards_earned_total": next_earned_total,
		"report": next_report,
	}

static func perform_prestige_on_game_state(game_state: Object) -> bool:
	if not PrestigeRules.can_perform(game_state.highest_wave_reached):
		return false
	var preview_report: Dictionary = game_state.build_prestige_preview_report()
	var gained_shards: int = int(preview_report.get("gained_shards", 0))
	var result: Dictionary = apply_prestige(
		preview_report,
		game_state.prestige_count,
		game_state.prestige_shards,
		game_state.prestige_shards_earned_total,
		get_school_xp_multiplier(
			game_state.prestige_upgrade_levels,
			game_state.prestige_shards_earned_total + gained_shards,
			game_state.get_bonus_total("artifact_bonus_school_xp_mult")
		)
	)
	game_state.prestige_count = int(result.get("prestige_count", game_state.prestige_count))
	game_state.prestige_shards = int(result.get("prestige_shards", game_state.prestige_shards))
	game_state.prestige_shards_earned_total = int(result.get("prestige_shards_earned_total", game_state.prestige_shards_earned_total))
	game_state.last_prestige_report = (result.get("report", {}) as Dictionary).duplicate(true)
	game_state._reset_run_progress()
	game_state._apply_upgrade_bonuses()
	game_state._emit_full_progress_refresh()
	game_state.prestige_performed.emit()
	game_state.prestige_report_ready.emit(game_state.get_last_prestige_report())
	return true

static func get_upgrade_level(prestige_upgrade_levels: Dictionary, upgrade_id: StringName) -> int:
	return int(prestige_upgrade_levels.get(upgrade_id, 0))

static func get_upgrade_cost(prestige_upgrade_levels: Dictionary, upgrade_id: StringName) -> int:
	return PrestigeRules.get_upgrade_cost(upgrade_id, get_upgrade_level(prestige_upgrade_levels, upgrade_id))

static func can_buy_upgrade(prestige_upgrade_levels: Dictionary, upgrade_id: StringName, prestige_shards: int) -> bool:
	var cost: int = get_upgrade_cost(prestige_upgrade_levels, upgrade_id)
	return cost > 0 and prestige_shards >= cost

static func buy_upgrade(prestige_upgrade_levels: Dictionary, upgrade_id: StringName, prestige_shards: int) -> Dictionary:
	if not PrestigeRules.has_upgrade(upgrade_id):
		return {"success": false, "prestige_shards": prestige_shards}
	var cost: int = get_upgrade_cost(prestige_upgrade_levels, upgrade_id)
	if cost <= 0 or prestige_shards < cost:
		return {"success": false, "prestige_shards": prestige_shards}
	prestige_upgrade_levels[upgrade_id] = get_upgrade_level(prestige_upgrade_levels, upgrade_id) + 1
	return {
		"success": true,
		"prestige_shards": prestige_shards - cost,
	}

static func build_panel_data(
	preview: Dictionary,
	prestige_upgrade_levels: Dictionary,
	prestige_shards: int,
	prestige_shards_earned_total: int,
	prestige_count: int,
	can_prestige: bool,
	unlock_text: String,
	language: StringName
) -> Dictionary:
	var rows: Array[Dictionary] = []
	for upgrade_id in PrestigeRules.get_upgrade_ids():
		var cost: int = get_upgrade_cost(prestige_upgrade_levels, upgrade_id)
		rows.append({
			"id": upgrade_id,
			"name": PrestigeRules.get_upgrade_display_name(upgrade_id, language),
			"description": PrestigeRules.get_upgrade_description(upgrade_id, language),
			"level": get_upgrade_level(prestige_upgrade_levels, upgrade_id),
			"cost": cost,
			"can_buy": can_buy_upgrade(prestige_upgrade_levels, upgrade_id, prestige_shards),
			"maxed": cost <= 0,
		})
	return {
		"preview": preview,
		"can_prestige": can_prestige,
		"unlock_text": unlock_text,
		"available_shards": prestige_shards,
		"earned_total": prestige_shards_earned_total,
		"prestige_count": prestige_count,
		"upgrade_rows": rows,
	}

static func get_attack_multiplier(prestige_upgrade_levels: Dictionary) -> float:
	return PrestigeRules.get_stat_multiplier(PrestigeRules.ATTACK, get_upgrade_level(prestige_upgrade_levels, PrestigeRules.ATTACK))

static func get_hp_multiplier(prestige_upgrade_levels: Dictionary) -> float:
	return PrestigeRules.get_stat_multiplier(PrestigeRules.HP, get_upgrade_level(prestige_upgrade_levels, PrestigeRules.HP))

static func get_defense_multiplier(prestige_upgrade_levels: Dictionary) -> float:
	return PrestigeRules.get_stat_multiplier(PrestigeRules.DEFENSE, get_upgrade_level(prestige_upgrade_levels, PrestigeRules.DEFENSE))

static func get_crit_chance_bonus(prestige_upgrade_levels: Dictionary) -> float:
	return PrestigeRules.get_crit_chance_bonus(get_upgrade_level(prestige_upgrade_levels, PrestigeRules.CRIT))

static func get_crit_multiplier_bonus(prestige_upgrade_levels: Dictionary) -> float:
	return PrestigeRules.get_crit_multiplier_bonus(get_upgrade_level(prestige_upgrade_levels, PrestigeRules.CRIT))

static func get_school_xp_multiplier(
	prestige_upgrade_levels: Dictionary,
	prestige_shards_earned_total: int,
	artifact_bonus: float
) -> float:
	var branch_bonus: float = PrestigeRules.get_stat_multiplier(PrestigeRules.SCHOOL_XP, get_upgrade_level(prestige_upgrade_levels, PrestigeRules.SCHOOL_XP)) - 1.0
	return PrestigeRules.get_school_xp_multiplier_for_total_shards(prestige_shards_earned_total) + branch_bonus + artifact_bonus

static func get_gold_multiplier(prestige_upgrade_levels: Dictionary, artifact_bonus: float) -> float:
	return PrestigeRules.get_stat_multiplier(PrestigeRules.GOLD, get_upgrade_level(prestige_upgrade_levels, PrestigeRules.GOLD)) + artifact_bonus

static func get_equipment_cost_discount(prestige_upgrade_levels: Dictionary, artifact_bonus: float) -> float:
	return PrestigeRules.get_equipment_cost_discount(get_upgrade_level(prestige_upgrade_levels, PrestigeRules.CRAFT)) + artifact_bonus
