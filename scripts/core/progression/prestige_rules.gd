extends RefCounted
class_name PrestigeRules

const UNLOCK_WAVE: int = 50
const ATTACK: StringName = &"attack"
const HP: StringName = &"hp"
const DEFENSE: StringName = &"defense"
const CRIT: StringName = &"crit"
const SCHOOL_XP: StringName = &"school_xp"
const GOLD: StringName = &"gold"
const CRAFT: StringName = &"craft"

const UPGRADE_ORDER: Array[StringName] = [
	ATTACK,
	HP,
	DEFENSE,
	CRIT,
	SCHOOL_XP,
	GOLD,
	CRAFT,
]

const UPGRADE_DEFS: Dictionary = {
	&"attack": {"name_ru": "Атака", "name_en": "Attack", "base_cost": 1, "cost_step": 2, "max_level": 100, "per_level": 0.005, "desc_ru": "+0.5% урона героя", "desc_en": "+0.5% hero damage"},
	&"hp": {"name_ru": "Живучесть", "name_en": "Vitality", "base_cost": 1, "cost_step": 2, "max_level": 100, "per_level": 0.005, "desc_ru": "+0.5% max HP", "desc_en": "+0.5% max HP"},
	&"defense": {"name_ru": "Защита", "name_en": "Defense", "base_cost": 1, "cost_step": 2, "max_level": 100, "per_level": 0.005, "desc_ru": "+0.5% защиты", "desc_en": "+0.5% defense"},
	&"crit": {"name_ru": "Крит", "name_en": "Crit", "base_cost": 2, "cost_step": 2, "max_level": 80, "crit_chance": 0.00025, "crit_mult": 0.002, "desc_ru": "+0.025% шанс крита, +0.002x крит. множитель", "desc_en": "+0.025% crit chance, +0.002x crit multiplier"},
	&"school_xp": {"name_ru": "Учение", "name_en": "Study", "base_cost": 1, "cost_step": 2, "max_level": 100, "per_level": 0.006, "desc_ru": "+0.6% XP школ", "desc_en": "+0.6% school XP"},
	&"gold": {"name_ru": "Добыча", "name_en": "Prosperity", "base_cost": 1, "cost_step": 2, "max_level": 100, "per_level": 0.006, "desc_ru": "+0.6% золота", "desc_en": "+0.6% gold"},
	&"craft": {"name_ru": "Ремесло", "name_en": "Craft", "base_cost": 2, "cost_step": 2, "max_level": 60, "per_level": 0.003, "cap": 0.12, "desc_ru": "-0.3% цена предметов, до -12%", "desc_en": "-0.3% equipment costs, up to -12%"},
}

static func can_perform(highest_wave: int) -> bool:
	return highest_wave >= UNLOCK_WAVE

static func get_unlock_text(language: StringName) -> String:
	return "Доступно с волны %d" % UNLOCK_WAVE if language == &"ru" else "Available from wave %d" % UNLOCK_WAVE

static func get_shards_for_wave(highest_wave: int) -> int:
	if not can_perform(highest_wave):
		return 0
	var wave_shards: int = int(floor(float(highest_wave - UNLOCK_WAVE) / 25.0)) + 1
	return maxi(1, wave_shards)

static func get_upgrade_ids() -> Array[StringName]:
	return UPGRADE_ORDER.duplicate()

static func has_upgrade(upgrade_id: StringName) -> bool:
	return UPGRADE_DEFS.has(upgrade_id)

static func get_upgrade_cost(upgrade_id: StringName, level: int) -> int:
	var definition: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	var max_level: int = int(definition.get("max_level", 0))
	if max_level > 0 and level >= max_level:
		return 0
	return int(definition.get("base_cost", 1)) + level * int(definition.get("cost_step", 1))

static func get_upgrade_display_name(upgrade_id: StringName, language: StringName) -> String:
	var definition: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	return String(definition.get("name_ru" if language == &"ru" else "name_en", String(upgrade_id)))

static func get_upgrade_description(upgrade_id: StringName, language: StringName) -> String:
	var definition: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	return String(definition.get("desc_ru" if language == &"ru" else "desc_en", ""))

static func get_stat_multiplier(upgrade_id: StringName, level: int) -> float:
	var definition: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	return 1.0 + level * float(definition.get("per_level", 0.0))

static func get_crit_chance_bonus(level: int) -> float:
	return level * float(UPGRADE_DEFS[CRIT].get("crit_chance", 0.0))

static func get_crit_multiplier_bonus(level: int) -> float:
	return level * float(UPGRADE_DEFS[CRIT].get("crit_mult", 0.0))

static func get_school_xp_multiplier_for_total_shards(total_shards: int) -> float:
	var first_chunk: int = mini(maxi(0, total_shards), 100)
	var overflow: int = maxi(0, total_shards - 100)
	return 1.0 + float(first_chunk) * 0.002 + float(overflow) * 0.0005

static func get_equipment_cost_discount(craft_level: int) -> float:
	var definition: Dictionary = UPGRADE_DEFS[CRAFT]
	return minf(
		float(definition.get("cap", 0.30)),
		craft_level * float(definition.get("per_level", 0.0))
	)

static func get_new_milestone_lines(next_count: int, language: StringName) -> Array[String]:
	var is_ru: bool = language == &"ru"
	var lines: Array[String] = []
	if next_count == 1:
		lines.append("Первый престиж: открыто дерево престижа" if is_ru else "First prestige: prestige tree unlocked")
	if next_count == 3:
		lines.append("Заработанные shards мягко ускоряют XP школ" if is_ru else "Earned shards softly improve school XP")
	if next_count == 5:
		lines.append("Веха 5 престижей: стабильный мета-прогресс" if is_ru else "5 prestige milestone: stable meta progress")
	if next_count == 10:
		lines.append("Веха 10 престижей: глубокий цикл усиления" if is_ru else "10 prestige milestone: deep power loop")
	return lines
