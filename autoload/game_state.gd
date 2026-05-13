extends Node
const BalanceSimulator = preload("res://scripts/dev/balance_simulator.gd")

signal resources_changed(gold: int, essence: int)
signal echo_changed(collected_echo: int, active_echo_power: int)
signal hero_stats_changed
signal upgrades_changed
signal school_state_changed
signal school_mastery_changed
signal prestige_performed
signal combat_text_settings_changed
signal language_changed

const UPGRADE_DAMAGE: StringName = &"damage"
const UPGRADE_ATTACK_SPEED: StringName = &"attack_speed"
const UPGRADE_CRIT_CHANCE: StringName = &"crit_chance"
const UPGRADE_CRIT_MULTIPLIER: StringName = &"crit_multiplier"

var gold: int = 0
var essence: int = 0
var echo_collected: int = 0
var echo_power: int = 0
var highest_wave_reached: int = 1
var total_deaths: int = 0
var best_run_time_sec: float = 0.0
var active_school: StringName = SchoolRules.SCHOOL_FIRE
var school_mastery_xp: Dictionary = {}
var unlocked_global_skill_ids: Array[StringName] = []
var equipped_skill_ids: Array[StringName] = []
var show_damage_text: bool = true
var show_crit_text: bool = true
var show_miss_text: bool = true
var show_hero_damage_text: bool = true
var show_hero_miss_text: bool = true
var current_language: StringName = &"ru"
var equipment_levels: Dictionary = {}
var equipment_unlocked: Dictionary = {}
var artifact_levels: Dictionary = {}
var owned_artifacts: Array[StringName] = []
var defeated_apex_wave_rewards: Array[int] = []
var incoming_hits_since_absorb: int = 0
var pending_weapon_skill_offers: Array[Dictionary] = []
var skill_upgrade_levels: Dictionary = {}
var repeat_action_icd_left: float = 0.0
var haste_buff_time_left: float = 0.0
var clone_buff_time_left: float = 0.0
var clone_stat_multiplier: float = 0.0
var teleport_icd_left: float = 0.0
var haste_icd_left: float = 0.0
var clone_icd_left: float = 0.0

const TRANSLATIONS := {
	&"ru": {
		"ui.settings": "Настройки",
		"ui.skills": "Навыки",
		"ui.upgrades": "Улучшения",
		"ui.run": "Забег",
		"ui.prestige": "Престиж",
		"ui.combat_text": "Боевой текст",
		"ui.show_damage": "Показывать урон",
		"ui.show_crit": "Показывать криты",
		"ui.show_miss": "Показывать промахи",
		"ui.show_hero_damage": "Урон по герою",
		"ui.show_hero_miss": "Промахи по герою",
		"ui.language": "Язык",
		"ui.enemy_summary": "Враги: Урон %s | Крит %s | Промах %s",
		"ui.hero_summary": "Герой: Урон %s | Промах %s",
		"ui.on": "ВКЛ",
		"ui.off": "ВЫКЛ",
		"run.title": "Забег",
		"run.overview": "Сводка",
		"run.wave_record": "Рекорд волны",
		"run.current_dps": "Текущий DPS",
		"run.echo_collected": "Эхо собрано",
		"run.echo_active": "Эхо активно",
		"run.echo": "Эхо",
		"run.active_bonus": "Активный бонус",
		"run.after_death_bonus": "Бонус после смерти",
		"run.hero_stats": "Статы героя (текущий забег)",
		"stat.damage": "Урон",
		"stat.attack_speed": "Скорость атаки",
		"stat.dps": "DPS",
		"stat.max_hp": "Макс HP",
		"stat.crit_chance": "Шанс крита",
		"stat.crit_mult": "Множ. крита",
		"stat.defense": "Защита",
		"stat.evasion": "Уклонение",
		"stat.accuracy": "Точность",
		"abilities.permanent_slots": "постоянных слота навыков",
		"abilities.unlocks": "Открытия на мастерстве 1 / 4 / 5",
		"abilities.equipped": "Экипировано:",
		"abilities.slot": "Слот",
		"abilities.locked": "Закрыт",
		"abilities.locked_wave": "Закрыт до волны",
		"abilities.empty": "Пусто",
		"abilities.tap_set": "Нажми, чтобы установить",
		"abilities.tap_clear": "Нажми, чтобы очистить",
		"abilities.available": "Доступно",
		"abilities.selected": "Выбрано",
		"abilities.state_need_wave_slot": "Нужен слот за волну %d",
		"abilities.state_equipped": "Экипировано",
		"abilities.state_available": "Доступно",
		"abilities.state_select_replace": "Выбери для замены",
	},
	&"en": {
		"ui.settings": "Settings",
		"ui.skills": "Skills",
		"ui.upgrades": "Upgrades",
		"ui.run": "Run",
		"ui.prestige": "Prestige",
		"ui.combat_text": "Combat Text",
		"ui.show_damage": "Show Damage",
		"ui.show_crit": "Show Crit",
		"ui.show_miss": "Show Miss",
		"ui.show_hero_damage": "Show Hero Damage",
		"ui.show_hero_miss": "Show Hero Miss",
		"ui.language": "Language",
		"ui.enemy_summary": "Enemy: Damage %s | Crit %s | Miss %s",
		"ui.hero_summary": "Hero: Damage %s | Miss %s",
		"ui.on": "ON",
		"ui.off": "OFF",
		"run.title": "Run",
		"run.overview": "Overview",
		"run.wave_record": "Wave Record",
		"run.current_dps": "Current DPS",
		"run.echo_collected": "Echo Collected",
		"run.echo_active": "Echo Active",
		"run.echo": "Echo",
		"run.active_bonus": "Active Bonus",
		"run.after_death_bonus": "After Death Bonus",
		"run.hero_stats": "Hero Stats (Current Run)",
		"stat.damage": "Damage",
		"stat.attack_speed": "Attack Speed",
		"stat.dps": "DPS",
		"stat.max_hp": "Max HP",
		"stat.crit_chance": "Crit Chance",
		"stat.crit_mult": "Crit Mult",
		"stat.defense": "Defense",
		"stat.evasion": "Evasion",
		"stat.accuracy": "Accuracy",
		"abilities.permanent_slots": "permanent skill slots",
		"abilities.unlocks": "Unlocks at mastery 1 / 4 / 5",
		"abilities.equipped": "Equipped:",
		"abilities.slot": "Slot",
		"abilities.locked": "Locked",
		"abilities.locked_wave": "Locked until wave",
		"abilities.empty": "Empty",
		"abilities.tap_set": "Tap to set",
		"abilities.tap_clear": "Tap to clear",
		"abilities.available": "Available",
		"abilities.selected": "Selected",
		"abilities.state_need_wave_slot": "Need wave %d slot",
		"abilities.state_equipped": "Equipped",
		"abilities.state_available": "Available",
		"abilities.state_select_replace": "Select To Replace",
	},
}

var bonus_damage: float = 0.0
var bonus_max_hp: float = 0.0
var bonus_attack_speed: float = 0.0
var bonus_crit_chance: float = 0.0
var bonus_crit_multiplier: float = 0.0
var bonus_defense: float = 0.0
var bonus_evasion: float = 0.0
var bonus_accuracy: float = 0.0
var artifact_bonus_block_chance: float = 0.0
var artifact_bonus_reflect_chance: float = 0.0
var artifact_bonus_reflect_ratio: float = 0.0
var artifact_bonus_haste_chance: float = 0.0
var artifact_bonus_haste_duration: float = 0.0
var artifact_bonus_repeat_chance: float = 0.0
var artifact_bonus_teleport_chance: float = 0.0
var artifact_bonus_clone_chance: float = 0.0
var artifact_bonus_clone_duration: float = 0.0
var artifact_bonus_clone_stat_multiplier: float = 0.0
var artifact_bonus_skill_damage_mult: float = 0.0
var artifact_bonus_skill_proc_mult: float = 0.0

const EQUIPMENT_ORDER: Array[StringName] = [&"weapon", &"helm", &"chest", &"gloves", &"boots", &"ring", &"amulet", &"relic"]
const EQUIPMENT_DEFS := {
	&"weapon": {"name": "Weapon", "base_cost": 50, "cost_scale": 1.12},
	&"helm": {"name": "Helm", "base_cost": 40, "cost_scale": 1.11},
	&"chest": {"name": "Chest", "base_cost": 55, "cost_scale": 1.12},
	&"gloves": {"name": "Gloves", "base_cost": 42, "cost_scale": 1.11},
	&"boots": {"name": "Boots", "base_cost": 42, "cost_scale": 1.11},
	&"ring": {"name": "Ring", "base_cost": 48, "cost_scale": 1.115},
	&"amulet": {"name": "Amulet", "base_cost": 50, "cost_scale": 1.115},
	&"relic": {"name": "Relic", "base_cost": 60, "cost_scale": 1.12},
}
const EQUIPMENT_UNLOCK_COSTS := {
	&"helm": 2500,
	&"chest": 12000,
	&"gloves": 40000,
	&"boots": 100000,
	&"ring": 220000,
	&"amulet": 450000,
	&"relic": 900000,
}
const ARTIFACT_POOL: Array[StringName] = [
	&"ember_heart", &"crystal_lung", &"warhorn_shard", &"stone_eye", &"storm_compass",
	&"iron_leaf", &"moon_pin", &"glass_tooth", &"sun_thread", &"warden_coin",
	&"ashen_tome", &"tide_knot", &"gale_lock", &"thunder_nail", &"cinder_seal",
	&"deep_scale", &"oak_charm", &"spark_relic", &"frost_sigil", &"void_feather",
]
const ARTIFACT_EFFECTS := {
	&"ember_heart": {"stat": "damage", "coef": 0.9, "label": "damage"},
	&"crystal_lung": {"stat": "max_hp", "coef": 7.0, "label": "HP"},
	&"warhorn_shard": {"stat": "attack_speed", "coef": 0.01, "label": "attack speed"},
	&"stone_eye": {"stat": "accuracy", "coef": 0.6, "label": "accuracy"},
	&"storm_compass": {"stat": "crit_chance", "coef": 0.0018, "label": "crit chance", "percent": true},
	&"iron_leaf": {"stat": "crit_multiplier", "coef": 0.012, "label": "crit multiplier"},
	&"moon_pin": {"stat": "defense", "coef": 0.22, "label": "defense"},
	&"glass_tooth": {"stat": "evasion", "coef": 0.22, "label": "evasion"},
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
}

var upgrade_levels: Dictionary = {
	UPGRADE_DAMAGE: 0,
	UPGRADE_ATTACK_SPEED: 0,
	UPGRADE_CRIT_CHANCE: 0,
	UPGRADE_CRIT_MULTIPLIER: 0,
}

var upgrade_definitions: Dictionary = {
	UPGRADE_DAMAGE: {
		"name": "Damage",
		"base_cost": 20,
		"cost_scale": 1.35,
		"value_per_level": 1.5,
	},
	UPGRADE_ATTACK_SPEED: {
		"name": "Attack Speed",
		"base_cost": 25,
		"cost_scale": 1.4,
		"value_per_level": 0.04,
	},
	UPGRADE_CRIT_CHANCE: {
		"name": "Crit Chance",
		"base_cost": 30,
		"cost_scale": 1.45,
		"value_per_level": 0.0075,
	},
	UPGRADE_CRIT_MULTIPLIER: {
		"name": "Crit Mult",
		"base_cost": 40,
		"cost_scale": 1.5,
		"value_per_level": 0.05,
	},
}

func _ready() -> void:
	set_process(true)
	for school_id: StringName in SchoolRules.SCHOOL_ORDER:
		school_mastery_xp[school_id] = 0
	for equipment_id in EQUIPMENT_ORDER:
		equipment_levels[equipment_id] = 0
		equipment_unlocked[equipment_id] = equipment_id == &"weapon"
	for artifact_id in ARTIFACT_POOL:
		artifact_levels[artifact_id] = 0
	for skill_id_variant in SchoolRules.SKILL_DEFINITIONS.keys():
		var skill_id := skill_id_variant as StringName
		skill_upgrade_levels[skill_id] = {"dmg": 0, "cd": 0, "proc": 0}
	SignalBus.wave_changed.connect(_on_wave_changed)
	_rebuild_all_bonuses()
	_rebuild_school_state()

func _process(delta: float) -> void:
	repeat_action_icd_left = maxf(0.0, repeat_action_icd_left - delta)
	teleport_icd_left = maxf(0.0, teleport_icd_left - delta)
	haste_icd_left = maxf(0.0, haste_icd_left - delta)
	clone_icd_left = maxf(0.0, clone_icd_left - delta)
	haste_buff_time_left = maxf(0.0, haste_buff_time_left - delta)
	clone_buff_time_left = maxf(0.0, clone_buff_time_left - delta)

func add_gold(value: int) -> void:
	gold += value
	resources_changed.emit(gold, essence)

func add_essence(value: int) -> void:
	essence += value
	resources_changed.emit(gold, essence)

func add_echo(value: int) -> void:
	echo_collected += value
	echo_changed.emit(echo_collected, echo_power)

func register_run_death(run_time_sec: float) -> void:
	total_deaths += 1
	if run_time_sec > best_run_time_sec:
		best_run_time_sec = run_time_sec
	upgrades_changed.emit()

func format_duration_short(seconds: float) -> String:
	var total: int = maxi(0, int(floor(seconds)))
	var mins: int = total / 60
	var secs: int = total % 60
	return "%02d:%02d" % [mins, secs]

func build_hero_stats() -> CombatStats:
	var stats := CombatStats.new()
	stats.max_hp = GameConstants.HERO_BASE_HP + bonus_max_hp + get_active_echo_hp_bonus()
	stats.damage = GameConstants.HERO_BASE_DAMAGE + bonus_damage + get_active_echo_damage_bonus()
	stats.attack_speed = GameConstants.HERO_BASE_ATTACK_SPEED + bonus_attack_speed + get_active_echo_attack_speed_bonus()
	stats.crit_chance = clampf(
		GameConstants.HERO_BASE_CRIT_CHANCE + bonus_crit_chance + get_active_echo_crit_chance_bonus(),
		0.0,
		GameConstants.HERO_MAX_CRIT_CHANCE
	)
	stats.crit_multiplier = clampf(
		GameConstants.HERO_BASE_CRIT_MULTIPLIER + bonus_crit_multiplier + get_active_echo_crit_multiplier_bonus(),
		1.0,
		GameConstants.HERO_MAX_CRIT_MULTIPLIER
	)
	stats.defense = GameConstants.HERO_BASE_DEFENSE + bonus_defense + get_active_echo_defense_bonus()
	stats.evasion = GameConstants.HERO_BASE_EVASION + bonus_evasion + get_active_echo_evasion_bonus()
	stats.accuracy = GameConstants.HERO_BASE_ACCURACY + bonus_accuracy + get_active_echo_accuracy_bonus()
	return stats

func get_hero_dps() -> float:
	return build_hero_stats().compute_dps()

func get_school_ids() -> Array[StringName]:
	return SchoolRules.SCHOOL_ORDER.duplicate()

func get_school_definition(school_id: StringName) -> Dictionary:
	return SchoolRules.SCHOOL_DEFINITIONS.get(school_id, {})

func get_active_school_summary() -> Dictionary:
	var definition := get_school_definition(active_school)
	var mastery_level := get_school_mastery_level(active_school)
	var mastery_xp := get_school_mastery_xp(active_school)
	return {
		"id": active_school,
		"name": String(definition.get("name", "Unknown")),
		"core_label": String(definition.get("core_label", "Staff")),
		"mastery_level": mastery_level,
		"mastery_xp": mastery_xp,
		"current_level_floor_xp": SchoolRules.get_current_level_floor_xp(mastery_level),
		"next_level_xp": SchoolRules.get_next_level_xp(mastery_level),
	}

func get_school_mastery_xp(school_id: StringName) -> int:
	return int(school_mastery_xp.get(school_id, 0))

func get_school_mastery_level(school_id: StringName) -> int:
	return SchoolRules.get_total_mastery_level_from_xp(get_school_mastery_xp(school_id))

func get_school_core_mastery_level(school_id: StringName) -> int:
	return SchoolRules.get_core_mastery_level_from_xp(get_school_mastery_xp(school_id))

func get_school_mastery_skill_bonuses(school_id: StringName) -> Dictionary:
	var level: int = get_school_core_mastery_level(school_id)
	var damage_bonus: float = 0.0
	var cooldown_reduction: float = 0.0
	var proc_bonus: float = 0.0
	var unique_bonus_text: String = ""

	if level >= 2:
		damage_bonus += 0.04
	if level >= 3:
		cooldown_reduction += 0.03
	if level >= 6:
		proc_bonus += 0.08
	if level >= 7:
		cooldown_reduction += 0.05
	if level >= 8:
		damage_bonus += 0.10
	if level >= 9:
		cooldown_reduction += 0.05
	if level >= 10:
		match school_id:
			SchoolRules.SCHOOL_FIRE:
				proc_bonus += 0.10
				unique_bonus_text = "Усиление горения"
			SchoolRules.SCHOOL_WATER:
				proc_bonus += 0.08
				unique_bonus_text = "Усиление заморозки"
			SchoolRules.SCHOOL_EARTH:
				damage_bonus += 0.12
				unique_bonus_text = "Пробитие брони"
			SchoolRules.SCHOOL_AIR:
				cooldown_reduction += 0.08
				unique_bonus_text = "Темп воздушных навыков"
			SchoolRules.SCHOOL_LIGHTNING:
				proc_bonus += 0.12
				unique_bonus_text = "Усиление цепного разряда"

	if level > 10:
		var post_levels: int = level - 10
		var first_chunk: int = mini(post_levels, 60)
		var overflow: int = maxi(0, post_levels - 60)
		var effective_post: float = float(first_chunk) + float(overflow) * 0.5
		damage_bonus += effective_post * 0.015
		proc_bonus += effective_post * 0.01

	return {
		"damage_bonus": damage_bonus,
		"cooldown_reduction": cooldown_reduction,
		"proc_bonus": proc_bonus,
		"unique_bonus_text": unique_bonus_text,
	}

func add_active_school_mastery_xp(value: int) -> void:
	var old_core_level := get_school_core_mastery_level(active_school)
	var old_total_level := get_school_mastery_level(active_school)
	school_mastery_xp[active_school] = get_school_mastery_xp(active_school) + value
	var new_core_level := get_school_core_mastery_level(active_school)
	var new_total_level := get_school_mastery_level(active_school)
	if new_core_level != old_core_level or new_total_level != old_total_level:
		_rebuild_school_state()
		return
	school_mastery_changed.emit()

func get_mastery_xp_for_enemy(boss_kind: StringName) -> int:
	match boss_kind:
		&"wave":
			return 10
		&"mini":
			return 25
		&"grand":
			return 60
		&"apex":
			return 140
		_:
			return 0

func set_active_school(school_id: StringName) -> void:
	if not SchoolRules.SCHOOL_DEFINITIONS.has(school_id):
		return
	active_school = school_id
	_rebuild_school_state()

func get_permanent_skill_slot_count() -> int:
	if GameConstants.DEV_UNLOCK_ALL_SKILLS:
		return 4
	return SchoolRules.get_skill_slot_count_for_highest_wave(highest_wave_reached)

func get_available_skill_ids() -> Array[StringName]:
	var available: Array[StringName] = []
	var active_school_skills: Array = get_school_definition(active_school).get("skills", [])
	for skill_id_variant in active_school_skills:
		var skill_id := skill_id_variant as StringName
		if _is_skill_unlocked_for_active_school(skill_id):
			available.append(skill_id)

	for skill_id in unlocked_global_skill_ids:
		if not available.has(skill_id):
			available.append(skill_id)

	return available

func get_equipped_skill_ids() -> Array[StringName]:
	return equipped_skill_ids.duplicate()

func equip_skill(slot_index: int, skill_id: StringName) -> bool:
	if slot_index < 0 or slot_index >= get_permanent_skill_slot_count():
		return false
	if not get_available_skill_ids().has(skill_id):
		return false
	while equipped_skill_ids.size() < get_permanent_skill_slot_count():
		equipped_skill_ids.append(&"")
	equipped_skill_ids[slot_index] = skill_id
	school_state_changed.emit()
	return true

func equip_skill_to_first_open_slot(skill_id: StringName) -> bool:
	for slot_index in range(get_permanent_skill_slot_count()):
		if slot_index >= equipped_skill_ids.size():
			return equip_skill(slot_index, skill_id)
		if equipped_skill_ids[slot_index] == &"":
			return equip_skill(slot_index, skill_id)
	return false

func clear_skill_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= get_permanent_skill_slot_count():
		return false
	if slot_index >= equipped_skill_ids.size():
		return false
	equipped_skill_ids[slot_index] = &""
	school_state_changed.emit()
	return true

func replace_skill(slot_index: int, skill_id: StringName) -> bool:
	if slot_index < 0 or slot_index >= get_permanent_skill_slot_count():
		return false
	if not get_available_skill_ids().has(skill_id):
		return false
	while equipped_skill_ids.size() < get_permanent_skill_slot_count():
		equipped_skill_ids.append(&"")
	equipped_skill_ids[slot_index] = skill_id
	school_state_changed.emit()
	return true

func get_available_skill_ui_data() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var has_open_slot := false
	var slot_count := get_permanent_skill_slot_count()
	for slot_index in range(get_permanent_skill_slot_count()):
		if slot_index >= equipped_skill_ids.size() or equipped_skill_ids[slot_index] == &"":
			has_open_slot = true
			break
	for skill_id in get_available_skill_ids():
		var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
		var equipped := equipped_skill_ids.has(skill_id)
		var unlock_level := int(skill_data.get("unlock_level", 0))
		var can_equip := equipped or slot_count > 0
		var state_text := loc("abilities.state_need_wave_slot") % SchoolRules.SLOT_WAVE_UNLOCKS[0]
		var state_key := "abilities.state_need_wave_slot"
		if equipped:
			state_text = loc("abilities.state_equipped")
			state_key = "abilities.state_equipped"
		elif slot_count > 0 and has_open_slot:
			state_text = loc("abilities.state_available")
			state_key = "abilities.state_available"
		elif slot_count > 0:
			state_text = loc("abilities.state_select_replace")
			state_key = "abilities.state_select_replace"
		rows.append({
			"id": skill_id,
			"name": String(skill_data.get("name", skill_id)),
			"equipped": equipped,
			"can_equip": can_equip,
			"unlock_level": unlock_level,
			"state_text": state_text,
			"state_key": state_key,
		})
	return rows

func get_ability_panel_rows() -> Array[String]:
	var rows: Array[String] = []
	var slot_count := get_permanent_skill_slot_count()
	rows.append("Unlocks at mastery 1 / 4 / 5")
	rows.append("Equipped:")
	for slot_index in range(4):
		var slot_label := "Locked"
		if slot_index < slot_count:
			var equipped_skill_id: StringName = &""
			if slot_index < equipped_skill_ids.size():
				equipped_skill_id = equipped_skill_ids[slot_index]
			slot_label = "Empty"
			if equipped_skill_id != &"":
				var equipped_skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(equipped_skill_id, {})
				slot_label = String(equipped_skill_data.get("name", equipped_skill_id))
		rows.append("Slot %d: %s" % [slot_index + 1, slot_label])

	return rows

func activate_collected_echo() -> void:
	if echo_collected <= 0:
		return
	echo_power += echo_collected
	echo_collected = 0
	echo_changed.emit(echo_collected, echo_power)
	hero_stats_changed.emit()

func get_echo_tier_bonuses(echo_value: int) -> Dictionary:
	var total_echo: float = maxf(0.0, float(echo_value))
	var out := {
		"damage": 0.0,
		"max_hp": 0.0,
		"attack_speed": 0.0,
		"crit_chance": 0.0,
		"crit_multiplier": 0.0,
		"defense": 0.0,
		"evasion": 0.0,
		"accuracy": 0.0,
	}
	for tier_any in GameConstants.ECHO_TIERS:
		var tier: Dictionary = tier_any
		var start: int = int(tier.get("start", 0))
		if total_echo <= float(start):
			continue
		var step: float = float(tier.get("step", 1.0))
		if step <= 0.0:
			continue
		var next_start: int = 2147483647
		var idx: int = GameConstants.ECHO_TIERS.find(tier_any)
		if idx >= 0 and idx + 1 < GameConstants.ECHO_TIERS.size():
			next_start = int((GameConstants.ECHO_TIERS[idx + 1] as Dictionary).get("start", 2147483647))
		var tier_end: float = float(next_start) if idx + 1 < GameConstants.ECHO_TIERS.size() else total_echo
		var tier_echo: float = maxf(0.0, minf(total_echo, tier_end) - float(start))
		var ticks: float = floor(tier_echo / step)
		if ticks <= 0.0:
			continue
		var bonuses: Dictionary = tier.get("bonuses", {})
		for stat in bonuses.keys():
			var key: String = String(stat)
			if not out.has(key):
				continue
			out[key] = float(out[key]) + float(bonuses[stat]) * ticks
	return out

func get_echo_progress_info(echo_value: int) -> Dictionary:
	var value: int = maxi(0, echo_value)
	var tiers: Array[Dictionary] = GameConstants.ECHO_TIERS
	if tiers.is_empty():
		return {
			"current_step": 0,
			"next_step": 0,
			"required_echo": value,
			"remaining_to_next": 0,
		}

	var current_idx: int = 0
	for i in range(tiers.size()):
		var start_i: int = int((tiers[i] as Dictionary).get("start", 0))
		if start_i <= value:
			current_idx = i
		else:
			break

	var current_tier: Dictionary = tiers[current_idx] as Dictionary
	var current_step: int = int(round(float(current_tier.get("step", 0.0))))
	var next_target: int = 2147483647
	var next_step: int = 0

	for i in range(tiers.size()):
		var tier: Dictionary = tiers[i] as Dictionary
		var start: int = int(tier.get("start", 0))
		var step_f: float = float(tier.get("step", 0.0))
		if step_f <= 0.0:
			continue
		var step_i: int = int(round(step_f))
		if step_i <= 0:
			continue
		var next_start: int = 2147483647
		if i + 1 < tiers.size():
			next_start = int((tiers[i + 1] as Dictionary).get("start", 2147483647))

		var candidate: int = 2147483647
		if value < start:
			candidate = start + step_i
		else:
			var ticks_now: int = int(floor(float(value - start) / step_f))
			candidate = start + (ticks_now + 1) * step_i
			if next_start < 2147483647 and candidate > next_start:
				candidate = start + ((ticks_now + 2) * step_i)
		if next_start < 2147483647 and candidate > next_start:
			continue
		if candidate > value and candidate < next_target:
			next_target = candidate
			next_step = step_i

	if next_target == 2147483647:
		next_target = value

	return {
		"current_step": current_step,
		"next_step": next_step if next_step > 0 else current_step,
		"required_echo": next_target,
		"remaining_to_next": maxi(0, next_target - value),
	}

func get_active_echo_damage_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_power).get("damage", 0.0))

func get_active_echo_hp_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_power).get("max_hp", 0.0))

func get_active_echo_attack_speed_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_power).get("attack_speed", 0.0))

func get_active_echo_crit_chance_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_power).get("crit_chance", 0.0))

func get_active_echo_crit_multiplier_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_power).get("crit_multiplier", 0.0))

func get_active_echo_defense_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_power).get("defense", 0.0))

func get_active_echo_evasion_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_power).get("evasion", 0.0))

func get_active_echo_accuracy_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_power).get("accuracy", 0.0))

func get_collected_echo_damage_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_collected).get("damage", 0.0))

func get_collected_echo_hp_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_collected).get("max_hp", 0.0))

func get_collected_echo_attack_speed_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_collected).get("attack_speed", 0.0))

func get_collected_echo_crit_chance_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_collected).get("crit_chance", 0.0))

func get_collected_echo_crit_multiplier_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_collected).get("crit_multiplier", 0.0))

func get_collected_echo_defense_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_collected).get("defense", 0.0))

func get_collected_echo_evasion_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_collected).get("evasion", 0.0))

func get_collected_echo_accuracy_bonus() -> float:
	return float(get_echo_tier_bonuses(echo_collected).get("accuracy", 0.0))

func get_active_echo_bonus_summary() -> String:
	return "+%.0f hp  +%.1f dmg  +%.2f atk/s  +%.1f def  +%.1f eva  +%.1f acc  +%.2f%% crit  +%.2f critx" % [
		get_active_echo_hp_bonus(),
		get_active_echo_damage_bonus(),
		get_active_echo_attack_speed_bonus(),
		get_active_echo_defense_bonus(),
		get_active_echo_evasion_bonus(),
		get_active_echo_accuracy_bonus(),
		get_active_echo_crit_chance_bonus() * 100.0,
		get_active_echo_crit_multiplier_bonus(),
	]

func get_collected_echo_bonus_summary() -> String:
	return "+%.0f hp  +%.1f dmg  +%.2f atk/s  +%.1f def  +%.1f eva  +%.1f acc  +%.2f%% crit  +%.2f critx after death" % [
		get_collected_echo_hp_bonus(),
		get_collected_echo_damage_bonus(),
		get_collected_echo_attack_speed_bonus(),
		get_collected_echo_defense_bonus(),
		get_collected_echo_evasion_bonus(),
		get_collected_echo_accuracy_bonus(),
		get_collected_echo_crit_chance_bonus() * 100.0,
		get_collected_echo_crit_multiplier_bonus(),
	]

func set_combat_text_settings(show_damage: bool, show_crit: bool, show_miss: bool, show_hero_damage: bool = true, show_hero_miss: bool = true) -> void:
	show_damage_text = show_damage
	show_crit_text = show_crit
	show_miss_text = show_miss
	show_hero_damage_text = show_hero_damage
	show_hero_miss_text = show_hero_miss
	combat_text_settings_changed.emit()

func get_equipment_ids() -> Array[StringName]:
	return EQUIPMENT_ORDER.duplicate()

func is_equipment_unlocked(equipment_id: StringName) -> bool:
	if not EQUIPMENT_ORDER.has(equipment_id):
		return false
	return bool(equipment_unlocked.get(equipment_id, equipment_id == &"weapon"))

func get_equipment_unlock_requirement_text(equipment_id: StringName) -> String:
	return ""

func get_equipment_unlock_progress_text(equipment_id: StringName) -> String:
	return ""

func get_equipment_unlock_cost(equipment_id: StringName) -> int:
	if equipment_id == &"weapon":
		return 0
	return int(EQUIPMENT_UNLOCK_COSTS.get(equipment_id, 0))

func can_unlock_equipment(equipment_id: StringName) -> bool:
	if is_equipment_unlocked(equipment_id):
		return false
	var unlock_cost: int = get_equipment_unlock_cost(equipment_id)
	return unlock_cost > 0 and gold >= unlock_cost

func unlock_equipment(equipment_id: StringName) -> bool:
	if is_equipment_unlocked(equipment_id):
		return false
	var unlock_cost: int = get_equipment_unlock_cost(equipment_id)
	if unlock_cost <= 0 or gold < unlock_cost:
		return false
	gold -= unlock_cost
	equipment_unlocked[equipment_id] = true
	# Unlock purchase grants the first level immediately.
	if int(equipment_levels.get(equipment_id, 0)) <= 0:
		equipment_levels[equipment_id] = 1
		if equipment_id == &"weapon":
			_try_generate_weapon_skill_offers(0, 1)
	_rebuild_all_bonuses()
	resources_changed.emit(gold, essence)
	hero_stats_changed.emit()
	upgrades_changed.emit()
	return true

func get_equipment_display_name(equipment_id: StringName) -> String:
	var is_ru := current_language == &"ru"
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

func get_equipment_effect_summary(equipment_id: StringName) -> String:
	var level: int = get_equipment_level(equipment_id)
	var t100: int = int(floor(float(level) / 100.0))
	var t1000: int = int(floor(float(level) / 1000.0))
	var is_ru := current_language == &"ru"
	match equipment_id:
		&"weapon":
			if is_ru:
				return "Каждые 100 ур: выбор 1 из 3 улучшений навыка. Бонус урона навыков: +%d%%, КД навыков: -%d%%." % [t1000 * 6, t1000 * 2]
			return "Every 100 lv: pick 1 of 3 skill upgrades. Skill damage +%d%%, skill cooldown -%d%%." % [t1000 * 6, t1000 * 2]
		&"helm":
			var block_pct := _get_helm_block_chance() * 100.0
			if is_ru:
				return "Базово: HP и защита. Блок урона: %.2f%%." % block_pct
			return "Base: HP and defense. Block chance: %.2f%%." % block_pct
		&"chest":
			var reflect_chance_pct := _get_chest_reflect_chance() * 100.0
			if is_ru:
				return "Базово: HP и защита. Шанс отражения: %.2f%%." % reflect_chance_pct
			return "Base: HP and defense. Reflect chance: %.2f%%." % reflect_chance_pct
		&"gloves":
			var reflect_ratio_pct := _get_gloves_reflect_ratio() * 100.0
			if is_ru:
				return "Базово: скорость атаки. Сила отражения: %.2f%% входящего урона." % reflect_ratio_pct
			return "Base: attack speed. Reflect power: %.2f%% of incoming damage." % reflect_ratio_pct
		&"boots":
			var haste_pct := _get_boots_haste_chance() * 100.0
			var haste_dur := _get_boots_haste_duration()
			if is_ru:
				return "Базово: уклонение. После получения урона: %.2f%% шанс ускорения x1.5 на %.1fс." % [haste_pct, haste_dur]
			return "Base: evasion. On hit taken: %.2f%% chance for x1.5 haste for %.1fs." % [haste_pct, haste_dur]
		&"ring":
			var repeat_pct := _get_ring_repeat_chance() * 100.0
			if is_ru:
				return "Базово: точность и крит-шанс. Двойное срабатывание атаки/навыка: %.2f%%." % repeat_pct
			return "Base: accuracy and crit chance. Double attack/skill trigger: %.2f%%." % repeat_pct
		&"amulet":
			var teleport_pct := _get_amulet_teleport_chance() * 100.0
			if is_ru:
				return "Базово: урон и крит-множитель. Телепорт при получении урона: %.2f%%." % teleport_pct
			return "Base: damage and crit multiplier. Teleport on hit taken: %.2f%%." % teleport_pct
		&"relic":
			var clone_pct := _get_relic_clone_chance() * 100.0
			var clone_dur := _get_relic_clone_duration()
			var clone_stats := _get_relic_clone_stat_multiplier() * 100.0
			if is_ru:
				return "Базово: точность. Шанс клона: %.2f%%, длительность %.1fс, сила %.0f%% статов." % [clone_pct, clone_dur, clone_stats]
			return "Base: accuracy. Clone chance %.2f%%, duration %.1fs, power %.0f%% stats." % [clone_pct, clone_dur, clone_stats]
		_:
			if is_ru:
				return "Нет описания."
			return "No description."

func get_equipment_current_boost_short(equipment_id: StringName) -> String:
	var t100: int = int(floor(float(get_equipment_level(equipment_id)) / 100.0))
	var t1000: int = int(floor(float(get_equipment_level(equipment_id)) / 1000.0))
	match equipment_id:
		&"weapon":
			return "SKILL +%d%% | CD -%d%%" % [t1000 * 6, t1000 * 2]
		&"helm":
			return "BLOCK %.2f%%" % (_get_helm_block_chance() * 100.0)
		&"chest":
			return "REFLECT %.2f%%" % (_get_chest_reflect_chance() * 100.0)
		&"gloves":
			return "REFLECT DMG %.2f%%" % (_get_gloves_reflect_ratio() * 100.0)
		&"boots":
			return "HASTE %.2f%%" % (_get_boots_haste_chance() * 100.0)
		&"ring":
			return "DOUBLE %.2f%%" % (_get_ring_repeat_chance() * 100.0)
		&"amulet":
			return "TP %.2f%%" % (_get_amulet_teleport_chance() * 100.0)
		&"relic":
			return "CLONE %.2f%%" % (_get_relic_clone_chance() * 100.0)
		_:
			return "T%d" % t100

func get_equipment_base_boost_short(equipment_id: StringName) -> String:
	var level: int = get_equipment_level(equipment_id)
	var is_ru := current_language == &"ru"
	match equipment_id:
		&"weapon":
			var weapon_50: float = floor(float(level) / 50.0)
			var bonus_damage_value: float = level * (0.16 + weapon_50 * 0.0035)
			return ("База: +%.1f урона" % bonus_damage_value) if is_ru else ("Base: +%.1f damage" % bonus_damage_value)
		&"helm":
			var helm_50: float = floor(float(level) / 50.0)
			var hp_bonus: float = level * (0.42 + helm_50 * 0.009)
			var def_bonus: float = level * (0.055 + helm_50 * 0.0012)
			return ("База: +%.0f HP, +%.1f DEF" % [hp_bonus, def_bonus]) if is_ru else ("Base: +%.0f HP, +%.1f DEF" % [hp_bonus, def_bonus])
		&"chest":
			var chest_50: float = floor(float(level) / 50.0)
			var hp_bonus: float = level * (0.74 + chest_50 * 0.012)
			var def_bonus: float = level * (0.095 + chest_50 * 0.0017)
			return ("База: +%.0f HP, +%.1f DEF" % [hp_bonus, def_bonus]) if is_ru else ("Base: +%.0f HP, +%.1f DEF" % [hp_bonus, def_bonus])
		&"gloves":
			var gloves_50: float = floor(float(level) / 50.0)
			var atk_bonus: float = level * (0.0018 + gloves_50 * 0.00004)
			return ("База: +%.2f ATK/s" % atk_bonus) if is_ru else ("Base: +%.2f ATK/s" % atk_bonus)
		&"boots":
			var boots_50: float = floor(float(level) / 50.0)
			var eva_bonus: float = level * (0.034 + boots_50 * 0.0008)
			return ("База: +%.1f EVA" % eva_bonus) if is_ru else ("Base: +%.1f EVA" % eva_bonus)
		&"ring":
			var ring_50: float = floor(float(level) / 50.0)
			var acc_bonus: float = level * (0.06 + ring_50 * 0.0012)
			var crit_bonus: float = level * (0.000002 + ring_50 * 0.00000001) * 100.0
			return ("База: +%.1f ACC, +%.2f%% CRIT" % [acc_bonus, crit_bonus]) if is_ru else ("Base: +%.1f ACC, +%.2f%% CRIT" % [acc_bonus, crit_bonus])
		&"amulet":
			var amulet_50: float = floor(float(level) / 50.0)
			var dmg_bonus: float = level * (0.046 + amulet_50 * 0.0009)
			var critx_bonus: float = level * (0.00009 + amulet_50 * 0.0000003)
			return ("База: +%.1f DMG, +%.2f CRITx" % [dmg_bonus, critx_bonus]) if is_ru else ("Base: +%.1f DMG, +%.2f CRITx" % [dmg_bonus, critx_bonus])
		&"relic":
			var relic_100: float = floor(float(level) / 100.0)
			var relic_1000: float = floor(float(level) / 1000.0)
			var acc_bonus: float = relic_100 * 0.3 + relic_1000 * 10.0
			return ("База: +%.1f ACC" % acc_bonus) if is_ru else ("Base: +%.1f ACC" % acc_bonus)
		_:
			return ""

func get_equipment_proc_boost_short(equipment_id: StringName) -> String:
	var is_ru := current_language == &"ru"
	match equipment_id:
		&"weapon":
			var t1000: int = int(floor(float(get_equipment_level(&"weapon")) / 1000.0))
			return ("Перк: +%d%% урон навыков, -%d%% КД" % [t1000 * 6, t1000 * 2]) if is_ru else ("Perk: +%d%% skill dmg, -%d%% cd" % [t1000 * 6, t1000 * 2])
		&"helm":
			return ("Перк: +%.2f%% блок" % (_get_helm_block_chance() * 100.0)) if is_ru else ("Perk: +%.2f%% block" % (_get_helm_block_chance() * 100.0))
		&"chest":
			return ("Перк: +%.2f%% шанс отраж." % (_get_chest_reflect_chance() * 100.0)) if is_ru else ("Perk: +%.2f%% reflect chance" % (_get_chest_reflect_chance() * 100.0))
		&"gloves":
			return ("Перк: +%.2f%% сила отраж." % (_get_gloves_reflect_ratio() * 100.0)) if is_ru else ("Perk: +%.2f%% reflect power" % (_get_gloves_reflect_ratio() * 100.0))
		&"boots":
			return ("Перк: +%.2f%% ускорение" % (_get_boots_haste_chance() * 100.0)) if is_ru else ("Perk: +%.2f%% haste" % (_get_boots_haste_chance() * 100.0))
		&"ring":
			return ("Перк: +%.2f%% двойной" % (_get_ring_repeat_chance() * 100.0)) if is_ru else ("Perk: +%.2f%% double" % (_get_ring_repeat_chance() * 100.0))
		&"amulet":
			return ("Перк: +%.2f%% телепорт" % (_get_amulet_teleport_chance() * 100.0)) if is_ru else ("Perk: +%.2f%% teleport" % (_get_amulet_teleport_chance() * 100.0))
		&"relic":
			return ("Перк: +%.2f%% клон" % (_get_relic_clone_chance() * 100.0)) if is_ru else ("Perk: +%.2f%% clone" % (_get_relic_clone_chance() * 100.0))
		_:
			return ""

func get_equipment_next_perk_upgrade_text(equipment_id: StringName) -> String:
	var is_ru: bool = current_language == &"ru"
	var level: int = get_equipment_level(equipment_id)
	var step: int = 100
	if equipment_id == &"weapon":
		step = 1000
	var next_level: int = ((level / step) + 1) * step
	if next_level <= level:
		next_level += step
	return ("Откроется на %d ур." % next_level) if is_ru else ("Unlocks at Lv.%d" % next_level)

func get_equipment_level(equipment_id: StringName) -> int:
	return int(equipment_levels.get(equipment_id, 0))

func get_equipment_upgrade_cost(equipment_id: StringName) -> int:
	var def: Dictionary = EQUIPMENT_DEFS.get(equipment_id, {})
	var base_cost: float = float(def.get("base_cost", 50))
	var level: int = get_equipment_level(equipment_id)
	var idx: int = EQUIPMENT_ORDER.find(equipment_id)
	if idx <= 0:
		return _compute_progressive_equipment_cost(base_cost, level)

	# Unlocks are now gold-based, so upgrade entry cost should scale from unlock price
	# instead of legacy level-threshold anchors.
	var unlock_cost: int = get_equipment_unlock_cost(equipment_id)
	var anchor_cost: float = maxf(base_cost, float(unlock_cost) * 0.30)
	return _compute_progressive_equipment_cost(anchor_cost, level)

func _get_equipment_unlock_threshold_by_index(idx: int) -> int:
	if idx == 1:
		return 100
	if idx == 2:
		return 500
	return 1000

func _get_equipment_anchor_cost_by_index(idx: int) -> float:
	var weapon_base: float = float(EQUIPMENT_DEFS[&"weapon"].get("base_cost", 50))
	var anchor: float = weapon_base
	for i in range(1, idx + 1):
		var threshold: int = _get_equipment_unlock_threshold_by_index(i)
		anchor = float(_compute_progressive_equipment_cost(anchor, threshold))
	return anchor

func _compute_progressive_equipment_cost(base_cost: float, effective_level: int) -> int:
	# Piecewise growth for infinite mode:
	# phase 1: fast but controllable
	# phase 2: medium
	# phase 3: long-tail
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

func buy_equipment_upgrade(equipment_id: StringName) -> bool:
	if not EQUIPMENT_DEFS.has(equipment_id):
		return false
	if not is_equipment_unlocked(equipment_id):
		return false
	var previous_level := get_equipment_level(equipment_id)
	var cost := get_equipment_upgrade_cost(equipment_id)
	if gold < cost:
		return false
	gold -= cost
	equipment_levels[equipment_id] = previous_level + 1
	if equipment_id == &"weapon":
		_try_generate_weapon_skill_offers(previous_level, previous_level + 1)
	_rebuild_all_bonuses()
	resources_changed.emit(gold, essence)
	hero_stats_changed.emit()
	upgrades_changed.emit()
	return true

func get_artifact_upgrade_cost(artifact_id: StringName) -> int:
	var level := int(artifact_levels.get(artifact_id, 0))
	return 35 + level * 20

func buy_artifact_upgrade(artifact_id: StringName) -> bool:
	if not owned_artifacts.has(artifact_id):
		return false
	var cost := get_artifact_upgrade_cost(artifact_id)
	if essence < cost:
		return false
	essence -= cost
	artifact_levels[artifact_id] = int(artifact_levels.get(artifact_id, 0)) + 1
	_rebuild_all_bonuses()
	resources_changed.emit(gold, essence)
	hero_stats_changed.emit()
	upgrades_changed.emit()
	return true

func get_artifact_ui_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for artifact_id in ARTIFACT_POOL:
		var owned := owned_artifacts.has(artifact_id)
		rows.append({
			"id": artifact_id,
			"name": get_artifact_display_name(artifact_id),
			"owned": owned,
			"level": int(artifact_levels.get(artifact_id, 0)),
			"cost": get_artifact_upgrade_cost(artifact_id),
			"affordable": owned and essence >= get_artifact_upgrade_cost(artifact_id),
		})
	return rows

func get_artifact_display_name(artifact_id: StringName) -> String:
	match artifact_id:
		&"ember_heart":
			return "Ember Heart"
		&"crystal_lung":
			return "Crystal Lung"
		&"warhorn_shard":
			return "Warhorn Shard"
		&"stone_eye":
			return "Stone Eye"
		_:
			return String(artifact_id).replace("_", " ").capitalize()

func get_artifact_effect_summary(artifact_id: StringName) -> String:
	var level: int = int(artifact_levels.get(artifact_id, 0))
	return _format_artifact_effect_summary(artifact_id, level)

func register_apex_boss_kill(wave_number: int) -> void:
	if wave_number % 100 != 0:
		return
	if defeated_apex_wave_rewards.has(wave_number):
		return
	defeated_apex_wave_rewards.append(wave_number)
	_grant_random_artifact()
	upgrades_changed.emit()

func _grant_random_artifact() -> void:
	if ARTIFACT_POOL.is_empty():
		return
	var granted := ARTIFACT_POOL[randi_range(0, ARTIFACT_POOL.size() - 1)]
	if not owned_artifacts.has(granted):
		owned_artifacts.append(granted)
	artifact_levels[granted] = int(artifact_levels.get(granted, 0)) + 1
	_rebuild_all_bonuses()
	hero_stats_changed.emit()

func should_block_incoming_hit() -> bool:
	var chance := _get_helm_block_chance()
	return randf() < chance

func get_reflect_chance() -> float:
	return _get_chest_reflect_chance()

func get_reflect_ratio() -> float:
	return _get_gloves_reflect_ratio()

func should_trigger_repeat_action() -> bool:
	if repeat_action_icd_left > 0.0:
		return false
	if randf() < _get_ring_repeat_chance():
		repeat_action_icd_left = 1.5
		return true
	return false

func get_runtime_attack_speed_multiplier() -> float:
	return 1.5 if haste_buff_time_left > 0.0 else 1.0

func get_clone_attack_multiplier() -> float:
	return clone_stat_multiplier if clone_buff_time_left > 0.0 else 0.0

func on_hero_damaged(hero: Node2D, attacker: Enemy, damage_taken: float) -> void:
	if hero == null:
		return
	if randf() < _get_boots_haste_chance() and haste_icd_left <= 0.0:
		haste_icd_left = 4.0
		haste_buff_time_left = maxf(haste_buff_time_left, _get_boots_haste_duration())
	if randf() < _get_amulet_teleport_chance() and teleport_icd_left <= 0.0:
		teleport_icd_left = 8.0
		hero.global_position = _find_safe_teleport_position(hero.global_position)
	if randf() < _get_relic_clone_chance() and clone_icd_left <= 0.0:
		clone_icd_left = 8.0
		clone_buff_time_left = maxf(clone_buff_time_left, _get_relic_clone_duration())
		clone_stat_multiplier = maxf(clone_stat_multiplier, _get_relic_clone_stat_multiplier())
	if attacker != null and is_instance_valid(attacker) and randf() < _get_chest_reflect_chance():
		attacker.take_damage(damage_taken * _get_gloves_reflect_ratio())

func get_skill_damage_multiplier(skill_id: StringName) -> float:
	var weapon_level: int = get_equipment_level(&"weapon")
	var milestone_1000: float = floor(float(weapon_level) / 1000.0)
	var skill_data: Dictionary = skill_upgrade_levels.get(skill_id, {"dmg": 0, "cd": 0, "proc": 0})
	var dmg_upgrades: int = int(skill_data.get("dmg", 0))
	var skill_school: StringName = SchoolRules.SCHOOL_FIRE
	if SchoolRules.SKILL_DEFINITIONS.has(skill_id):
		skill_school = SchoolRules.SKILL_DEFINITIONS[skill_id].get("school", SchoolRules.SCHOOL_FIRE) as StringName
	var school_bonus: Dictionary = get_school_mastery_skill_bonuses(skill_school)
	var base_mult: float = 1.0 + milestone_1000 * 0.06 + dmg_upgrades * 0.04 + artifact_bonus_skill_damage_mult
	return base_mult * (1.0 + float(school_bonus.get("damage_bonus", 0.0)))

func get_skill_cooldown_multiplier(skill_id: StringName) -> float:
	var weapon_level: int = get_equipment_level(&"weapon")
	var milestone_1000: float = floor(float(weapon_level) / 1000.0)
	var skill_data: Dictionary = skill_upgrade_levels.get(skill_id, {"dmg": 0, "cd": 0, "proc": 0})
	var cd_upgrades: int = int(skill_data.get("cd", 0))
	var skill_school: StringName = SchoolRules.SCHOOL_FIRE
	if SchoolRules.SKILL_DEFINITIONS.has(skill_id):
		skill_school = SchoolRules.SKILL_DEFINITIONS[skill_id].get("school", SchoolRules.SCHOOL_FIRE) as StringName
	var school_bonus: Dictionary = get_school_mastery_skill_bonuses(skill_school)
	var base_cd: float = maxf(0.5, 1.0 - milestone_1000 * 0.02 - cd_upgrades * 0.03)
	var school_reduction: float = clampf(float(school_bonus.get("cooldown_reduction", 0.0)), 0.0, 0.35)
	return maxf(0.35, base_cd * (1.0 - school_reduction))

func get_skill_proc_multiplier(skill_id: StringName) -> float:
	var skill_data: Dictionary = skill_upgrade_levels.get(skill_id, {"dmg": 0, "cd": 0, "proc": 0})
	var proc_upgrades: int = int(skill_data.get("proc", 0))
	var skill_school: StringName = SchoolRules.SCHOOL_FIRE
	if SchoolRules.SKILL_DEFINITIONS.has(skill_id):
		skill_school = SchoolRules.SKILL_DEFINITIONS[skill_id].get("school", SchoolRules.SCHOOL_FIRE) as StringName
	var school_bonus: Dictionary = get_school_mastery_skill_bonuses(skill_school)
	var base_proc: float = 1.0 + proc_upgrades * 0.05 + artifact_bonus_skill_proc_mult
	return base_proc * (1.0 + float(school_bonus.get("proc_bonus", 0.0)))

func get_pending_weapon_skill_offers() -> Array[Dictionary]:
	return pending_weapon_skill_offers.duplicate(true)

func apply_weapon_skill_offer(offer_index: int) -> bool:
	if offer_index < 0 or offer_index >= pending_weapon_skill_offers.size():
		return false
	var offer: Dictionary = pending_weapon_skill_offers[offer_index]
	var skill_id: StringName = offer.get("skill_id", &"") as StringName
	var kind: String = String(offer.get("kind", ""))
	if skill_id == &"" or kind.is_empty():
		return false
	var data: Dictionary = skill_upgrade_levels.get(skill_id, {"dmg": 0, "cd": 0, "proc": 0})
	data[kind] = int(data.get(kind, 0)) + 1
	skill_upgrade_levels[skill_id] = data
	pending_weapon_skill_offers.clear()
	_rebuild_all_bonuses()
	hero_stats_changed.emit()
	upgrades_changed.emit()
	return true

func set_language(language_code: StringName) -> void:
	if not TRANSLATIONS.has(language_code):
		return
	if current_language == language_code:
		return
	current_language = language_code
	language_changed.emit()

func loc(key: String) -> String:
	var lang_data: Dictionary = TRANSLATIONS.get(current_language, TRANSLATIONS[&"ru"])
	return String(lang_data.get(key, key))

func get_echo_gain_for_enemy(boss_kind: StringName, wave_number: int = -1) -> int:
	var wave: int = wave_number if wave_number > 0 else highest_wave_reached
	var wave_offset: int = maxi(0, wave - 1)
	var reward_curve: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_REWARD_EARLY,
		GameConstants.BALANCE_WAVE_REWARD_MID,
		GameConstants.BALANCE_WAVE_REWARD_LATE
	)
	var reward_multiplier: float = pow(reward_curve, GameConstants.ECHO_REWARD_WAVE_EXPONENT)
	var kind_multiplier: float = 1.0
	match boss_kind:
		&"wave":
			kind_multiplier = 1.6
		&"mini":
			kind_multiplier = 3.2
		&"grand":
			kind_multiplier = 5.5
		&"apex":
			kind_multiplier = 9.0
		_:
			kind_multiplier = 1.0
	var raw: float = reward_multiplier * kind_multiplier * 0.42
	return maxi(1, int(round(raw)))

func get_upgrade_ids() -> Array[StringName]:
	return []

func get_upgrade_level(upgrade_id: StringName) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))

func get_upgrade_cost(upgrade_id: StringName) -> int:
	var definition: Dictionary = upgrade_definitions.get(upgrade_id, {})
	var base_cost: int = int(definition.get("base_cost", 10))
	var cost_scale: float = float(definition.get("cost_scale", 1.25))
	var level := get_upgrade_level(upgrade_id)
	return int(round(base_cost * pow(cost_scale, level)))

func can_buy_upgrade(upgrade_id: StringName) -> bool:
	return gold >= get_upgrade_cost(upgrade_id)

func buy_upgrade(upgrade_id: StringName) -> bool:
	if not upgrade_definitions.has(upgrade_id):
		return false
	if not can_buy_upgrade(upgrade_id):
		return false

	gold -= get_upgrade_cost(upgrade_id)
	upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	_apply_upgrade_bonuses()
	resources_changed.emit(gold, essence)
	hero_stats_changed.emit()
	upgrades_changed.emit()
	return true

func get_upgrade_ui_data(upgrade_id: StringName) -> Dictionary:
	var definition: Dictionary = upgrade_definitions.get(upgrade_id, {})
	return {
		"id": upgrade_id,
		"name": String(definition.get("name", "Upgrade")),
		"level": get_upgrade_level(upgrade_id),
		"cost": get_upgrade_cost(upgrade_id),
		"affordable": can_buy_upgrade(upgrade_id),
		"next_bonus_text": _build_upgrade_bonus_text(upgrade_id),
	}

func _build_upgrade_bonus_text(upgrade_id: StringName) -> String:
	var definition: Dictionary = upgrade_definitions.get(upgrade_id, {})
	var value_per_level: float = float(definition.get("value_per_level", 0.0))

	match upgrade_id:
		UPGRADE_DAMAGE:
			return "+%.0f damage" % value_per_level
		UPGRADE_ATTACK_SPEED:
			return "+%.2f atk/s" % value_per_level
		UPGRADE_CRIT_CHANCE:
			return "+%.0f%% crit" % (value_per_level * 100.0)
		UPGRADE_CRIT_MULTIPLIER:
			return "+%.0f%% crit dmg" % (value_per_level * 100.0)
		_:
			return ""

func _apply_upgrade_bonuses() -> void:
	bonus_max_hp = 0.0
	bonus_damage = get_upgrade_level(UPGRADE_DAMAGE) * float(upgrade_definitions[UPGRADE_DAMAGE]["value_per_level"])
	bonus_attack_speed = get_upgrade_level(UPGRADE_ATTACK_SPEED) * float(upgrade_definitions[UPGRADE_ATTACK_SPEED]["value_per_level"])
	bonus_crit_chance = get_upgrade_level(UPGRADE_CRIT_CHANCE) * float(upgrade_definitions[UPGRADE_CRIT_CHANCE]["value_per_level"])
	bonus_crit_multiplier = get_upgrade_level(UPGRADE_CRIT_MULTIPLIER) * float(upgrade_definitions[UPGRADE_CRIT_MULTIPLIER]["value_per_level"])
	bonus_defense = 0.0
	bonus_evasion = 0.0
	bonus_accuracy = 0.0
	_apply_equipment_and_artifact_bonuses()

func _rebuild_all_bonuses() -> void:
	_apply_upgrade_bonuses()

func _try_generate_weapon_skill_offers(previous_level: int, new_level: int) -> void:
	var prev_milestone: int = int(floor(float(previous_level) / 100.0))
	var new_milestone: int = int(floor(float(new_level) / 100.0))
	if new_milestone <= prev_milestone:
		return
	if not pending_weapon_skill_offers.is_empty():
		return
	pending_weapon_skill_offers = _roll_weapon_skill_offers()

func _roll_weapon_skill_offers() -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	var skill_ids: Array[StringName] = []
	for key in SchoolRules.SKILL_DEFINITIONS.keys():
		skill_ids.append(key as StringName)
	if skill_ids.is_empty():
		return offers
	var kinds: Array[String] = ["dmg", "cd", "proc"]
	for _i in range(3):
		var skill_id: StringName = skill_ids[randi_range(0, skill_ids.size() - 1)]
		var kind: String = kinds[randi_range(0, kinds.size() - 1)]
		offers.append({
			"skill_id": skill_id,
			"kind": kind,
			"text": _format_weapon_offer_text(skill_id, kind),
		})
	return offers

func _format_weapon_offer_text(skill_id: StringName, kind: String) -> String:
	var skill_name := String(SchoolRules.SKILL_DEFINITIONS.get(skill_id, {}).get("name", skill_id))
	match kind:
		"dmg":
			return "%s: +4%% damage" % skill_name
		"cd":
			return "%s: -3%% cooldown" % skill_name
		"proc":
			return "%s: +5%% effect power" % skill_name
		_:
			return skill_name

func _get_helm_block_chance() -> float:
	var tiers: float = floor(float(get_equipment_level(&"helm")) / 100.0)
	return _soft_cap_progress(tiers * 0.0025 + artifact_bonus_block_chance, 0.20, 0.40)

func _get_chest_reflect_chance() -> float:
	var tiers: float = floor(float(get_equipment_level(&"chest")) / 100.0)
	return _soft_cap_progress(tiers * 0.0030 + artifact_bonus_reflect_chance, 0.25, 0.45)

func _get_gloves_reflect_ratio() -> float:
	var tiers: float = floor(float(get_equipment_level(&"gloves")) / 100.0)
	return _soft_cap_progress(tiers * 0.0020 + artifact_bonus_reflect_ratio, 0.20, 0.35)

func _get_boots_haste_chance() -> float:
	var tiers: float = floor(float(get_equipment_level(&"boots")) / 100.0)
	return _soft_cap_progress(tiers * 0.0025 + artifact_bonus_haste_chance, 0.20, 0.40)

func _get_boots_haste_duration() -> float:
	var tiers: float = floor(float(get_equipment_level(&"boots")) / 300.0)
	return 2.5 + tiers * 0.2 + artifact_bonus_haste_duration

func _get_ring_repeat_chance() -> float:
	var tiers: float = floor(float(get_equipment_level(&"ring")) / 100.0)
	return _soft_cap_progress(tiers * 0.0013 + artifact_bonus_repeat_chance, 0.12, 0.20)

func _get_amulet_teleport_chance() -> float:
	var tiers: float = floor(float(get_equipment_level(&"amulet")) / 100.0)
	return _soft_cap_progress(tiers * 0.0014 + artifact_bonus_teleport_chance, 0.10, 0.20)

func _get_relic_clone_chance() -> float:
	var tiers: float = floor(float(get_equipment_level(&"relic")) / 100.0)
	return _soft_cap_progress(tiers * 0.0009 + artifact_bonus_clone_chance, 0.08, 0.18)

func _get_relic_clone_duration() -> float:
	var tiers: float = floor(float(get_equipment_level(&"relic")) / 100.0)
	return minf(10.0, 4.0 + tiers * 0.029 + artifact_bonus_clone_duration)

func _get_relic_clone_stat_multiplier() -> float:
	var tiers: float = floor(float(get_equipment_level(&"relic")) / 500.0)
	return minf(0.70, 0.40 + tiers * 0.005 + artifact_bonus_clone_stat_multiplier)

func _soft_cap_progress(value: float, soft_cap: float, hard_cap: float) -> float:
	if value <= soft_cap:
		return minf(value, hard_cap)
	var overflow := value - soft_cap
	return minf(hard_cap, soft_cap + overflow * 0.5)

func _format_artifact_effect_summary(artifact_id: StringName, level: int) -> String:
	var effect: Dictionary = ARTIFACT_EFFECTS.get(artifact_id, {})
	if effect.is_empty():
		return "Нет эффекта." if current_language == &"ru" else "No effect."
	var coef: float = float(effect.get("coef", 0.0))
	var label: String = String(effect.get("label", "effect"))
	var value: float = level * coef
	var is_ru: bool = current_language == &"ru"
	var ru_label_map := {
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
	}
	var ui_label: String = String(ru_label_map.get(label, label)) if is_ru else label
	if bool(effect.get("percent", false)):
		return ("Даёт +%.2f%% %s." % [value * 100.0, ui_label]) if is_ru else ("Gives +%.2f%% %s." % [value * 100.0, ui_label])
	if bool(effect.get("seconds", false)):
		return ("Даёт +%.2fс %s." % [value, ui_label]) if is_ru else ("Gives +%.2fs %s." % [value, ui_label])
	if label == "HP":
		return ("Даёт +%.0f %s." % [value, ui_label]) if is_ru else ("Gives +%.0f %s." % [value, ui_label])
	return ("Даёт +%.2f %s." % [value, ui_label]) if is_ru else ("Gives +%.2f %s." % [value, ui_label])

func _apply_artifact_effect(artifact_id: StringName, level: int) -> void:
	var effect: Dictionary = ARTIFACT_EFFECTS.get(artifact_id, {})
	if effect.is_empty():
		return
	var stat: String = String(effect.get("stat", ""))
	var delta: float = float(effect.get("coef", 0.0)) * level
	match stat:
		"damage":
			bonus_damage += delta
		"max_hp":
			bonus_max_hp += delta
		"attack_speed":
			bonus_attack_speed += delta
		"crit_chance":
			bonus_crit_chance += delta
		"crit_multiplier":
			bonus_crit_multiplier += delta
		"defense":
			bonus_defense += delta
		"evasion":
			bonus_evasion += delta
		"accuracy":
			bonus_accuracy += delta
		"artifact_bonus_block_chance":
			artifact_bonus_block_chance += delta
		"artifact_bonus_reflect_chance":
			artifact_bonus_reflect_chance += delta
		"artifact_bonus_reflect_ratio":
			artifact_bonus_reflect_ratio += delta
		"artifact_bonus_haste_chance":
			artifact_bonus_haste_chance += delta
		"artifact_bonus_haste_duration":
			artifact_bonus_haste_duration += delta
		"artifact_bonus_repeat_chance":
			artifact_bonus_repeat_chance += delta
		"artifact_bonus_teleport_chance":
			artifact_bonus_teleport_chance += delta
		"artifact_bonus_clone_chance":
			artifact_bonus_clone_chance += delta
		"artifact_bonus_clone_duration":
			artifact_bonus_clone_duration += delta
		"artifact_bonus_clone_stat_multiplier":
			artifact_bonus_clone_stat_multiplier += delta
		"artifact_bonus_skill_damage_mult":
			artifact_bonus_skill_damage_mult += delta
		"artifact_bonus_skill_proc_mult":
			artifact_bonus_skill_proc_mult += delta

func _find_safe_teleport_position(origin: Vector2) -> Vector2:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best := origin
	var best_score := -INF
	for _i in range(16):
		var candidate := Vector2(
			randf_range(GameConstants.ARENA_MIN.x + 28.0, GameConstants.ARENA_MAX.x - 28.0),
			randf_range(GameConstants.ARENA_MIN.y + 28.0, GameConstants.ARENA_MAX.y - 28.0)
		)
		var nearest := INF
		for enemy in enemies:
			if enemy is not Enemy or not is_instance_valid(enemy):
				continue
			var dist := candidate.distance_to((enemy as Enemy).global_position)
			if dist < nearest:
				nearest = dist
		if nearest > best_score:
			best_score = nearest
			best = candidate
	return best

func _apply_equipment_and_artifact_bonuses() -> void:
	var weapon_level: int = get_equipment_level(&"weapon")
	var helm_level: int = get_equipment_level(&"helm")
	var chest_level: int = get_equipment_level(&"chest")
	var gloves_level: int = get_equipment_level(&"gloves")
	var boots_level: int = get_equipment_level(&"boots")
	var ring_level: int = get_equipment_level(&"ring")
	var amulet_level: int = get_equipment_level(&"amulet")
	var relic_level: int = get_equipment_level(&"relic")
	var weapon_50: float = floor(float(weapon_level) / 50.0)
	var helm_50: float = floor(float(helm_level) / 50.0)
	var chest_50: float = floor(float(chest_level) / 50.0)
	var gloves_50: float = floor(float(gloves_level) / 50.0)
	var boots_50: float = floor(float(boots_level) / 50.0)
	var ring_50: float = floor(float(ring_level) / 50.0)
	var amulet_50: float = floor(float(amulet_level) / 50.0)
	var relic_50: float = floor(float(relic_level) / 50.0)

	# Every 50 levels: boost each item's base stat progression.
	bonus_damage += weapon_level * (0.16 + weapon_50 * 0.0035)
	bonus_max_hp += helm_level * (0.42 + helm_50 * 0.009)
	bonus_max_hp += chest_level * (0.74 + chest_50 * 0.012)
	bonus_attack_speed += gloves_level * (0.0018 + gloves_50 * 0.00004)
	bonus_evasion += boots_level * (0.034 + boots_50 * 0.0008)
	bonus_accuracy += ring_level * (0.06 + ring_50 * 0.0012)
	bonus_accuracy += amulet_level * (0.046 + amulet_50 * 0.0009)
	bonus_defense += helm_level * (0.055 + helm_50 * 0.0012)
	bonus_defense += chest_level * (0.095 + chest_50 * 0.0017)
	bonus_crit_chance += ring_level * (0.000002 + ring_50 * 0.00000001)
	bonus_crit_multiplier += amulet_level * (0.00009 + amulet_50 * 0.0000003)

	var weapon_100: float = floor(float(weapon_level) / 100.0)
	var helm_100: float = floor(float(helm_level) / 100.0)
	var chest_100: float = floor(float(chest_level) / 100.0)
	var gloves_100: float = floor(float(gloves_level) / 100.0)
	var boots_100: float = floor(float(boots_level) / 100.0)
	var ring_100: float = floor(float(ring_level) / 100.0)
	var amulet_100: float = floor(float(amulet_level) / 100.0)
	var relic_100: float = floor(float(relic_level) / 100.0)

	# Every 100 levels: slot-specific passive bonuses.
	bonus_crit_multiplier += weapon_100 * 0.0035
	bonus_defense += helm_100 * 0.42
	bonus_defense += chest_100 * 0.62
	bonus_crit_chance += gloves_100 * 0.0012
	bonus_attack_speed += boots_100 * 0.0022
	bonus_crit_chance += ring_100 * 0.0012
	bonus_damage += amulet_100 * 0.3
	bonus_accuracy += relic_100 * 0.3

	var weapon_1000: float = floor(float(weapon_level) / 1000.0)
	var helm_1000: float = floor(float(helm_level) / 1000.0)
	var chest_1000: float = floor(float(chest_level) / 1000.0)
	var gloves_1000: float = floor(float(gloves_level) / 1000.0)
	var boots_1000: float = floor(float(boots_level) / 1000.0)
	var ring_1000: float = floor(float(ring_level) / 1000.0)
	var amulet_1000: float = floor(float(amulet_level) / 1000.0)
	var relic_1000: float = floor(float(relic_level) / 1000.0)

	# Every 1000 levels: strong item identity spikes.
	bonus_damage += weapon_1000 * 28.0
	bonus_crit_multiplier += weapon_1000 * 0.07
	bonus_max_hp += helm_1000 * 72.0
	bonus_defense += helm_1000 * 9.0
	bonus_max_hp += chest_1000 * 105.0
	bonus_defense += chest_1000 * 13.0
	bonus_attack_speed += gloves_1000 * 0.05
	bonus_evasion += boots_1000 * 6.5
	bonus_crit_chance += ring_1000 * 0.015
	bonus_damage += amulet_1000 * 12.0
	bonus_accuracy += relic_1000 * 10.0

	artifact_bonus_block_chance = 0.0
	artifact_bonus_reflect_chance = 0.0
	artifact_bonus_reflect_ratio = 0.0
	artifact_bonus_haste_chance = 0.0
	artifact_bonus_haste_duration = 0.0
	artifact_bonus_repeat_chance = 0.0
	artifact_bonus_teleport_chance = 0.0
	artifact_bonus_clone_chance = 0.0
	artifact_bonus_clone_duration = 0.0
	artifact_bonus_clone_stat_multiplier = 0.0
	artifact_bonus_skill_damage_mult = 0.0
	artifact_bonus_skill_proc_mult = 0.0

	for artifact_id in owned_artifacts:
		var level := int(artifact_levels.get(artifact_id, 0))
		_apply_artifact_effect(artifact_id, level)

func perform_prestige() -> void:
	gold = 0
	essence = 0
	echo_collected = 0
	echo_power = 0
	total_deaths = 0
	best_run_time_sec = 0.0
	incoming_hits_since_absorb = 0
	pending_weapon_skill_offers.clear()
	repeat_action_icd_left = 0.0
	haste_buff_time_left = 0.0
	clone_buff_time_left = 0.0
	clone_stat_multiplier = 0.0
	teleport_icd_left = 0.0
	haste_icd_left = 0.0
	clone_icd_left = 0.0
	for equipment_id in EQUIPMENT_ORDER:
		equipment_levels[equipment_id] = 0
		equipment_unlocked[equipment_id] = equipment_id == &"weapon"
	for upgrade_id: StringName in get_upgrade_ids():
		upgrade_levels[upgrade_id] = 0
	_apply_upgrade_bonuses()
	resources_changed.emit(gold, essence)
	echo_changed.emit(echo_collected, echo_power)
	hero_stats_changed.emit()
	upgrades_changed.emit()
	prestige_performed.emit()
	school_state_changed.emit()
	school_mastery_changed.emit()

func _on_wave_changed(current_wave: int) -> void:
	if current_wave > highest_wave_reached:
		highest_wave_reached = current_wave
		_rebuild_school_state()

func _rebuild_school_state() -> void:
	_rebuild_global_skill_pool()
	_trim_equipped_skills_to_permanent_slots()
	school_state_changed.emit()

func _rebuild_global_skill_pool() -> void:
	unlocked_global_skill_ids.clear()
	for school_id: StringName in SchoolRules.SCHOOL_ORDER:
		if get_school_core_mastery_level(school_id) < 10:
			continue
		var school_skills: Array = get_school_definition(school_id).get("skills", [])
		for skill_id_variant in school_skills:
			var skill_id := skill_id_variant as StringName
			if not unlocked_global_skill_ids.has(skill_id):
				unlocked_global_skill_ids.append(skill_id)

func _trim_equipped_skills_to_permanent_slots() -> void:
	var allowed_slots := get_permanent_skill_slot_count()
	while equipped_skill_ids.size() > allowed_slots:
		equipped_skill_ids.remove_at(equipped_skill_ids.size() - 1)
	while equipped_skill_ids.size() < allowed_slots:
		equipped_skill_ids.append(&"")

func _is_skill_unlocked_for_active_school(skill_id: StringName) -> bool:
	if GameConstants.DEV_UNLOCK_ALL_SKILLS:
		return true
	var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
	var unlock_level := int(skill_data.get("unlock_level", 999))
	return get_school_core_mastery_level(active_school) >= unlock_level

func run_balance_simulation(max_wave: int = 1000, step: int = 100) -> Array[Dictionary]:
	return BalanceSimulator.run(max_wave, step)
