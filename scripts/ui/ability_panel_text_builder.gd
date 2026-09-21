extends RefCounted
class_name AbilityPanelTextBuilder

const SKILL_BASE_INFO: Dictionary = {
	&"ember_chain": {"cd": 3.0, "shape": "Метка/поджог", "ratios": [1.05, 1.35, 0.35], "ratio_labels": ["Удар", "По горящей", "Распространение"]},
	&"cinder_burst": {"cd": 5.5, "shape": "Взрыв/горение", "ratios": [0.82, 1.08], "ratio_labels": ["Обычный взрыв", "По горящей"]},
	&"ash_storm": {"cd": 8.0, "shape": "Шторм/конус", "ratios": [1.25], "ratio_labels": ["Урон шторма"]},
	&"frost_orb": {"cd": 4.0, "shape": "Сфера", "ratios": [1.0], "ratio_labels": ["Базовый удар"]},
	&"tidal_pulse": {"cd": 6.0, "shape": "Волна", "ratios": [1.0], "ratio_labels": ["Базовый удар"]},
	&"glacial_field": {"cd": 8.0, "shape": "Поле", "ratios": [1.0], "ratio_labels": ["Базовый удар"]},
	&"stone_spike": {"cd": 4.2, "shape": "Шип/цель", "ratios": [1.15, 1.50], "ratio_labels": ["Удар", "По заморозке"]},
	&"quake_ring": {"cd": 6.3, "shape": "Широкий отбой", "ratios": [0.58], "ratio_labels": ["Урон кольца"]},
	&"bastion_crash": {"cd": 8.6, "shape": "Бастион 4 сек.", "ratios": [0.44], "ratio_labels": ["Урон тика"]},
	&"razor_gust": {"cd": 3.8, "shape": "Порыв/цель", "ratios": [0.95], "ratio_labels": ["Порыв"]},
	&"cyclone_arc": {"cd": 6.2, "shape": "Циклон/стяжка", "ratios": [0.62], "ratio_labels": ["Урон циклона"]},
	&"sky_flurry": {"cd": 8.5, "shape": "3 удара/стрелки", "ratios": [0.50, 0.72], "ratio_labels": ["Обычная цель", "Стрелок"]},
	&"spark_jump": {"cd": 3.5, "shape": "Цепь/до 3 целей", "ratios": [1.0, 0.70, 0.50], "ratio_labels": ["1 цель", "2 цель", "3 цель"]},
	&"volt_lance": {"cd": 5.8, "shape": "Линия/пробой", "ratios": [1.15], "ratio_labels": ["Урон линии"]},
	&"thunder_crown": {"cd": 9.0, "shape": "Аура 6 сек.", "ratios": [0.45], "ratio_labels": ["Урон тика"]},
}

const SKILL_DESC_RU: Dictionary = {
	&"ember_chain": "Огненная метка бьет одну цель и поджигает ее. Если цель уже горит, удар сильнее, а искры распространяют слабый поджог на ближайших врагов.",
	&"cinder_burst": "Взрыв огня по цели и ближайшим врагам. Если цель уже горит, взрыв шире, сильнее и добавляет extra-стак огня соседям.",
	&"ash_storm": "Создает зону пепла, наносящую периодический урон.",
	&"frost_orb": "Ледяной снаряд с короткой заморозкой и небольшой лужей. Вода теперь больше про замедление, чем про постоянный hard-control.",
	&"tidal_pulse": "Импульс воды создает sustain-зону: умеренный урон, slow и небольшое лечение героя.",
	&"glacial_field": "Короткая метель по всей зоне: умеренный урон и массовое замедление без слишком долгого контроля.",
	&"stone_spike": "Каменный шип бьет ближайшую цель, сильнее бьет замороженных врагов и быстро набирает стаки земли.",
	&"quake_ring": "Широкое землетрясение вокруг героя: слабый урон, сильное отбрасывание и контроль дистанции.",
	&"bastion_crash": "Герой поднимает бастион на 4 секунды: получает +25% защиты, а враги рядом периодически получают урон и дополнительные стаки земли.",
	&"razor_gust": "Быстрый воздушный порыв по ближайшей цели. Накладывает воздух, снижает точность, срывает ближайшую атаку и отталкивает.",
	&"cyclone_arc": "Циклон вокруг цели слабо бьет группу врагов, быстрее набирает воздух, срывает атаки и стягивает их к центру.",
	&"sky_flurry": "Серия из трех воздушных ударов с приоритетом по стрелкам. По стрелкам бьет сильнее, быстрее режет точность и заметнее задерживает выстрел.",
	&"spark_jump": "Разряд прыгает по цепочке до трех врагов. Накладывает молнию; на 5 стаках цель получает разряд и часть урона перекидывается дальше.",
	&"volt_lance": "Пробивное копье молнии бьет всех врагов на линии перед героем и быстро набирает стаки молнии.",
	&"thunder_crown": "На 6 секунд создает грозовую корону вокруг героя. Враги рядом периодически получают урон и стаки молнии.",
}

static func build_current_bonus_text(school_id: StringName, is_ru: bool) -> String:
	var bonuses: Dictionary = GameState.get_school_mastery_skill_bonuses(school_id)
	var dmg_pct: float = float(bonuses.get("damage_bonus", 0.0)) * 100.0
	var cd_pct: float = float(bonuses.get("cooldown_reduction", 0.0)) * 100.0
	var proc_pct: float = float(bonuses.get("proc_bonus", 0.0)) * 100.0
	var unique_text: String = String(bonuses.get("unique_bonus_text", ""))
	if is_ru:
		var base_ru: String = "Текущие бонусы: +%.1f%% урон, -%.1f%% КД, +%.1f%% сила эффектов" % [dmg_pct, cd_pct, proc_pct]
		if unique_text != "":
			base_ru += " | Lv10: " + unique_text
		return base_ru
	var base_en: String = "Current bonuses: +%.1f%% damage, -%.1f%% cd, +%.1f%% effect power" % [dmg_pct, cd_pct, proc_pct]
	if unique_text != "":
		base_en += " | Lv10: " + unique_text
	return base_en

static func build_next_unlock_text(core_level: int, is_ru: bool) -> String:
	var next_level: int = core_level + 1
	var next_reward: String = ""
	match next_level:
		1:
			next_reward = "Открытие 1-го навыка школы" if is_ru else "Unlock 1st school skill"
		2:
			next_reward = "+4% урон навыков" if is_ru else "+4% skill damage"
		3:
			next_reward = "Открытие 2-го навыка школы" if is_ru else "Unlock 2nd school skill"
		4:
			next_reward = "-3% КД навыков" if is_ru else "-3% skill cooldown"
		5:
			next_reward = "Открытие 3-го навыка школы" if is_ru else "Unlock 3rd school skill"
		6:
			next_reward = "+8% сила эффектов школы" if is_ru else "+8% school effect power"
		7:
			next_reward = "-5% КД навыков школы" if is_ru else "-5% school skill cooldown"
		8:
			next_reward = "+10% урон навыков школы" if is_ru else "+10% school skill damage"
		9:
			next_reward = "-5% КД навыков школы" if is_ru else "-5% school skill cooldown"
		10:
			next_reward = "Уникальный бонус школы" if is_ru else "Unique school bonus"
		_:
			next_reward = "+1.5% урон, +1% сила эффектов" if is_ru else "+1.5% damage, +1% effect power"
	return ("Следующий уровень (Lv.%d): %s" % [next_level, next_reward]) if is_ru else ("Next level (Lv.%d): %s" % [next_level, next_reward])

static func build_slot_text(slot_index: int, equipped_skill_ids: Array[StringName], language: StringName) -> String:
	var is_ru: bool = language == &"ru"
	if slot_index >= GameState.get_permanent_skill_slot_count():
		return "Слот %d\nОткр. волна %d" % [slot_index + 1, SchoolRules.SLOT_WAVE_UNLOCKS[slot_index]] if is_ru else "Slot %d\nUnlock wave %d" % [slot_index + 1, SchoolRules.SLOT_WAVE_UNLOCKS[slot_index]]
	var equipped_skill_id: StringName = &""
	if slot_index < equipped_skill_ids.size():
		equipped_skill_id = equipped_skill_ids[slot_index]
	var slot_text: String = ("Слот %d\n" % (slot_index + 1)) if is_ru else ("Slot %d\n" % (slot_index + 1))
	if equipped_skill_id == &"":
		slot_text += ("Пусто" if is_ru else "Empty")
	else:
		var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(equipped_skill_id, {})
		slot_text += String(skill_data.get("name", equipped_skill_id))
	return slot_text

static func build_skill_tooltip(skill_id: StringName, skill_data: Dictionary, pending_skill_id: StringName, equipped: bool) -> String:
	var text: String = String(skill_data.get("name", skill_id))
	if pending_skill_id == skill_id:
		text += " - %s" % GameState.loc("abilities.selected")
	if equipped:
		text += " - %s" % GameState.loc("abilities.state_equipped")
	return text

static func build_skill_info_text(skill_id: StringName, language: StringName) -> String:
	var is_ru: bool = language == &"ru"
	if skill_id == &"":
		return "Выберите навык, чтобы увидеть описание." if is_ru else "Select a skill to see details."

	var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
	var skill_name: String = String(skill_data.get("name", skill_id))
	var unlock_level: int = int(skill_data.get("unlock_level", 0))
	var base_info: Dictionary = SKILL_BASE_INFO.get(skill_id, {})
	var cd: float = float(base_info.get("cd", 0.0))
	var shape: String = String(base_info.get("shape", ""))
	var desc: String = String(SKILL_DESC_RU.get(skill_id, "Описание пока не задано."))
	var ratios: Array = base_info.get("ratios", [1.0])
	var ratio_labels: Array = base_info.get("ratio_labels", ["Базовый удар"])
	var hero_damage: float = GameState.build_hero_stats().damage
	var dmg_mult: float = GameState.get_skill_damage_multiplier(skill_id)
	var cd_mult: float = GameState.get_skill_cooldown_multiplier(skill_id)
	var proc_mult: float = GameState.get_skill_proc_multiplier(skill_id)
	var current_cd: float = cd * cd_mult

	var base_lines: Array[String] = []
	var current_lines: Array[String] = []
	for i in range(ratios.size()):
		var ratio: float = float(ratios[i])
		var label: String = String(ratio_labels[i]) if i < ratio_labels.size() else ("Hit %d" % (i + 1))
		base_lines.append("%s: x%.2f" % [label, ratio])
		var current_hit: float = hero_damage * ratio * dmg_mult * proc_mult
		current_lines.append("%s: %.1f" % [label, current_hit])

	if is_ru:
		var base_block: String = "\n".join(base_lines)
		var current_block: String = "\n".join(current_lines)
		return (
			"[b]%s[/b]\n" % skill_name
			+ "Открытие: ур.%d школы\n" % unlock_level
			+ "Форма: %s\n\n" % shape
			+ "[b]Базовые показатели[/b]\n"
			+ "КД: %.2fс\n" % cd
			+ "Proc: x1.00\n"
			+ "Множители урона:\n%s\n\n" % base_block
			+ "[b]Текущие показатели[/b]\n"
			+ "КД: %.2fс\n" % current_cd
			+ "Множитель урона навыка: x%.3f\n" % dmg_mult
			+ "Proc множитель: x%.3f\n" % proc_mult
			+ "Расчетный урон:\n%s\n\n" % current_block
			+ "[b]Описание[/b]\n%s" % desc
		)
	return (
		"[b]%s[/b]\n" % skill_name
		+ "Unlock: school Lv.%d\n" % unlock_level
		+ "Shape: %s\n\n" % shape
		+ "[b]Base stats[/b]\n"
		+ "CD: %.2fs\n" % cd
		+ "Proc: x1.00\n"
		+ "Damage ratios:\n%s\n\n" % "\n".join(base_lines)
		+ "[b]Current stats[/b]\n"
		+ "CD: %.2fs\n" % current_cd
		+ "Skill damage mult: x%.3f\n" % dmg_mult
		+ "Proc mult: x%.3f\n" % proc_mult
		+ "Estimated damage:\n%s" % "\n".join(current_lines)
	)
