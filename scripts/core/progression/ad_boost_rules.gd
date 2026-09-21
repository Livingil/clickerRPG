extends RefCounted
class_name AdBoostRules

const OFFER_INTERVAL_SEC: float = 180.0
const OFFER_VISIBLE_SEC: float = 16.6

const GOLD_RUSH: StringName = &"gold_rush"
const ESSENCE_SURGE: StringName = &"essence_surge"
const BATTLE_FOCUS: StringName = &"battle_focus"
const HASTE_SPARK: StringName = &"haste_spark"
const ECHO_MAGNET: StringName = &"echo_magnet"
const SECOND_WIND: StringName = &"second_wind"
const GAME_SPEED: StringName = &"game_speed"

const DEFS: Dictionary = {
	&"gold_rush": {"name_ru": "Золотая лихорадка", "name_en": "Gold Rush", "duration": 180.0, "short_ru": "x2 золото", "short_en": "x2 gold"},
	&"essence_surge": {"name_ru": "Всплеск эссенции", "name_en": "Essence Surge", "duration": 180.0, "short_ru": "x2 эссенция", "short_en": "x2 essence"},
	&"battle_focus": {"name_ru": "Боевой фокус", "name_en": "Battle Focus", "duration": 120.0, "short_ru": "+25% урон", "short_en": "+25% damage"},
	&"haste_spark": {"name_ru": "Искра скорости", "name_en": "Haste Spark", "duration": 120.0, "short_ru": "+20% скорость", "short_en": "+20% speed"},
	&"echo_magnet": {"name_ru": "Магнит эха", "name_en": "Echo Magnet", "duration": 180.0, "short_ru": "x2 эхо", "short_en": "x2 echo"},
	&"second_wind": {"name_ru": "Второе дыхание", "name_en": "Second Wind", "duration": 0.0, "short_ru": "полное HP", "short_en": "full HP"},
	&"game_speed": {"name_ru": "Перемотка", "name_en": "Fast Forward", "duration": 180.0, "short_ru": "x2 скорость", "short_en": "x2 speed"},
}

const OFFER_POOL: Array[StringName] = [
	GOLD_RUSH,
	ESSENCE_SURGE,
	BATTLE_FOCUS,
	HASTE_SPARK,
	ECHO_MAGNET,
	SECOND_WIND,
]

static func has_boost(boost_id: StringName) -> bool:
	return DEFS.has(boost_id)

static func get_duration(boost_id: StringName) -> float:
	var definition: Dictionary = DEFS.get(boost_id, {})
	return float(definition.get("duration", 0.0))

static func get_display_name(boost_id: StringName, language: StringName) -> String:
	var definition: Dictionary = DEFS.get(boost_id, {})
	if language == &"ru":
		return String(definition.get("name_ru", String(boost_id)))
	return String(definition.get("name_en", String(boost_id)))

static func get_short_text(boost_id: StringName, language: StringName) -> String:
	var definition: Dictionary = DEFS.get(boost_id, {})
	if language == &"ru":
		return String(definition.get("short_ru", "Буст"))
	return String(definition.get("short_en", "Boost"))

static func roll_offer_id() -> StringName:
	if OFFER_POOL.is_empty():
		return &""
	return OFFER_POOL[randi_range(0, OFFER_POOL.size() - 1)]
