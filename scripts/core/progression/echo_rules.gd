extends RefCounted
class_name EchoRules

const STAT_DAMAGE: String = "damage"
const STAT_MAX_HP: String = "max_hp"
const STAT_ATTACK_SPEED: String = "attack_speed"
const STAT_CRIT_CHANCE: String = "crit_chance"
const STAT_CRIT_MULTIPLIER: String = "crit_multiplier"
const STAT_DEFENSE: String = "defense"
const STAT_EVASION: String = "evasion"
const STAT_ACCURACY: String = "accuracy"

static func get_tier_bonuses(echo_value: int) -> Dictionary:
	var total_echo: float = maxf(0.0, float(echo_value))
	var out: Dictionary = {
		STAT_DAMAGE: 0.0,
		STAT_MAX_HP: 0.0,
		STAT_ATTACK_SPEED: 0.0,
		STAT_CRIT_CHANCE: 0.0,
		STAT_CRIT_MULTIPLIER: 0.0,
		STAT_DEFENSE: 0.0,
		STAT_EVASION: 0.0,
		STAT_ACCURACY: 0.0,
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

static func get_progress_info(echo_value: int) -> Dictionary:
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

static func format_bonus_summary(bonuses: Dictionary, suffix: String = "") -> String:
	return "+%.0f hp  +%.1f dmg  +%.2f atk/s  +%.1f def  +%.1f eva  +%.1f acc  +%.2f%% crit  +%.2f critx%s" % [
		float(bonuses.get(STAT_MAX_HP, 0.0)),
		float(bonuses.get(STAT_DAMAGE, 0.0)),
		float(bonuses.get(STAT_ATTACK_SPEED, 0.0)),
		float(bonuses.get(STAT_DEFENSE, 0.0)),
		float(bonuses.get(STAT_EVASION, 0.0)),
		float(bonuses.get(STAT_ACCURACY, 0.0)),
		float(bonuses.get(STAT_CRIT_CHANCE, 0.0)) * 100.0,
		float(bonuses.get(STAT_CRIT_MULTIPLIER, 0.0)),
		suffix,
	]
