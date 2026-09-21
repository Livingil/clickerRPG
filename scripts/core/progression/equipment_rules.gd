extends RefCounted
class_name EquipmentRules

const ORDER: Array[StringName] = [&"weapon", &"helm", &"chest", &"gloves", &"boots", &"ring", &"amulet", &"relic"]
const DEFS: Dictionary = {
	&"weapon": {"name": "Weapon", "base_cost": 50, "cost_scale": 1.12},
	&"helm": {"name": "Helm", "base_cost": 40, "cost_scale": 1.11},
	&"chest": {"name": "Chest", "base_cost": 55, "cost_scale": 1.12},
	&"gloves": {"name": "Gloves", "base_cost": 42, "cost_scale": 1.11},
	&"boots": {"name": "Boots", "base_cost": 42, "cost_scale": 1.11},
	&"ring": {"name": "Ring", "base_cost": 48, "cost_scale": 1.115},
	&"amulet": {"name": "Amulet", "base_cost": 50, "cost_scale": 1.115},
	&"relic": {"name": "Relic", "base_cost": 60, "cost_scale": 1.12},
}
const UNLOCK_COSTS: Dictionary = {
	&"helm": 2000,
	&"chest": 9600,
	&"gloves": 32000,
	&"boots": 80000,
	&"ring": 176000,
	&"amulet": 360000,
	&"relic": 720000,
}

static func has_equipment(equipment_id: StringName) -> bool:
	return ORDER.has(equipment_id)

static func get_ids() -> Array[StringName]:
	return ORDER.duplicate()

static func get_display_name(equipment_id: StringName, language: StringName) -> String:
	var is_ru: bool = language == &"ru"
	match equipment_id:
		&"weapon":
			return "Оружие" if is_ru else "Weapon"
		&"helm":
			return "Шлем" if is_ru else "Helm"
		&"chest":
			return "Броня" if is_ru else "Chest"
		&"gloves":
			return "Перчатки" if is_ru else "Gloves"
		&"boots":
			return "Сапоги" if is_ru else "Boots"
		&"ring":
			return "Кольцо" if is_ru else "Ring"
		&"amulet":
			return "Амулет" if is_ru else "Amulet"
		&"relic":
			return "Реликвия" if is_ru else "Relic"
		_:
			return String(equipment_id).capitalize()

static func get_unlock_cost(equipment_id: StringName) -> int:
	if equipment_id == &"weapon":
		return 0
	return int(UNLOCK_COSTS.get(equipment_id, 0))

static func get_upgrade_cost(equipment_id: StringName, level: int, discount: float) -> int:
	var definition: Dictionary = DEFS.get(equipment_id, {})
	var base_cost: float = float(definition.get("base_cost", 50))
	var idx: int = ORDER.find(equipment_id)
	var raw_cost: int
	if idx <= 0:
		raw_cost = compute_progressive_cost(base_cost, level)
	else:
		var unlock_cost: int = get_unlock_cost(equipment_id)
		var anchor_cost: float = maxf(base_cost, float(unlock_cost) * 0.30)
		raw_cost = compute_progressive_cost(anchor_cost, level)
	return apply_cost_discount(raw_cost, discount)

static func compute_progressive_cost(base_cost: float, effective_level: int) -> int:
	var l0: int = mini(effective_level, GameConstants.BALANCE_COST_PHASE1_CAP)
	var l1: int = mini(
		maxi(0, effective_level - GameConstants.BALANCE_COST_PHASE1_CAP),
		GameConstants.BALANCE_COST_PHASE2_CAP - GameConstants.BALANCE_COST_PHASE1_CAP
	)
	var l2: int = maxi(0, effective_level - GameConstants.BALANCE_COST_PHASE2_CAP)

	var cost: float = base_cost
	cost *= pow(GameConstants.BALANCE_COST_PHASE1_RATE, l0)
	cost *= pow(GameConstants.BALANCE_COST_PHASE2_RATE, l1)
	cost *= pow(GameConstants.BALANCE_COST_PHASE3_RATE, l2)
	return int(maxi(1, int(round(cost))))

static func apply_cost_discount(cost: int, discount: float) -> int:
	return maxi(1, int(round(float(cost) * (1.0 - discount))))

static func effective_progress(level: int) -> float:
	var safe_level: int = maxi(0, level)
	var early: float = float(mini(safe_level, 250))
	var mid: float = float(mini(maxi(0, safe_level - 250), 750)) * 0.45
	var late_level: int = maxi(0, safe_level - 1000)
	var late: float = log(1.0 + float(late_level)) * 160.0
	return early + mid + late

static func get_next_perk_upgrade_text(equipment_id: StringName, level: int, language: StringName) -> String:
	var step: int = 100
	if equipment_id == &"weapon":
		step = 1000
	var next_level: int = int((floor(float(level) / float(step)) + 1.0) * float(step))
	if next_level <= level:
		next_level += step
	return ("Откроется на %d ур." % next_level) if language == &"ru" else ("Unlocks at Lv.%d" % next_level)

static func get_next_milestone_short_text(equipment_id: StringName, level: int, language: StringName) -> String:
	var next_level: int = get_next_milestone_level(equipment_id, level)
	if next_level <= 0:
		return ""
	return ("Веха: Ур.%d" % next_level) if language == &"ru" else ("Milestone: Lv.%d" % next_level)

static func get_next_milestone_text(equipment_id: StringName, level: int, language: StringName) -> String:
	var next_level: int = get_next_milestone_level(equipment_id, level)
	if next_level <= level:
		return ""
	var reward_text: String = get_milestone_reward_text(equipment_id, next_level, language)
	if language == &"ru":
		return "Ур.%d: %s" % [next_level, reward_text]
	return "Lv.%d: %s" % [next_level, reward_text]

static func get_periodic_milestones_text(equipment_id: StringName, language: StringName) -> String:
	var is_ru: bool = language == &"ru"
	match equipment_id:
		&"weapon":
			return "Каждые 100 ур.: выбор школы +1% урон навыков, +0.5% сила эффектов\nКаждые 1000 ур.: +3% общий урон навыков, -1% КД навыков" if is_ru else "Every 100 lv: school pick +1% skill damage, +0.5% effect power\nEvery 1000 lv: +3% global skill damage, -1% skill cooldown"
		&"helm":
			return "Каждые 100 ур.: +DEF и шанс блока\nКаждые 1000 ур.: крупный бонус HP и DEF" if is_ru else "Every 100 lv: +DEF and block chance\nEvery 1000 lv: large HP and DEF bonus"
		&"chest":
			return "Каждые 100 ур.: +DEF, отражение и реген HP\nКаждые 1000 ур.: крупный бонус HP и DEF" if is_ru else "Every 100 lv: +DEF, reflect and HP regen\nEvery 1000 lv: large HP and DEF bonus"
		&"gloves":
			return "Каждые 100 ур.: скорость атаки и сила отражения\nКаждые 1000 ур.: крупный бонус скорости атаки" if is_ru else "Every 100 lv: attack speed and reflect power\nEvery 1000 lv: large attack speed bonus"
		&"boots":
			return "Каждые 100 ур.: +5 скорости движения и шанс ускорения\nКаждые 300 ур.: длительность ускорения\nКаждые 1000 ур.: бонус уклонения" if is_ru else "Every 100 lv: +5 move speed and haste chance\nEvery 300 lv: haste duration\nEvery 1000 lv: evasion bonus"
		&"ring":
			return "Каждые 100 ур.: крит-шанс и шанс двойного срабатывания\nКаждые 1000 ур.: дополнительный крит-шанс" if is_ru else "Every 100 lv: crit chance and double trigger chance\nEvery 1000 lv: extra crit chance"
		&"amulet":
			return "Каждые 100 ур.: крит-множитель и шанс телепорта\nКаждые 1000 ур.: урон навыков" if is_ru else "Every 100 lv: crit multiplier and teleport chance\nEvery 1000 lv: skill damage"
		&"relic":
			return "Каждые 100 ур.: точность, сила эффектов и шанс клона\nКаждые 500 ур.: сила клона" if is_ru else "Every 100 lv: accuracy, effect power and clone chance\nEvery 500 lv: clone power"
		_:
			return ""

static func get_next_milestone_level(equipment_id: StringName, level: int) -> int:
	var periods: Array[int] = get_milestone_periods(equipment_id)
	var best_level: int = 2147483647
	for period in periods:
		if period <= 0:
			continue
		var candidate: int = int((floor(float(level) / float(period)) + 1.0) * float(period))
		if candidate <= level:
			candidate += period
		best_level = mini(best_level, candidate)
	return 0 if best_level == 2147483647 else best_level

static func get_milestone_periods(equipment_id: StringName) -> Array[int]:
	match equipment_id:
		&"weapon":
			return [100, 1000]
		&"boots":
			return [100, 300, 1000]
		&"relic":
			return [100, 500]
		_:
			return [100, 1000]

static func get_milestone_reward_text(equipment_id: StringName, milestone_level: int, language: StringName) -> String:
	var is_ru: bool = language == &"ru"
	match equipment_id:
		&"weapon":
			if milestone_level % 1000 == 0:
				return "+3% общий урон навыков, -1% КД навыков" if is_ru else "+3% global skill damage, -1% skill cooldown"
			return "выбор школы" if is_ru else "school pick"
		&"helm":
			if milestone_level % 1000 == 0:
				return "крупный бонус HP и DEF" if is_ru else "large HP and DEF bonus"
			return "+DEF и шанс блока" if is_ru else "+DEF and block chance"
		&"chest":
			if milestone_level % 1000 == 0:
				return "крупный бонус HP и DEF" if is_ru else "large HP and DEF bonus"
			return "+DEF, отражение и реген HP" if is_ru else "+DEF, reflect and HP regen"
		&"gloves":
			if milestone_level % 1000 == 0:
				return "крупный бонус скорости атаки" if is_ru else "large attack speed bonus"
			return "скорость атаки и сила отражения" if is_ru else "attack speed and reflect power"
		&"boots":
			if milestone_level % 1000 == 0:
				return "бонус уклонения" if is_ru else "evasion bonus"
			if milestone_level % 300 == 0:
				return "длительность ускорения" if is_ru else "haste duration"
			return "+5 скорости движения и шанс ускорения" if is_ru else "+5 move speed and haste chance"
		&"ring":
			if milestone_level % 1000 == 0:
				return "дополнительный крит-шанс" if is_ru else "extra crit chance"
			return "крит-шанс и двойное срабатывание" if is_ru else "crit chance and double trigger"
		&"amulet":
			if milestone_level % 1000 == 0:
				return "урон навыков" if is_ru else "skill damage"
			return "крит-множитель и телепорт" if is_ru else "crit multiplier and teleport"
		&"relic":
			if milestone_level % 500 == 0:
				return "сила клона" if is_ru else "clone power"
			return "точность, эффекты и шанс клона" if is_ru else "accuracy, effects and clone chance"
		_:
			return ""
