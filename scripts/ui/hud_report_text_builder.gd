extends RefCounted
class_name HudReportTextBuilder

static func build_afk_reward_text(report: Dictionary, language: StringName) -> Dictionary:
	var is_ru: bool = language == &"ru"
	var capped_text: String = ""
	if bool(report.get("capped", false)):
		capped_text = "\nЛимит AFK: 8 часов." if is_ru else "\nAFK cap: 8 hours."
	return {
		"title": "Пока вас не было" if is_ru else "While You Were Away",
		"body": (
			"Время: %s%s\nВолна расчета: %d\n\n+%d Gold\n+%d Essence\n+%d Echo"
			if is_ru
			else
			"Time: %s%s\nReward wave: %d\n\n+%d Gold\n+%d Essence\n+%d Echo"
		) % [
			GameState.format_duration_short(float(report.get("capped_sec", 0))),
			capped_text,
			int(report.get("wave", 1)),
			int(report.get("gold", 0)),
			int(report.get("essence", 0)),
			int(report.get("echo", 0)),
		],
		"close": "Забрать" if is_ru else "Claim",
	}

static func build_school_level_text(report: Dictionary, language: StringName) -> Dictionary:
	var is_ru: bool = language == &"ru"
	var school_name: String = String(report.get("school_name", "School"))
	var new_total_level: int = int(report.get("new_total_level", 0))
	var title: String = (
		"%s достигла уровня %d" % [school_name, new_total_level]
		if is_ru
		else
		"%s reached level %d" % [school_name, new_total_level]
	)

	var lines: Array[String] = []
	var unlocked_skills: Array = report.get("unlocked_skills", [])
	if not unlocked_skills.is_empty():
		var unlocked_skill_names: PackedStringArray = PackedStringArray()
		for skill_name_variant in unlocked_skills:
			unlocked_skill_names.append(String(skill_name_variant))
		lines.append(
			"Новые навыки: %s" % ", ".join(unlocked_skill_names)
			if is_ru
			else
			"New skills: %s" % ", ".join(unlocked_skill_names)
		)
	var rewards: Array = report.get("reward_lines", [])
	for reward_variant in rewards:
		lines.append("- %s" % String(reward_variant))
	if bool(report.get("has_new_skills", false)):
		lines.append(
			"\nОткрой вкладку навыков и поставь новый навык в слот, иначе он не будет работать."
			if is_ru
			else
			"\nOpen the skills tab and equip the new skill into a slot, otherwise it will not work."
		)
	return {
		"title": title,
		"body": "\n".join(lines),
		"close": "Закрыть" if is_ru else "Close",
		"action": "Открыть навыки" if is_ru else "Open Skills",
	}

static func build_skill_slot_unlocked_message(report: Dictionary, language: StringName) -> Dictionary:
	var is_ru: bool = language == &"ru"
	var slot_count: int = int(report.get("slot_count", GameState.get_permanent_skill_slot_count()))
	var wave: int = int(report.get("wave", GameState.highest_wave_reached))
	return {
		"title": "Открыт слот навыка" if is_ru else "Skill Slot Unlocked",
		"body": (
			"Волна %d открыла %d-й постоянный слот навыка.\n\nОткрой вкладку навыков и поставь туда способность, иначе слот не будет усиливать героя."
			if is_ru
			else
			"Wave %d unlocked permanent skill slot %d.\n\nOpen the skills tab and equip an ability there, otherwise the slot will not empower the hero."
		) % [wave, slot_count],
		"action_text": "Открыть навыки" if is_ru else "Open Skills",
		"action": &"open_skills",
	}

static func build_prestige_unlocked_message(report: Dictionary, language: StringName) -> Dictionary:
	var is_ru: bool = language == &"ru"
	var unlock_wave: int = int(report.get("unlock_wave", GameState.get_prestige_unlock_wave()))
	var shards_now: int = int(report.get("shards_now", GameState.get_prestige_shards_for_current_run()))
	return {
		"title": "Престиж открыт" if is_ru else "Prestige Unlocked",
		"body": (
			"Ты дошел до волны %d. Теперь можно сделать престиж: сбросить текущий прогресс забега и получить shards для дерева престижа.\n\nЕсли сделать престиж сейчас: +%d shard."
			if is_ru
			else
			"You reached wave %d. Prestige is now available: reset the current run progress and gain shards for the prestige tree.\n\nPrestiging now grants: +%d shard."
		) % [unlock_wave, shards_now],
		"action_text": "Открыть престиж" if is_ru else "Open Prestige",
		"action": &"open_prestige",
	}

static func build_milestone_boss_reward_message(report: Dictionary, language: StringName) -> Dictionary:
	var is_ru: bool = language == &"ru"
	var wave: int = int(report.get("wave", 0))
	var artifact_name: String = String(report.get("artifact_name", "Artifact"))
	var artifact_level: int = int(report.get("artifact_level", 1))
	var was_new: bool = bool(report.get("was_new", false))
	var effect: String = String(report.get("effect", ""))
	var reward_template: String = "Artifact upgraded: %s Lv.%d"
	if is_ru:
		reward_template = "Найден новый артефакт: %s Ур.%d" if was_new else "Артефакт усилен: %s Ур.%d"
	elif was_new:
		reward_template = "New artifact found: %s Lv.%d"
	var reward_line: String = reward_template % [artifact_name, artifact_level]
	return {
		"title": "Награда за босса" if is_ru else "Boss Reward",
		"body": (
			"Испытание волны %d пройдено.\n%s\n\n%s"
			if is_ru
			else
			"Wave %d challenge completed.\n%s\n\n%s"
		) % [wave, reward_line, effect],
		"action_text": "Открыть артефакты" if is_ru else "Open Artifacts",
		"action": &"open_artifacts",
	}

static func build_run_death_report_text(report: Dictionary, language: StringName) -> Dictionary:
	var is_ru: bool = language == &"ru"
	var lines: Array[String] = []
	lines.append(("Забег: %s" if is_ru else "Run: %s") % [
		GameState.format_duration_short(float(report.get("run_time_sec", 0.0))),
	])
	lines.append(("Собрано Echo: +%d" if is_ru else "Echo collected: +%d") % int(report.get("collected_echo", 0)))
	lines.append(("Active Echo: %d -> %d" if is_ru else "Active Echo: %d -> %d") % [
		int(report.get("echo_before", 0)),
		int(report.get("echo_after", 0)),
	])
	var remaining_to_next: int = int(report.get("remaining_to_next_echo_bonus", 0))
	var next_echo_at: int = int(report.get("next_echo_bonus_at", int(report.get("echo_after", 0))))
	if remaining_to_next > 0:
		lines.append(("До следующего Echo-бонуса: %d (на %d)" if is_ru else "To next Echo bonus: %d (at %d)") % [remaining_to_next, next_echo_at])
	lines.append("")
	lines.append_array(_build_death_echo_bonus_snapshot(report, is_ru))
	return {
		"title": "После смерти" if is_ru else "After Death",
		"body": "\n".join(lines),
		"close": "Закрыть" if is_ru else "Close",
	}

static func build_prestige_report_text(report: Dictionary, language: StringName) -> Dictionary:
	var is_ru: bool = language == &"ru"
	var milestone_lines: Array = report.get("milestones", [])
	var milestone_text: String = ""
	if not milestone_lines.is_empty():
		var packed: PackedStringArray = PackedStringArray()
		for line in milestone_lines:
			packed.append(String(line))
		milestone_text = "\n" + "\n".join(packed)
	return {
		"title": "Престиж выполнен" if is_ru else "Prestige Complete",
		"body": (
			"Получено shards: +%d\nДоступно shards: %d\nПрестижей: %d\nXP школ: x%.2f -> x%.2f%s"
			if is_ru
			else
			"Shards gained: +%d\nAvailable shards: %d\nPrestiges: %d\nSchool XP: x%.2f -> x%.2f%s"
		) % [
			int(report.get("gained_shards", 0)),
			int(report.get("available_shards_after", 0)),
			int(report.get("prestige_count", 0)),
			float(report.get("school_xp_multiplier_before", 1.0)),
			float(report.get("school_xp_multiplier_after", 1.0)),
			milestone_text,
		],
		"close": "Закрыть" if is_ru else "Close",
	}

static func _build_death_echo_bonus_snapshot(report: Dictionary, is_ru: bool) -> Array[String]:
	var echo_before: int = int(report.get("echo_before", 0))
	var echo_after: int = int(report.get("echo_after", 0))
	var before_bonuses: Dictionary = GameState.get_echo_tier_bonuses(echo_before)
	var after_bonuses: Dictionary = GameState.get_echo_tier_bonuses(echo_after)
	return [
		"До смерти" if is_ru else "Before Death",
		_build_echo_bonus_row(before_bonuses, {}, ["HP", "DMG", "ATK", "DEF"], false),
		_build_echo_bonus_row(before_bonuses, {}, ["EVA", "ACC", "CRIT", "CRITx"], false),
		"",
		"После смерти" if is_ru else "After Death",
		_build_echo_bonus_row(after_bonuses, before_bonuses, ["HP", "DMG", "ATK", "DEF"], true),
		_build_echo_bonus_row(after_bonuses, before_bonuses, ["EVA", "ACC", "CRIT", "CRITx"], true),
	]

static func _build_echo_bonus_row(bonuses: Dictionary, before_bonuses: Dictionary, stat_ids: Array, show_delta: bool) -> String:
	var parts: Array[String] = []
	for stat_id_variant in stat_ids:
		var stat_id: String = String(stat_id_variant)
		parts.append(_format_echo_bonus_cell(stat_id, bonuses, before_bonuses, show_delta))
	return "   ".join(parts)

static func _format_echo_bonus_cell(stat_id: String, bonuses: Dictionary, before_bonuses: Dictionary, show_delta: bool) -> String:
	var key: String = _get_echo_bonus_key(stat_id)
	var value: float = _get_echo_bonus_display_value(stat_id, float(bonuses.get(key, 0.0)))
	var before_value: float = _get_echo_bonus_display_value(stat_id, float(before_bonuses.get(key, 0.0)))
	var cell: String = "%s +%s" % [stat_id, _format_echo_bonus_value(stat_id, value)]
	if show_delta:
		var delta: float = value - before_value
		if delta > 0.0001:
			cell += " [color=#74e06f](+%s)[/color]" % _format_echo_bonus_value(stat_id, delta)
	return cell

static func _get_echo_bonus_key(stat_id: String) -> String:
	match stat_id:
		"HP":
			return "max_hp"
		"DMG":
			return "damage"
		"ATK":
			return "attack_speed"
		"DEF":
			return "defense"
		"EVA":
			return "evasion"
		"ACC":
			return "accuracy"
		"CRIT":
			return "crit_chance"
		"CRITx":
			return "crit_multiplier"
	return ""

static func _get_echo_bonus_display_value(stat_id: String, raw_value: float) -> float:
	if stat_id == "CRIT":
		return raw_value * 100.0
	return raw_value

static func _format_echo_bonus_value(stat_id: String, value: float) -> String:
	match stat_id:
		"HP":
			return "%.0f" % value
		"DMG", "DEF", "EVA", "ACC":
			return "%.1f" % value
		"ATK", "CRIT", "CRITx":
			return "%.2f" % value
	return "%.1f" % value
