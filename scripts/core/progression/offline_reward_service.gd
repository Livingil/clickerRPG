extends RefCounted
class_name OfflineRewardService

const MIN_SEC: int = 60
const MAX_SEC: int = 8 * 60 * 60
const EFFICIENCY: float = 0.35
const MIN_WAVE_CLEAR_SEC: float = 8.0

static func build_reward_report(
	saved_unix: int,
	now_unix: int,
	highest_wave_reached: int,
	hero_dps: float,
	gold_multiplier: float,
	essence_multiplier: float,
	echo_multiplier: float
) -> Dictionary:
	if saved_unix <= 0 or now_unix <= saved_unix:
		return {}
	var elapsed_sec: int = now_unix - saved_unix
	if elapsed_sec < MIN_SEC:
		return {}

	var capped_sec: int = mini(elapsed_sec, MAX_SEC)
	var reward_wave: int = maxi(1, highest_wave_reached)
	var wave_estimate: Dictionary = estimate_wave_rewards(reward_wave, hero_dps)
	var clear_time_sec: float = maxf(MIN_WAVE_CLEAR_SEC, float(wave_estimate.get("clear_time_sec", MIN_WAVE_CLEAR_SEC)))
	var effective_waves: float = (float(capped_sec) / clear_time_sec) * EFFICIENCY
	if effective_waves <= 0.0:
		return {}

	var gold_reward: int = _apply_multiplier(int(round(float(wave_estimate.get("gold", 0.0)) * effective_waves)), gold_multiplier)
	var essence_reward: int = _apply_multiplier(int(round(float(wave_estimate.get("essence", 0.0)) * effective_waves)), essence_multiplier)
	var echo_reward: int = _apply_multiplier(int(round(float(wave_estimate.get("echo", 0.0)) * effective_waves)), echo_multiplier)
	if gold_reward <= 0 and essence_reward <= 0 and echo_reward <= 0:
		return {}

	return {
		"elapsed_sec": elapsed_sec,
		"capped_sec": capped_sec,
		"wave": reward_wave,
		"effective_waves": effective_waves,
		"gold": gold_reward,
		"essence": essence_reward,
		"echo": echo_reward,
		"capped": elapsed_sec > capped_sec,
	}

static func estimate_wave_rewards(wave: int, hero_dps: float) -> Dictionary:
	var counts: Dictionary = get_wave_enemy_counts(wave)
	var reward_multiplier: float = get_wave_reward_multiplier(wave)
	var gold_total: float = 0.0
	var essence_total: float = 0.0
	var echo_total: float = 0.0
	var hp_total: float = 0.0
	var enemy_count_total: int = 0
	for kind_variant in counts.keys():
		var kind: StringName = kind_variant as StringName
		var count: int = int(counts[kind])
		if count <= 0:
			continue
		enemy_count_total += count
		gold_total += GameConstants.ENEMY_REWARD_GOLD * reward_multiplier * get_boss_gold_multiplier(kind) * count
		essence_total += GameConstants.ENEMY_REWARD_ESSENCE * reward_multiplier * get_boss_essence_multiplier(kind) * count
		echo_total += get_echo_gain_for_enemy(kind, wave) * count
		hp_total += GameConstants.ENEMY_BASE_HP * get_wave_hp_multiplier(wave) * get_boss_hp_multiplier(kind) * count

	var clear_time_sec: float = hp_total / maxf(1.0, hero_dps) + float(enemy_count_total) * 0.35
	return {
		"gold": gold_total,
		"essence": essence_total,
		"echo": echo_total,
		"clear_time_sec": clear_time_sec,
	}

static func get_wave_enemy_counts(wave: int) -> Dictionary:
	var normal: int = GameConstants.normal_enemy_count_for_wave(wave)
	var counts: Dictionary = {&"normal": normal, &"wave": 1, &"mini": 0, &"grand": 0, &"apex": 0}
	if wave % 5 == 0:
		if wave % 100 == 0:
			counts[&"apex"] = 1
		elif wave % 10 == 0:
			counts[&"grand"] = 1
		else:
			counts[&"mini"] = 1
	return counts

static func get_wave_reward_multiplier(wave: int) -> float:
	return GameConstants.progressive_wave_multiplier(
		maxi(0, wave - 1),
		GameConstants.BALANCE_WAVE_REWARD_EARLY,
		GameConstants.BALANCE_WAVE_REWARD_MID,
		GameConstants.BALANCE_WAVE_REWARD_LATE
	)

static func get_wave_hp_multiplier(wave: int) -> float:
	return GameConstants.progressive_wave_multiplier(
		maxi(0, wave - 1),
		GameConstants.BALANCE_WAVE_HP_EARLY,
		GameConstants.BALANCE_WAVE_HP_MID,
		GameConstants.BALANCE_WAVE_HP_LATE
	)

static func get_boss_hp_multiplier(kind: StringName) -> float:
	match kind:
		&"wave":
			return GameConstants.WAVE_BOSS_HP_MULTIPLIER
		&"mini":
			return GameConstants.MINI_BOSS_HP_MULTIPLIER
		&"grand":
			return GameConstants.GRAND_BOSS_HP_MULTIPLIER
		&"apex":
			return GameConstants.APEX_BOSS_HP_MULTIPLIER
		_:
			return 1.0

static func get_boss_gold_multiplier(kind: StringName) -> float:
	match kind:
		&"wave":
			return GameConstants.WAVE_BOSS_REWARD_GOLD_MULTIPLIER
		&"mini":
			return GameConstants.MINI_BOSS_REWARD_GOLD_MULTIPLIER
		&"grand":
			return GameConstants.GRAND_BOSS_REWARD_GOLD_MULTIPLIER
		&"apex":
			return GameConstants.APEX_BOSS_REWARD_GOLD_MULTIPLIER
		_:
			return 1.0

static func get_boss_essence_multiplier(kind: StringName) -> float:
	match kind:
		&"wave":
			return GameConstants.WAVE_BOSS_REWARD_ESSENCE_MULTIPLIER
		&"mini":
			return GameConstants.MINI_BOSS_REWARD_ESSENCE_MULTIPLIER
		&"grand":
			return GameConstants.GRAND_BOSS_REWARD_ESSENCE_MULTIPLIER
		&"apex":
			return GameConstants.APEX_BOSS_REWARD_ESSENCE_MULTIPLIER
		_:
			return 1.0

static func get_echo_gain_for_enemy(boss_kind: StringName, wave_number: int) -> int:
	var wave: int = maxi(1, wave_number)
	var reward_curve: float = get_wave_reward_multiplier(wave)
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

static func _apply_multiplier(value: int, multiplier: float) -> int:
	return maxi(0, int(round(float(maxi(0, value)) * multiplier)))
