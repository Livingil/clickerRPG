extends RefCounted
class_name ArtifactRules

const ARTIFACT_POOL: Array[StringName] = [
	&"ember_heart", &"crystal_lung", &"warhorn_shard", &"stone_eye", &"storm_compass",
	&"iron_leaf", &"moon_pin", &"glass_tooth", &"sun_thread", &"warden_coin",
	&"ashen_tome", &"tide_knot", &"gale_lock", &"thunder_nail", &"cinder_seal",
	&"deep_scale", &"oak_charm", &"spark_relic", &"frost_sigil", &"void_feather",
	&"hourglass_core", &"king_mint", &"echo_lantern", &"essence_vial", &"guardian_oath",
	&"execution_mark", &"school_prism", &"merchant_seal",
]

const ARTIFACT_EFFECTS: Dictionary = {
	&"ember_heart": {"stat": "damage", "coef": 0.09, "label": "damage"},
	&"crystal_lung": {"stat": "max_hp", "coef": 0.07, "label": "HP"},
	&"warhorn_shard": {"stat": "attack_speed", "coef": 0.001, "label": "attack speed"},
	&"stone_eye": {"stat": "accuracy", "coef": 0.06, "label": "accuracy"},
	&"storm_compass": {"stat": "crit_chance", "coef": 0.00018, "label": "crit chance", "percent": true},
	&"iron_leaf": {"stat": "crit_multiplier", "coef": 0.012, "label": "crit multiplier"},
	&"moon_pin": {"stat": "defense", "coef": 0.022, "label": "defense"},
	&"glass_tooth": {"stat": "evasion", "coef": 0.022, "label": "evasion"},
	&"sun_thread": {"stat": "artifact_bonus_block_chance", "coef": 0.0004, "label": "block chance", "percent": true},
	&"warden_coin": {"stat": "artifact_bonus_reflect_chance", "coef": 0.0005, "label": "reflect chance", "percent": true},
	&"ashen_tome": {"stat": "artifact_bonus_reflect_ratio", "coef": 0.003, "label": "reflect power", "percent": true},
	&"tide_knot": {"stat": "artifact_bonus_haste_chance", "coef": 0.0005, "label": "haste chance", "percent": true},
	&"gale_lock": {"stat": "artifact_bonus_haste_duration", "coef": 0.01, "label": "haste duration", "seconds": true},
	&"thunder_nail": {"stat": "artifact_bonus_repeat_chance", "coef": 0.0003, "label": "repeat chance", "percent": true},
	&"cinder_seal": {"stat": "artifact_bonus_teleport_chance", "coef": 0.0003, "label": "teleport chance", "percent": true},
	&"deep_scale": {"stat": "artifact_bonus_clone_chance", "coef": 0.0002, "label": "clone chance", "percent": true},
	&"oak_charm": {"stat": "artifact_bonus_clone_duration", "coef": 0.02, "label": "clone duration", "seconds": true},
	&"spark_relic": {"stat": "artifact_bonus_clone_stat_multiplier", "coef": 0.0006, "label": "clone power", "percent": true},
	&"frost_sigil": {"stat": "artifact_bonus_skill_damage_mult", "coef": 0.002, "label": "skill damage", "percent": true},
	&"void_feather": {"stat": "artifact_bonus_skill_proc_mult", "coef": 0.002, "label": "skill proc power", "percent": true},
	&"hourglass_core": {"stat": "artifact_bonus_boss_timer_sec", "coef": 0.05, "label": "boss timer", "seconds": true},
	&"king_mint": {"stat": "artifact_bonus_gold_mult", "coef": 0.0008, "label": "gold", "percent": true},
	&"echo_lantern": {"stat": "artifact_bonus_echo_mult", "coef": 0.0007, "label": "Echo", "percent": true},
	&"essence_vial": {"stat": "artifact_bonus_essence_mult", "coef": 0.0007, "label": "essence", "percent": true},
	&"guardian_oath": {"stat": "artifact_bonus_boss_damage_reduction", "coef": 0.0005, "label": "boss damage reduction", "percent": true},
	&"execution_mark": {"stat": "artifact_bonus_boss_damage_mult", "coef": 0.0007, "label": "boss damage", "percent": true},
	&"school_prism": {"stat": "artifact_bonus_school_xp_mult", "coef": 0.0006, "label": "school XP", "percent": true},
	&"merchant_seal": {"stat": "artifact_bonus_equipment_discount", "coef": 0.0004, "label": "equipment discount", "percent": true},
}

const RU_LABELS: Dictionary = {
	"damage": "урона",
	"HP": "HP",
	"attack speed": "скорости атаки",
	"accuracy": "точности",
	"crit chance": "шанса крита",
	"crit multiplier": "крит. множителя",
	"defense": "защиты",
	"evasion": "уклонения",
	"block chance": "шанса блока",
	"reflect chance": "шанса отражения",
	"reflect power": "силы отражения",
	"haste chance": "шанса ускорения",
	"haste duration": "длительности ускорения",
	"repeat chance": "шанса повтора",
	"teleport chance": "шанса телепорта",
	"clone chance": "шанса клона",
	"clone duration": "длительности клона",
	"clone power": "силы клона",
	"skill damage": "урона навыков",
	"skill proc power": "силы срабатывания навыков",
	"boss timer": "таймера босса",
	"gold": "золота",
	"Echo": "Echo",
	"essence": "эссенции",
	"boss damage reduction": "снижения урона от боссов",
	"boss damage": "урона по боссам",
	"school XP": "опыта школ",
	"equipment discount": "скидки на снаряжение",
}

static func get_display_name(artifact_id: StringName, language: StringName) -> String:
	match artifact_id:
		&"ember_heart":
			return "Тлеющее Сердце" if language == &"ru" else "Ember Heart"
		&"crystal_lung":
			return "Хрустальное Легкое" if language == &"ru" else "Crystal Lung"
		&"warhorn_shard":
			return "Осколок Боевого Рога" if language == &"ru" else "Warhorn Shard"
		&"stone_eye":
			return "Каменный Глаз" if language == &"ru" else "Stone Eye"
		&"storm_compass":
			return "Штормовой Компас" if language == &"ru" else "Storm Compass"
		&"iron_leaf":
			return "Железный Лист" if language == &"ru" else "Iron Leaf"
		&"moon_pin":
			return "Лунная Булавка" if language == &"ru" else "Moon Pin"
		&"glass_tooth":
			return "Стеклянный Зуб" if language == &"ru" else "Glass Tooth"
		&"sun_thread":
			return "Солнечная Нить" if language == &"ru" else "Sun Thread"
		&"warden_coin":
			return "Монета Стража" if language == &"ru" else "Warden Coin"
		&"ashen_tome":
			return "Пепельный Фолиант" if language == &"ru" else "Ashen Tome"
		&"tide_knot":
			return "Узел Прилива" if language == &"ru" else "Tide Knot"
		&"gale_lock":
			return "Замок Шквала" if language == &"ru" else "Gale Lock"
		&"thunder_nail":
			return "Громовой Гвоздь" if language == &"ru" else "Thunder Nail"
		&"cinder_seal":
			return "Печать Угля" if language == &"ru" else "Cinder Seal"
		&"deep_scale":
			return "Глубинная Чешуя" if language == &"ru" else "Deep Scale"
		&"oak_charm":
			return "Дубовый Оберег" if language == &"ru" else "Oak Charm"
		&"spark_relic":
			return "Искровая Реликвия" if language == &"ru" else "Spark Relic"
		&"frost_sigil":
			return "Морозный Знак" if language == &"ru" else "Frost Sigil"
		&"void_feather":
			return "Перо Пустоты" if language == &"ru" else "Void Feather"
		&"hourglass_core":
			return "Сердце Песочных Часов" if language == &"ru" else "Hourglass Core"
		&"king_mint":
			return "Королевский Монетный Двор" if language == &"ru" else "King Mint"
		&"echo_lantern":
			return "Фонарь Эха" if language == &"ru" else "Echo Lantern"
		&"essence_vial":
			return "Сосуд Эссенции" if language == &"ru" else "Essence Vial"
		&"guardian_oath":
			return "Клятва Стража" if language == &"ru" else "Guardian Oath"
		&"execution_mark":
			return "Метка Казни" if language == &"ru" else "Execution Mark"
		&"school_prism":
			return "Призма Школ" if language == &"ru" else "School Prism"
		&"merchant_seal":
			return "Печать Торговца" if language == &"ru" else "Merchant Seal"
		_:
			return String(artifact_id).replace("_", " ").capitalize()

static func get_effect(artifact_id: StringName) -> Dictionary:
	return ARTIFACT_EFFECTS.get(artifact_id, {})

static func get_effect_value(artifact_id: StringName, level: int) -> float:
	var effect: Dictionary = get_effect(artifact_id)
	if effect.is_empty():
		return 0.0
	return _get_effect_value(effect, level)

static func get_effect_summary(artifact_id: StringName, level: int, language: StringName) -> String:
	var effect: Dictionary = get_effect(artifact_id)
	if effect.is_empty():
		return "Нет эффекта." if language == &"ru" else "No effect."
	var label: String = String(effect.get("label", "effect"))
	var value: float = _get_effect_value(effect, level)
	var is_ru: bool = language == &"ru"
	var ui_label: String = String(RU_LABELS.get(label, label)) if is_ru else label
	if bool(effect.get("percent", false)):
		return ("Дает +%.2f%% %s." % [value * 100.0, ui_label]) if is_ru else ("Gives +%.2f%% %s." % [value * 100.0, ui_label])
	if bool(effect.get("seconds", false)):
		return ("Дает +%.2fс %s." % [value, ui_label]) if is_ru else ("Gives +%.2fs %s." % [value, ui_label])
	if label == "HP":
		return ("Дает +%.0f %s." % [value, ui_label]) if is_ru else ("Gives +%.0f %s." % [value, ui_label])
	return ("Дает +%.2f %s." % [value, ui_label]) if is_ru else ("Gives +%.2f %s." % [value, ui_label])

static func get_unowned_pool(owned_artifacts: Array[StringName]) -> Array[StringName]:
	var available_artifacts: Array[StringName] = []
	for artifact_id in ARTIFACT_POOL:
		if not owned_artifacts.has(artifact_id):
			available_artifacts.append(artifact_id)
	return available_artifacts

static func _get_effect_value(effect: Dictionary, level: int) -> float:
	var raw_value: float = maxi(0, level) * float(effect.get("coef", 0.0))
	if not effect.has("cap"):
		return raw_value
	var hard_cap: float = float(effect.get("cap", raw_value))
	var soft_cap: float = float(effect.get("soft_cap", hard_cap))
	if raw_value <= soft_cap:
		return minf(raw_value, hard_cap)
	var overflow: float = raw_value - soft_cap
	return minf(hard_cap, soft_cap + overflow * 0.5)
