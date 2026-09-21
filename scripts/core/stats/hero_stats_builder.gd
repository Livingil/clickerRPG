extends RefCounted
class_name HeroStatsBuilder

static func build_current(
	base_bonuses: Dictionary,
	echo_bonuses: Dictionary,
	prestige_bonuses: Dictionary,
	ad_boost_flags: Dictionary
) -> CombatStats:
	var stats: CombatStats = _build_base_stats(base_bonuses, echo_bonuses)
	if bool(ad_boost_flags.get("battle_focus", false)):
		stats.damage *= 1.25
	if bool(ad_boost_flags.get("haste_spark", false)):
		stats.attack_speed *= 1.20
	_apply_prestige(stats, prestige_bonuses)
	_clamp(stats)
	return stats

static func build_current_from_game_state(game_state: Object) -> CombatStats:
	return build_current(
		build_base_bonuses_from_game_state(game_state),
		EchoRules.get_tier_bonuses(game_state.echo_power),
		build_prestige_bonuses_from_game_state(game_state),
		build_ad_boost_flags_from_game_state(game_state)
	)

static func build_for_echo(base_bonuses: Dictionary, echo_bonuses: Dictionary, prestige_bonuses: Dictionary) -> CombatStats:
	var stats: CombatStats = _build_base_stats(base_bonuses, echo_bonuses)
	_apply_prestige(stats, prestige_bonuses)
	_clamp(stats)
	return stats

static func build_base_bonuses_from_game_state(game_state: Object) -> Dictionary:
	return {
		"max_hp": game_state.get_bonus_total("max_hp"),
		"damage": game_state.get_bonus_total("damage"),
		"attack_speed": game_state.get_bonus_total("attack_speed"),
		"crit_chance": game_state.get_bonus_total("crit_chance"),
		"crit_multiplier": game_state.get_bonus_total("crit_multiplier"),
		"defense": game_state.get_bonus_total("defense"),
		"evasion": game_state.get_bonus_total("evasion"),
		"accuracy": game_state.get_bonus_total("accuracy"),
	}

static func build_prestige_bonuses_from_game_state(game_state: Object) -> Dictionary:
	return {
		"attack_multiplier": game_state.get_prestige_attack_multiplier(),
		"hp_multiplier": game_state.get_prestige_hp_multiplier(),
		"defense_multiplier": game_state.get_prestige_defense_multiplier(),
		"crit_chance_bonus": game_state.get_prestige_crit_chance_bonus(),
		"crit_multiplier_bonus": game_state.get_prestige_crit_multiplier_bonus(),
	}

static func build_ad_boost_flags_from_game_state(game_state: Object) -> Dictionary:
	return {
		"battle_focus": game_state.has_active_ad_boost(AdBoostRules.BATTLE_FOCUS),
		"haste_spark": game_state.has_active_ad_boost(AdBoostRules.HASTE_SPARK),
	}

static func _build_base_stats(base_bonuses: Dictionary, echo_bonuses: Dictionary) -> CombatStats:
	var stats: CombatStats = CombatStats.new()
	stats.max_hp = GameConstants.HERO_BASE_HP + float(base_bonuses.get("max_hp", 0.0)) + float(echo_bonuses.get("max_hp", 0.0))
	stats.damage = GameConstants.HERO_BASE_DAMAGE + float(base_bonuses.get("damage", 0.0)) + float(echo_bonuses.get("damage", 0.0))
	stats.attack_speed = GameConstants.HERO_BASE_ATTACK_SPEED + float(base_bonuses.get("attack_speed", 0.0)) + float(echo_bonuses.get("attack_speed", 0.0))
	stats.crit_chance = GameConstants.HERO_BASE_CRIT_CHANCE + float(base_bonuses.get("crit_chance", 0.0)) + float(echo_bonuses.get("crit_chance", 0.0))
	stats.crit_multiplier = GameConstants.HERO_BASE_CRIT_MULTIPLIER + float(base_bonuses.get("crit_multiplier", 0.0)) + float(echo_bonuses.get("crit_multiplier", 0.0))
	stats.defense = GameConstants.HERO_BASE_DEFENSE + float(base_bonuses.get("defense", 0.0)) + float(echo_bonuses.get("defense", 0.0))
	stats.evasion = GameConstants.HERO_BASE_EVASION + float(base_bonuses.get("evasion", 0.0)) + float(echo_bonuses.get("evasion", 0.0))
	stats.accuracy = GameConstants.HERO_BASE_ACCURACY + float(base_bonuses.get("accuracy", 0.0)) + float(echo_bonuses.get("accuracy", 0.0))
	return stats

static func _apply_prestige(stats: CombatStats, prestige_bonuses: Dictionary) -> void:
	stats.damage *= float(prestige_bonuses.get("attack_multiplier", 1.0))
	stats.max_hp *= float(prestige_bonuses.get("hp_multiplier", 1.0))
	stats.defense *= float(prestige_bonuses.get("defense_multiplier", 1.0))
	stats.crit_chance += float(prestige_bonuses.get("crit_chance_bonus", 0.0))
	stats.crit_multiplier += float(prestige_bonuses.get("crit_multiplier_bonus", 0.0))

static func _clamp(stats: CombatStats) -> void:
	stats.attack_speed = EquipmentProgressRules.cap_hero_attack_speed(stats.attack_speed)
	stats.crit_chance = clampf(stats.crit_chance, 0.0, GameConstants.HERO_MAX_CRIT_CHANCE)
	stats.crit_multiplier = clampf(stats.crit_multiplier, 1.0, GameConstants.HERO_MAX_CRIT_MULTIPLIER)
