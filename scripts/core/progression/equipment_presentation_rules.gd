extends RefCounted
class_name EquipmentPresentationRules

static func build_context(
	equipment_levels: Dictionary,
	weapon_school_upgrade_levels: Dictionary,
	language: StringName,
	hero_stats: CombatStats,
	artifact_bonuses: Dictionary
) -> Dictionary:
	return {
		"language": language,
		"focus": EquipmentProgressRules.get_weapon_school_focus_summary(weapon_school_upgrade_levels, language),
		"attack_speed": hero_stats.attack_speed,
		"crit_multiplier": hero_stats.crit_multiplier,
		"move_speed": EquipmentProgressRules.get_hero_move_speed(equipment_levels),
		"block": EquipmentProgressRules.get_helm_block_chance(equipment_levels, float(artifact_bonuses.get("block", 0.0))),
		"chest_reflect": EquipmentProgressRules.get_chest_reflect_chance(equipment_levels, float(artifact_bonuses.get("reflect_chance", 0.0))),
		"hp_regen": EquipmentProgressRules.get_chest_hp_regen_percent_per_sec(equipment_levels),
		"gloves_reflect": EquipmentProgressRules.get_gloves_reflect_ratio(equipment_levels, float(artifact_bonuses.get("reflect_ratio", 0.0))),
		"boots_haste": EquipmentProgressRules.get_boots_haste_chance(equipment_levels, float(artifact_bonuses.get("haste_chance", 0.0))),
		"boots_haste_duration": EquipmentProgressRules.get_boots_haste_duration(equipment_levels, float(artifact_bonuses.get("haste_duration", 0.0))),
		"ring_repeat": EquipmentProgressRules.get_ring_repeat_chance(equipment_levels, float(artifact_bonuses.get("repeat_chance", 0.0))),
		"amulet_teleport": EquipmentProgressRules.get_amulet_teleport_chance(equipment_levels, float(artifact_bonuses.get("teleport_chance", 0.0))),
		"amulet_skill": EquipmentProgressRules.get_amulet_skill_damage_bonus(equipment_levels),
		"relic_skill": EquipmentProgressRules.get_relic_skill_damage_bonus(equipment_levels),
		"relic_proc": EquipmentProgressRules.get_relic_proc_bonus(equipment_levels),
		"relic_clone": EquipmentProgressRules.get_relic_clone_chance(equipment_levels, float(artifact_bonuses.get("clone_chance", 0.0))),
		"relic_clone_duration": EquipmentProgressRules.get_relic_clone_duration(equipment_levels, float(artifact_bonuses.get("clone_duration", 0.0))),
		"relic_clone_stats": EquipmentProgressRules.get_relic_clone_stat_multiplier(equipment_levels, float(artifact_bonuses.get("clone_stats", 0.0))),
	}

static func get_effect_summary(equipment_id: StringName, level: int, context: Dictionary) -> String:
	var is_ru: bool = _is_ru(context)
	var t1000: int = int(floor(float(level) / 1000.0))
	match equipment_id:
		&"weapon":
			var skill_bonus_pct: float = EquipmentProgressRules.soft_cap_progress(t1000 * 0.03, 0.45, 0.90) * 100.0
			var cooldown_reduction_pct: float = EquipmentProgressRules.soft_cap_progress(t1000 * 0.01, 0.25, 0.45) * 100.0
			if is_ru:
				return "Каждые 100 ур: выбор 1 из 3 школ. Каждый выбор школы: +1%% урон навыков, +0.5%% сила эффектов. Вехи 1000 ур: +%.0f%% общий урон навыков, -%.0f%% КД. Фокус: %s." % [skill_bonus_pct, cooldown_reduction_pct, _focus(context)]
			return "Every 100 lv: pick 1 of 3 schools. Each school pick: +1%% skill damage, +0.5%% effect power. 1000 lv milestones: +%.0f%% global skill damage, -%.0f%% cooldown. Focus: %s." % [skill_bonus_pct, cooldown_reduction_pct, _focus(context)]
		&"helm":
			return ("Базово: HP и защита. Блок урона: %.2f%%." % _pct(context, "block")) if is_ru else ("Base: HP and defense. Block chance: %.2f%%." % _pct(context, "block"))
		&"chest":
			return ("Базово: HP и защита. Шанс отражения: %.2f%%. Регенерация HP: %.3f%%/с." % [_pct(context, "chest_reflect"), _pct(context, "hp_regen")]) if is_ru else ("Base: HP and defense. Reflect chance: %.2f%%. HP regeneration: %.3f%%/s." % [_pct(context, "chest_reflect"), _pct(context, "hp_regen")])
		&"gloves":
			return ("Базово: скорость атаки. Сила отражения: %.2f%% входящего урона." % _pct(context, "gloves_reflect")) if is_ru else ("Base: attack speed. Reflect power: %.2f%% of incoming damage." % _pct(context, "gloves_reflect"))
		&"boots":
			return ("Базово: уклонение. Скорость движения: %.0f. После получения урона: %.2f%% шанс ускорения x1.5 на %.1fс." % [float(context.get("move_speed", 0.0)), _pct(context, "boots_haste"), float(context.get("boots_haste_duration", 0.0))]) if is_ru else ("Base: evasion. Move speed: %.0f. On hit taken: %.2f%% chance for x1.5 haste for %.1fs." % [float(context.get("move_speed", 0.0)), _pct(context, "boots_haste"), float(context.get("boots_haste_duration", 0.0))])
		&"ring":
			return ("Базово: точность и крит-шанс. Двойное срабатывание атаки/навыка: %.2f%%." % _pct(context, "ring_repeat")) if is_ru else ("Base: accuracy and crit chance. Double attack/skill trigger: %.2f%%." % _pct(context, "ring_repeat"))
		&"amulet":
			return ("Базово: крит-множитель, немного урона и +%.0f%% урон навыков. Телепорт при получении урона: %.2f%%." % [_pct(context, "amulet_skill"), _pct(context, "amulet_teleport")]) if is_ru else ("Base: crit multiplier, minor damage and +%.0f%% skill damage. Teleport on hit taken: %.2f%%." % [_pct(context, "amulet_skill"), _pct(context, "amulet_teleport")])
		&"relic":
			return ("Базово: точность, +%.0f%% урон навыков, +%.1f%% сила эффектов. Шанс клона: %.2f%%, длительность %.1fс, сила %.0f%% статов." % [_pct(context, "relic_skill"), _pct(context, "relic_proc"), _pct(context, "relic_clone"), float(context.get("relic_clone_duration", 0.0)), _pct(context, "relic_clone_stats")]) if is_ru else ("Base: accuracy, +%.0f%% skill damage, +%.1f%% effect power. Clone chance %.2f%%, duration %.1fs, power %.0f%% stats." % [_pct(context, "relic_skill"), _pct(context, "relic_proc"), _pct(context, "relic_clone"), float(context.get("relic_clone_duration", 0.0)), _pct(context, "relic_clone_stats")])
		_:
			return "Нет описания." if is_ru else "No description."

static func get_current_boost_short(equipment_id: StringName, level: int, context: Dictionary) -> String:
	var t100: int = int(floor(float(level) / 100.0))
	var t1000: int = int(floor(float(level) / 1000.0))
	match equipment_id:
		&"weapon":
			return "SKILL +%.0f%% | CD -%.0f%%" % [
				EquipmentProgressRules.soft_cap_progress(t1000 * 0.03, 0.45, 0.90) * 100.0,
				EquipmentProgressRules.soft_cap_progress(t1000 * 0.01, 0.25, 0.45) * 100.0,
			]
		&"helm":
			return "BLOCK %.2f%%" % _pct(context, "block")
		&"chest":
			return "REFLECT %.2f%% | REGEN %.3f%%/s" % [_pct(context, "chest_reflect"), _pct(context, "hp_regen")]
		&"gloves":
			return "ATK %.2f | REFLECT %.2f%%" % [float(context.get("attack_speed", 0.0)), _pct(context, "gloves_reflect")]
		&"boots":
			return "MOVE %.0f | HASTE %.2f%%" % [float(context.get("move_speed", 0.0)), _pct(context, "boots_haste")]
		&"ring":
			return "DOUBLE %.2f%%" % _pct(context, "ring_repeat")
		&"amulet":
			return "CRITx %.2f | TP %.2f%%" % [float(context.get("crit_multiplier", 1.0)), _pct(context, "amulet_teleport")]
		&"relic":
			return "SKILL +%.0f%% | CLONE %.2f%%" % [_pct(context, "relic_skill"), _pct(context, "relic_clone")]
		_:
			return "T%d" % t100

static func get_base_boost_short(equipment_id: StringName, level: int, context: Dictionary) -> String:
	var progress: float = EquipmentProgressRules.effective_progress(level)
	var is_ru: bool = _is_ru(context)
	match equipment_id:
		&"weapon":
			var damage: float = progress * 0.18 + floor(float(level) / 1000.0) * 14.0
			return ("База: +%.1f урона" % damage) if is_ru else ("Base: +%.1f damage" % damage)
		&"helm":
			return _base_hp_def_text(progress * 0.48 + floor(float(level) / 1000.0) * 42.0, progress * 0.045 + floor(float(level) / 100.0) * 0.42 + floor(float(level) / 1000.0) * 5.0, is_ru)
		&"chest":
			return _base_hp_def_text(progress * 0.85 + floor(float(level) / 1000.0) * 68.0, progress * 0.075 + floor(float(level) / 100.0) * 0.62 + floor(float(level) / 1000.0) * 7.0, is_ru)
		&"gloves":
			var atk_bonus: float = progress * 0.0012 + floor(float(level) / 100.0) * 0.006 + floor(float(level) / 1000.0) * 0.035
			return ("База: +%.2f ATK/s" % atk_bonus) if is_ru else ("Base: +%.2f ATK/s" % atk_bonus)
		&"boots":
			var eva_bonus: float = progress * 0.040 + floor(float(level) / 1000.0) * 3.5
			var speed_bonus: float = floor(float(level) / 100.0) * GameConstants.HERO_BOOTS_MOVE_SPEED_PER_100
			return ("База: +%.1f EVA, +%.0f MOVE" % [eva_bonus, speed_bonus]) if is_ru else ("Base: +%.1f EVA, +%.0f MOVE" % [eva_bonus, speed_bonus])
		&"ring":
			var crit_bonus: float = (
				EquipmentProgressRules.soft_cap_progress(progress * 0.000006 + floor(float(level) / 100.0) * 0.004, 0.45, 0.72)
				+ EquipmentProgressRules.soft_cap_progress(floor(float(level) / 1000.0) * 0.006, 0.18, 0.28)
			) * 100.0
			return ("База: +%.1f ACC, +%.2f%% CRIT" % [progress * 0.045, crit_bonus]) if is_ru else ("Base: +%.1f ACC, +%.2f%% CRIT" % [progress * 0.045, crit_bonus])
		&"amulet":
			var critx_bonus: float = EquipmentProgressRules.soft_cap_progress(progress * 0.00035 + floor(float(level) / 100.0) * 0.003, 2.50, 4.50)
			return ("База: +%.1f DMG, +%.2f CRITx, +%.0f%% навык" % [progress * 0.035, critx_bonus, _pct(context, "amulet_skill")]) if is_ru else ("Base: +%.1f DMG, +%.2f CRITx, +%.0f%% skill" % [progress * 0.035, critx_bonus, _pct(context, "amulet_skill")])
		&"relic":
			var acc_bonus: float = progress * 0.030 + floor(float(level) / 100.0) * 0.20
			return ("База: +%.1f ACC, +%.0f%% навык, +%.1f%% эффекты" % [acc_bonus, _pct(context, "relic_skill"), _pct(context, "relic_proc")]) if is_ru else ("Base: +%.1f ACC, +%.0f%% skill, +%.1f%% effects" % [acc_bonus, _pct(context, "relic_skill"), _pct(context, "relic_proc")])
		_:
			return ""

static func get_proc_boost_short(equipment_id: StringName, level: int, context: Dictionary) -> String:
	var is_ru: bool = _is_ru(context)
	match equipment_id:
		&"weapon":
			var t1000: int = int(floor(float(level) / 1000.0))
			var skill_bonus_pct: float = EquipmentProgressRules.soft_cap_progress(t1000 * 0.03, 0.45, 0.90) * 100.0
			var cooldown_reduction_pct: float = EquipmentProgressRules.soft_cap_progress(t1000 * 0.01, 0.25, 0.45) * 100.0
			return ("Перк: школы %s | +%.0f%% навык, -%.0f%% КД" % [_focus(context), skill_bonus_pct, cooldown_reduction_pct]) if is_ru else ("Perk: schools %s | +%.0f%% skill, -%.0f%% cd" % [_focus(context), skill_bonus_pct, cooldown_reduction_pct])
		&"helm":
			return ("Перк: +%.2f%% блок" % _pct(context, "block")) if is_ru else ("Perk: +%.2f%% block" % _pct(context, "block"))
		&"chest":
			return ("Перк: +%.2f%% отраж., %.3f%%/с реген" % [_pct(context, "chest_reflect"), _pct(context, "hp_regen")]) if is_ru else ("Perk: +%.2f%% reflect, %.3f%%/s regen" % [_pct(context, "chest_reflect"), _pct(context, "hp_regen")])
		&"gloves":
			return ("Перк: +%.2f%% сила отраж." % _pct(context, "gloves_reflect")) if is_ru else ("Perk: +%.2f%% reflect power" % _pct(context, "gloves_reflect"))
		&"boots":
			return ("Перк: %.0f MOVE, +%.2f%% ускорение" % [float(context.get("move_speed", 0.0)), _pct(context, "boots_haste")]) if is_ru else ("Perk: %.0f MOVE, +%.2f%% haste" % [float(context.get("move_speed", 0.0)), _pct(context, "boots_haste")])
		&"ring":
			return ("Перк: +%.2f%% двойной" % _pct(context, "ring_repeat")) if is_ru else ("Perk: +%.2f%% double" % _pct(context, "ring_repeat"))
		&"amulet":
			return ("Перк: +%.2f%% телепорт" % _pct(context, "amulet_teleport")) if is_ru else ("Perk: +%.2f%% teleport" % _pct(context, "amulet_teleport"))
		&"relic":
			return ("Перк: +%.2f%% клон" % _pct(context, "relic_clone")) if is_ru else ("Perk: +%.2f%% clone" % _pct(context, "relic_clone"))
		_:
			return ""

static func get_next_level_boost_text(equipment_id: StringName, level: int, language: StringName) -> String:
	var progress_delta: float = EquipmentProgressRules.effective_progress(level + 1) - EquipmentProgressRules.effective_progress(level)
	var is_ru: bool = language == &"ru"
	match equipment_id:
		&"weapon":
			return ("+%.2f урона" % (progress_delta * 0.18)) if is_ru else ("+%.2f damage" % (progress_delta * 0.18))
		&"helm":
			return "+%.2f HP, +%.3f DEF" % [progress_delta * 0.48, progress_delta * 0.045]
		&"chest":
			return "+%.2f HP, +%.3f DEF" % [progress_delta * 0.85, progress_delta * 0.075]
		&"gloves":
			return "+%.4f ATK/s" % (progress_delta * 0.0012)
		&"boots":
			return "+%.3f EVA" % (progress_delta * 0.040)
		&"ring":
			return "+%.3f ACC" % (progress_delta * 0.045)
		&"amulet":
			return "+%.3f DMG, +%.4f CRITx" % [progress_delta * 0.035, progress_delta * 0.00035]
		&"relic":
			return ("+%.3f ACC, +%.3f%% навык" % [progress_delta * 0.030, progress_delta * 0.018]) if is_ru else ("+%.3f ACC, +%.3f%% skill" % [progress_delta * 0.030, progress_delta * 0.018])
		_:
			return ""

static func get_current_effect_summary(equipment_id: StringName, level: int, context: Dictionary) -> String:
	var is_ru: bool = _is_ru(context)
	match equipment_id:
		&"weapon":
			var t1000: float = floor(float(level) / 1000.0)
			var skill_bonus_pct: float = EquipmentProgressRules.soft_cap_progress(t1000 * 0.03, 0.45, 0.90) * 100.0
			var cooldown_reduction_pct: float = EquipmentProgressRules.soft_cap_progress(t1000 * 0.01, 0.25, 0.45) * 100.0
			return ("Фокус: %s\nОбщий урон навыков: +%.0f%%\nКД навыков: -%.0f%%" % [_focus(context), skill_bonus_pct, cooldown_reduction_pct]) if is_ru else ("Focus: %s\nGlobal skill damage: +%.0f%%\nSkill cooldown: -%.0f%%" % [_focus(context), skill_bonus_pct, cooldown_reduction_pct])
		&"helm":
			return ("Блок: %.2f%%" % _pct(context, "block")) if is_ru else ("Block: %.2f%%" % _pct(context, "block"))
		&"chest":
			return ("Отражение: %.2f%%\nРеген HP: %.3f%%/с" % [_pct(context, "chest_reflect"), _pct(context, "hp_regen")]) if is_ru else ("Reflect: %.2f%%\nHP regen: %.3f%%/s" % [_pct(context, "chest_reflect"), _pct(context, "hp_regen")])
		&"gloves":
			return ("Сила отражения: %.2f%% входящего урона" % _pct(context, "gloves_reflect")) if is_ru else ("Reflect power: %.2f%% incoming damage" % _pct(context, "gloves_reflect"))
		&"boots":
			return ("Скорость движения: %.0f\nУскорение при ударе: %.2f%% на %.1fс" % [float(context.get("move_speed", 0.0)), _pct(context, "boots_haste"), float(context.get("boots_haste_duration", 0.0))]) if is_ru else ("Move speed: %.0f\nHaste on hit: %.2f%% for %.1fs" % [float(context.get("move_speed", 0.0)), _pct(context, "boots_haste"), float(context.get("boots_haste_duration", 0.0))])
		&"ring":
			return ("Двойное срабатывание: %.2f%%" % _pct(context, "ring_repeat")) if is_ru else ("Double trigger: %.2f%%" % _pct(context, "ring_repeat"))
		&"amulet":
			return ("Урон навыков: +%.0f%%\nТелепорт при ударе: %.2f%%" % [_pct(context, "amulet_skill"), _pct(context, "amulet_teleport")]) if is_ru else ("Skill damage: +%.0f%%\nTeleport on hit: %.2f%%" % [_pct(context, "amulet_skill"), _pct(context, "amulet_teleport")])
		&"relic":
			return ("Урон навыков: +%.0f%%\nСила эффектов: +%.1f%%\nКлон: %.2f%%, %.1fс, %.0f%% статов" % [_pct(context, "relic_skill"), _pct(context, "relic_proc"), _pct(context, "relic_clone"), float(context.get("relic_clone_duration", 0.0)), _pct(context, "relic_clone_stats")]) if is_ru else ("Skill damage: +%.0f%%\nEffect power: +%.1f%%\nClone: %.2f%%, %.1fs, %.0f%% stats" % [_pct(context, "relic_skill"), _pct(context, "relic_proc"), _pct(context, "relic_clone"), float(context.get("relic_clone_duration", 0.0)), _pct(context, "relic_clone_stats")])
		_:
			return ""

static func _base_hp_def_text(hp_bonus: float, def_bonus: float, is_ru: bool) -> String:
	return ("База: +%.0f HP, +%.1f DEF" % [hp_bonus, def_bonus]) if is_ru else ("Base: +%.0f HP, +%.1f DEF" % [hp_bonus, def_bonus])

static func _focus(context: Dictionary) -> String:
	return String(context.get("focus", ""))

static func _is_ru(context: Dictionary) -> bool:
	return context.get("language", &"ru") == &"ru"

static func _pct(context: Dictionary, key: String) -> float:
	return float(context.get(key, 0.0)) * 100.0
