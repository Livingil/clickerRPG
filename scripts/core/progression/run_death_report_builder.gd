extends RefCounted
class_name RunDeathReportBuilder

static func build(
	run_time_sec: float,
	echo_before: int,
	echo_after: int,
	collected_echo: int,
	base_bonuses: Dictionary,
	prestige_bonuses: Dictionary
) -> Dictionary:
	var stats_before: CombatStats = _build_hero_stats_for_echo(echo_before, base_bonuses, prestige_bonuses)
	var stats_after: CombatStats = _build_hero_stats_for_echo(echo_after, base_bonuses, prestige_bonuses)
	var next_echo_info: Dictionary = EchoRules.get_progress_info(echo_after)
	return {
		"run_time_sec": run_time_sec,
		"collected_echo": collected_echo,
		"echo_before": echo_before,
		"echo_after": echo_after,
		"echo_delta": maxi(0, echo_after - echo_before),
		"remaining_to_next_echo_bonus": int(next_echo_info.get("remaining_to_next", 0)),
		"next_echo_bonus_at": int(next_echo_info.get("required_echo", echo_after)),
		"damage_before": stats_before.damage,
		"damage_after": stats_after.damage,
		"hp_before": stats_before.max_hp,
		"hp_after": stats_after.max_hp,
		"attack_speed_before": stats_before.attack_speed,
		"attack_speed_after": stats_after.attack_speed,
		"defense_before": stats_before.defense,
		"defense_after": stats_after.defense,
		"evasion_before": stats_before.evasion,
		"evasion_after": stats_after.evasion,
		"accuracy_before": stats_before.accuracy,
		"accuracy_after": stats_after.accuracy,
		"crit_chance_before": stats_before.crit_chance,
		"crit_chance_after": stats_after.crit_chance,
		"crit_multiplier_before": stats_before.crit_multiplier,
		"crit_multiplier_after": stats_after.crit_multiplier,
	}

static func build_on_game_state(
	game_state: Object,
	run_time_sec: float,
	echo_before: int,
	echo_after: int,
	collected_echo: int
) -> Dictionary:
	game_state.last_run_death_report = build(
		run_time_sec,
		echo_before,
		echo_after,
		collected_echo,
		HeroStatsBuilder.build_base_bonuses_from_game_state(game_state),
		HeroStatsBuilder.build_prestige_bonuses_from_game_state(game_state)
	)
	return game_state.get_last_run_death_report()

static func emit_on_game_state(game_state: Object, report: Dictionary) -> void:
	if report.is_empty():
		return
	game_state.last_run_death_report = report.duplicate(true)
	game_state.run_death_report_ready.emit(game_state.get_last_run_death_report())

static func _build_hero_stats_for_echo(echo_value: int, base_bonuses: Dictionary, prestige_bonuses: Dictionary) -> CombatStats:
	return HeroStatsBuilder.build_for_echo(base_bonuses, EchoRules.get_tier_bonuses(echo_value), prestige_bonuses)
