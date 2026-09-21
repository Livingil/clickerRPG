extends RefCounted
class_name ResourceProgressService

const AdBoostServiceData = preload("res://scripts/core/progression/ad_boost_service.gd")
const OfflineRewardServiceData = preload("res://scripts/core/progression/offline_reward_service.gd")

static func build_resource_add_result(
	current_amount: int,
	base_value: int,
	economy_multiplier: float,
	active_ad_boosts: Dictionary,
	ad_boost_id: StringName
) -> Dictionary:
	var gained: int = AdBoostServiceData.apply_reward_multiplier(
		active_ad_boosts,
		_apply_multiplier(base_value, economy_multiplier),
		ad_boost_id
	)
	return {
		"amount": current_amount + gained,
		"gained": gained,
	}

static func add_gold_to_game_state(game_state: Object, value: int) -> void:
	game_state.gold = _build_resource_amount(
		game_state,
		game_state.gold,
		value,
		game_state.get_gold_multiplier(),
		AdBoostRules.GOLD_RUSH
	)
	game_state.resources_changed.emit(game_state.gold, game_state.essence)

static func add_essence_to_game_state(game_state: Object, value: int) -> void:
	game_state.essence = _build_resource_amount(
		game_state,
		game_state.essence,
		value,
		game_state.get_essence_multiplier(),
		AdBoostRules.ESSENCE_SURGE
	)
	game_state.resources_changed.emit(game_state.gold, game_state.essence)

static func add_echo_to_game_state(game_state: Object, value: int) -> void:
	game_state.echo_collected = _build_resource_amount(
		game_state,
		game_state.echo_collected,
		value,
		game_state.get_echo_multiplier(),
		AdBoostRules.ECHO_MAGNET
	)
	game_state.echo_changed.emit(game_state.echo_collected, game_state.echo_power)

static func _build_resource_amount(
	game_state: Object,
	current_amount: int,
	base_value: int,
	economy_multiplier: float,
	ad_boost_id: StringName
) -> int:
	var result: Dictionary = build_resource_add_result(
		current_amount,
		base_value,
		economy_multiplier,
		game_state.active_ad_boosts,
		ad_boost_id
	)
	return int(result.get("amount", current_amount))

static func build_run_death_result(total_deaths: int, best_run_time_sec: float, run_time_sec: float) -> Dictionary:
	return {
		"total_deaths": total_deaths + 1,
		"best_run_time_sec": maxf(best_run_time_sec, run_time_sec),
	}

static func build_offline_reward_result(
	saved_unix: int,
	now_unix: int,
	current_gold: int,
	current_essence: int,
	current_echo_collected: int,
	highest_wave_reached: int,
	hero_dps: float,
	gold_multiplier: float,
	essence_multiplier: float,
	echo_multiplier: float
) -> Dictionary:
	var reward_report: Dictionary = OfflineRewardServiceData.build_reward_report(
		saved_unix,
		now_unix,
		highest_wave_reached,
		hero_dps,
		gold_multiplier,
		essence_multiplier,
		echo_multiplier
	)
	if reward_report.is_empty():
		return {"report": {}}

	return {
		"gold": current_gold + maxi(0, int(reward_report.get("gold", 0))),
		"essence": current_essence + maxi(0, int(reward_report.get("essence", 0))),
		"echo_collected": current_echo_collected + maxi(0, int(reward_report.get("echo", 0))),
		"report": reward_report,
	}

static func apply_offline_rewards_to_game_state(game_state: Object, saved_unix: int, now_unix: int) -> void:
	game_state.pending_offline_reward_report.clear()
	var result: Dictionary = build_offline_reward_result(
		saved_unix,
		now_unix,
		game_state.gold,
		game_state.essence,
		game_state.echo_collected,
		game_state.highest_wave_reached,
		game_state.get_hero_dps(),
		game_state.get_gold_multiplier(),
		game_state.get_essence_multiplier(),
		game_state.get_echo_multiplier()
	)
	var reward_report: Dictionary = result.get("report", {}) as Dictionary
	if reward_report.is_empty():
		return

	game_state.gold = int(result.get("gold", game_state.gold))
	game_state.essence = int(result.get("essence", game_state.essence))
	game_state.echo_collected = int(result.get("echo_collected", game_state.echo_collected))
	game_state.pending_offline_reward_report = reward_report

static func get_echo_gain_for_enemy(boss_kind: StringName, wave: int) -> int:
	return OfflineRewardServiceData.get_echo_gain_for_enemy(boss_kind, wave)

static func apply_multiplier(value: int, multiplier: float) -> int:
	return _apply_multiplier(value, multiplier)

static func _apply_multiplier(value: int, multiplier: float) -> int:
	return maxi(0, int(round(float(maxi(0, value)) * multiplier)))
