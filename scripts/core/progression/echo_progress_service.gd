extends RefCounted
class_name EchoProgressService

static func activate_collected(echo_power: int, echo_collected: int) -> Dictionary:
	if echo_collected <= 0:
		return {
			"activated": false,
			"echo_power": echo_power,
			"echo_collected": echo_collected,
		}
	return {
		"activated": true,
		"echo_power": echo_power + echo_collected,
		"echo_collected": 0,
	}

static func activate_collected_on_game_state(game_state: Object) -> void:
	var result: Dictionary = activate_collected(game_state.echo_power, game_state.echo_collected)
	if not bool(result.get("activated", false)):
		return
	game_state.echo_power = int(result.get("echo_power", game_state.echo_power))
	game_state.echo_collected = int(result.get("echo_collected", game_state.echo_collected))
	game_state.echo_changed.emit(game_state.echo_collected, game_state.echo_power)
	game_state.hero_stats_changed.emit()

static func get_bonus_value(echo_value: int, stat_key: String) -> float:
	return float(EchoRules.get_tier_bonuses(echo_value).get(stat_key, 0.0))

static func get_bonus_summary(echo_value: int, suffix: String = "") -> String:
	return EchoRules.format_bonus_summary(EchoRules.get_tier_bonuses(echo_value), suffix)
