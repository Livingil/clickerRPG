extends Node

const CombatStats = preload("res://scripts/core/stats/combat_stats.gd")

signal resources_changed(gold: int, essence: int)
signal echo_changed(collected_echo: int, active_echo_power: int)
signal hero_stats_changed
signal upgrades_changed
signal prestige_performed

const UPGRADE_DAMAGE: StringName = &"damage"
const UPGRADE_ATTACK_SPEED: StringName = &"attack_speed"
const UPGRADE_CRIT_CHANCE: StringName = &"crit_chance"
const UPGRADE_CRIT_MULTIPLIER: StringName = &"crit_multiplier"

var gold: int = 0
var essence: int = 0
var echo_collected: int = 0
var echo_power: int = 0

var bonus_damage: float = 0.0
var bonus_attack_speed: float = 0.0
var bonus_crit_chance: float = 0.0
var bonus_crit_multiplier: float = 0.0

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
		"value_per_level": 4.0,
	},
	UPGRADE_ATTACK_SPEED: {
		"name": "Attack Speed",
		"base_cost": 25,
		"cost_scale": 1.4,
		"value_per_level": 0.12,
	},
	UPGRADE_CRIT_CHANCE: {
		"name": "Crit Chance",
		"base_cost": 30,
		"cost_scale": 1.45,
		"value_per_level": 0.02,
	},
	UPGRADE_CRIT_MULTIPLIER: {
		"name": "Crit Mult",
		"base_cost": 40,
		"cost_scale": 1.5,
		"value_per_level": 0.15,
	},
}

func add_gold(value: int) -> void:
	gold += value
	resources_changed.emit(gold, essence)

func add_essence(value: int) -> void:
	essence += value
	resources_changed.emit(gold, essence)

func add_echo(value: int) -> void:
	echo_collected += value
	echo_changed.emit(echo_collected, echo_power)

func build_hero_stats() -> CombatStats:
	var stats := CombatStats.new()
	stats.damage = GameConstants.HERO_BASE_DAMAGE + bonus_damage + get_active_echo_damage_bonus()
	stats.attack_speed = GameConstants.HERO_BASE_ATTACK_SPEED + bonus_attack_speed + get_active_echo_attack_speed_bonus()
	stats.crit_chance = clampf(GameConstants.HERO_BASE_CRIT_CHANCE + bonus_crit_chance, 0.0, 1.0)
	stats.crit_multiplier = maxf(1.0, GameConstants.HERO_BASE_CRIT_MULTIPLIER + bonus_crit_multiplier)
	return stats

func get_hero_dps() -> float:
	return build_hero_stats().compute_dps()

func activate_collected_echo() -> void:
	if echo_collected <= 0:
		return
	echo_power += echo_collected
	echo_collected = 0
	echo_changed.emit(echo_collected, echo_power)
	hero_stats_changed.emit()

func get_active_echo_damage_bonus() -> float:
	return echo_power * 0.3

func get_active_echo_attack_speed_bonus() -> float:
	return floor(float(echo_power) / 20.0) * 0.03

func get_active_echo_bonus_summary() -> String:
	return "+%.1f dmg  +%.2f atk/s" % [
		get_active_echo_damage_bonus(),
		get_active_echo_attack_speed_bonus(),
	]

func get_collected_echo_bonus_summary() -> String:
	return "+%.1f dmg  +%.2f atk/s after death" % [
		echo_collected * 0.3,
		floor(float(echo_collected) / 20.0) * 0.03,
	]

func get_echo_gain_for_enemy(boss_kind: StringName) -> int:
	match boss_kind:
		&"wave":
			return 4
		&"mini":
			return 12
		&"grand":
			return 24
		_:
			return 1

func get_upgrade_ids() -> Array[StringName]:
	return [
		UPGRADE_DAMAGE,
		UPGRADE_ATTACK_SPEED,
		UPGRADE_CRIT_CHANCE,
		UPGRADE_CRIT_MULTIPLIER,
	]

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
	bonus_damage = get_upgrade_level(UPGRADE_DAMAGE) * float(upgrade_definitions[UPGRADE_DAMAGE]["value_per_level"])
	bonus_attack_speed = get_upgrade_level(UPGRADE_ATTACK_SPEED) * float(upgrade_definitions[UPGRADE_ATTACK_SPEED]["value_per_level"])
	bonus_crit_chance = get_upgrade_level(UPGRADE_CRIT_CHANCE) * float(upgrade_definitions[UPGRADE_CRIT_CHANCE]["value_per_level"])
	bonus_crit_multiplier = get_upgrade_level(UPGRADE_CRIT_MULTIPLIER) * float(upgrade_definitions[UPGRADE_CRIT_MULTIPLIER]["value_per_level"])

func perform_prestige() -> void:
	gold = 0
	essence = 0
	echo_collected = 0
	echo_power = 0
	for upgrade_id: StringName in get_upgrade_ids():
		upgrade_levels[upgrade_id] = 0
	_apply_upgrade_bonuses()
	resources_changed.emit(gold, essence)
	echo_changed.emit(echo_collected, echo_power)
	hero_stats_changed.emit()
	upgrades_changed.emit()
	prestige_performed.emit()
