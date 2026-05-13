extends RefCounted
class_name BalanceSimulator

const PROFILE_CHEAPEST: StringName = &"cheapest"
const PROFILE_BALANCED: StringName = &"balanced"
const PROFILE_PROC_FOCUS: StringName = &"proc_focus"

const PROFILE_CONFIGS := {
	&"cheapest": {
		"gold_spend_limit": 500,
		"essence_spend_limit": 200,
		"weights": {
			&"weapon": 1.0, &"helm": 1.0, &"chest": 1.0, &"gloves": 1.0,
			&"boots": 1.0, &"ring": 1.0, &"amulet": 1.0, &"relic": 1.0,
		},
	},
	&"balanced": {
		"gold_spend_limit": 700,
		"essence_spend_limit": 450,
		"weights": {
			&"weapon": 1.10, &"helm": 1.00, &"chest": 1.05, &"gloves": 1.12,
			&"boots": 1.10, &"ring": 1.20, &"amulet": 1.15, &"relic": 1.24,
		},
	},
	&"proc_focus": {
		"gold_spend_limit": 900,
		"essence_spend_limit": 700,
		"weights": {
			&"weapon": 0.95, &"helm": 0.92, &"chest": 0.95, &"gloves": 1.20,
			&"boots": 1.30, &"ring": 1.48, &"amulet": 1.15, &"relic": 1.58,
		},
	},
}

static func get_profile_names() -> Array[StringName]:
	return [PROFILE_CHEAPEST, PROFILE_BALANCED, PROFILE_PROC_FOCUS]

static func run(max_wave: int = 1000, step: int = 100) -> Array[Dictionary]:
	return run_with_profile(max_wave, step, PROFILE_CHEAPEST)

static func run_with_profile(max_wave: int = 1000, step: int = 100, profile: StringName = PROFILE_CHEAPEST) -> Array[Dictionary]:
	var sim: _SimState = _SimState.new(profile)
	var rows: Array[Dictionary] = []
	for wave in range(1, max_wave + 1):
		sim.process_wave(wave)
		if wave % step == 0 or wave == 1:
			rows.append(sim.make_row(wave))
	return rows

static func run_multi_profiles(max_wave: int = 1000, step: int = 100, profiles: Array[StringName] = []) -> Dictionary:
	var requested: Array[StringName] = profiles if not profiles.is_empty() else get_profile_names()
	var out: Dictionary = {}
	for profile in requested:
		out[profile] = run_with_profile(max_wave, step, profile)
	return out

class _SimState:
	var spend_profile: StringName = PROFILE_CHEAPEST
	var profile_config: Dictionary = PROFILE_CONFIGS[PROFILE_CHEAPEST]
	const MAX_ATTEMPTS_PER_TARGET_WAVE: int = 2500

	var gold: float = 0.0
	var essence: float = 0.0
	var echo_collected: float = 0.0
	var echo_power: float = 0.0
	var run_index: int = 1
	var death_count: int = 0
	var first_death_wave: int = -1
	var latest_death_wave: int = -1
	var furthest_wave_reached: int = 1
	var current_wave: int = 1
	var stalled: bool = false
	var equipment: Dictionary = {
		&"weapon": 0, &"helm": 0, &"chest": 0, &"gloves": 0,
		&"boots": 0, &"ring": 0, &"amulet": 0, &"relic": 0,
	}
	var equipment_unlocked: Dictionary = {
		&"weapon": true, &"helm": false, &"chest": false, &"gloves": false,
		&"boots": false, &"ring": false, &"amulet": false, &"relic": false,
	}
	var artifacts_owned: int = 0
	var artifact_levels: int = 0

	var last_wave_gold_income: float = 0.0
	var last_wave_gold_spent: float = 0.0
	var last_wave_gold_purchases: int = 0
	var last_wave_essence_income: float = 0.0
	var last_wave_essence_spent: float = 0.0
	var last_wave_essence_purchases: int = 0

	func _init(profile: StringName = PROFILE_CHEAPEST) -> void:
		if PROFILE_CONFIGS.has(profile):
			spend_profile = profile
			profile_config = PROFILE_CONFIGS[profile]

	func process_wave(wave: int) -> void:
		if wave < current_wave:
			return
		var guard: int = 0
		while current_wave <= wave and guard < MAX_ATTEMPTS_PER_TARGET_WAVE:
			guard += 1
			_process_current_wave_attempt()
		if current_wave <= wave:
			stalled = true

	func _process_current_wave_attempt() -> void:
		last_wave_gold_income = 0.0
		last_wave_gold_spent = 0.0
		last_wave_gold_purchases = 0
		last_wave_essence_income = 0.0
		last_wave_essence_spent = 0.0
		last_wave_essence_purchases = 0

		if not _can_clear_wave(current_wave):
			_on_death(current_wave)
			return

		var counts: Dictionary = _wave_enemy_counts(current_wave)
		var reward_mul: float = _wave_reward_multiplier(current_wave)
		for kind in counts.keys():
			var c: int = int(counts[kind])
			var gold_per: float = GameConstants.ENEMY_REWARD_GOLD * reward_mul * _boss_gold_mult(kind)
			var ess_per: float = GameConstants.ENEMY_REWARD_ESSENCE * reward_mul * _boss_ess_mult(kind)
			var wave_gold: float = gold_per * c
			var wave_ess: float = ess_per * c
			gold += wave_gold
			essence += wave_ess
			last_wave_gold_income += wave_gold
			last_wave_essence_income += wave_ess
			echo_collected += GameState.get_echo_gain_for_enemy(kind, current_wave) * c

		# apex artifact grant
		if current_wave % 100 == 0:
			artifacts_owned += 1
			artifact_levels += 1

		_spend_gold()
		_spend_essence()
		furthest_wave_reached = maxi(furthest_wave_reached, current_wave)
		current_wave += 1

	func make_row(wave: int) -> Dictionary:
		var hero: CombatStats = _hero_stats()
		var enemy_normal: Dictionary = _enemy_stats(wave, &"normal")
		var enemy_apex: Dictionary = _enemy_stats(wave, &"apex")
		var hit_chance: float = CombatStats.compute_hit_chance(hero.accuracy, float(enemy_normal["evasion"]))
		var proc_mult: float = _proc_dps_multiplier()
		var effective_dps: float = hero.compute_dps() * hit_chance * proc_mult
		return {
			"profile": String(spend_profile),
			"wave": wave,
			"gold": int(gold),
			"essence": int(essence),
			"wave_gold_income": int(round(last_wave_gold_income)),
			"wave_gold_spent": int(round(last_wave_gold_spent)),
			"wave_gold_purchases": last_wave_gold_purchases,
			"wave_essence_income": int(round(last_wave_essence_income)),
			"wave_essence_spent": int(round(last_wave_essence_spent)),
			"wave_essence_purchases": last_wave_essence_purchases,
			"equip": equipment.duplicate(true),
			"artifacts_owned": artifacts_owned,
			"artifact_levels": artifact_levels,
			"echo_power": int(echo_power),
			"echo_collected": int(echo_collected),
			"run_index": run_index,
			"death_count": death_count,
			"first_death_wave": first_death_wave,
			"latest_death_wave": latest_death_wave,
			"furthest_wave_reached": furthest_wave_reached,
			"stalled": stalled,
			"hero_dps": effective_dps,
			"normal_hp": enemy_normal["hp"],
			"normal_ttk": enemy_normal["hp"] / maxf(1.0, effective_dps),
			"apex_hp": enemy_apex["hp"],
			"apex_ttk": enemy_apex["hp"] / maxf(1.0, effective_dps),
		}

	func _can_clear_wave(wave: int) -> bool:
		var hero: CombatStats = _hero_stats()
		var wave_dps: float = _hero_effective_dps_against_wave(hero, wave)
		var counts: Dictionary = _wave_enemy_counts(wave)
		var total_enemy_hp: float = 0.0
		var peak_enemy_pressure: float = 0.0
		for kind in counts.keys():
			var count: int = int(counts[kind])
			if count <= 0:
				continue
			var enemy_stats: Dictionary = _enemy_stats(wave, kind)
			total_enemy_hp += float(enemy_stats["hp"]) * count
			peak_enemy_pressure += _enemy_threat_dps(enemy_stats, hero) * _peak_active_count_for_kind(kind, count, wave) * _enemy_contact_uptime(kind, wave)
		var clear_time: float = total_enemy_hp / maxf(1.0, wave_dps)
		clear_time *= _wave_clear_time_factor(wave, counts)
		var hero_ehp: float = hero.max_hp * (1.0 + maxf(0.0, hero.defense) / 100.0)
		var pressure_budget: float = peak_enemy_pressure * clear_time
		var sustain_budget: float = hero_ehp * _survival_tolerance(hero, wave)
		return pressure_budget <= sustain_budget

	func _hero_effective_dps_against_wave(hero: CombatStats, wave: int) -> float:
		var normal_enemy: Dictionary = _enemy_stats(wave, &"normal")
		var hit_chance: float = CombatStats.compute_hit_chance(hero.accuracy, float(normal_enemy["evasion"]))
		var dps: float = hero.compute_dps() * hit_chance * _proc_dps_multiplier()
		return dps

	func _enemy_threat_dps(enemy_stats: Dictionary, hero: CombatStats) -> float:
		var hit_chance: float = CombatStats.compute_hit_chance(float(enemy_stats["accuracy"]), hero.evasion)
		var per_hit: float = CombatStats.apply_defense(float(enemy_stats["damage"]), hero.defense)
		return (per_hit / GameConstants.ENEMY_ATTACK_COOLDOWN) * hit_chance

	func _peak_active_count_for_kind(kind: StringName, total_count: int, wave: int) -> float:
		var max_active: int = GameConstants.MAX_ACTIVE_ENEMIES + int(floor(float(maxi(0, wave - 1)) / float(GameConstants.ACTIVE_ENEMY_WAVE_STEP)))
		match kind:
			&"normal":
				return minf(float(total_count), float(max_active))
			&"wave":
				return 1.0
			&"mini", &"grand", &"apex":
				return 1.0
			_:
				return 0.0

	func _enemy_contact_uptime(kind: StringName, wave: int) -> float:
		var base: float = 0.0
		match kind:
			&"normal":
				base = 0.045
			&"wave":
				base = 0.085
			&"mini":
				base = 0.110
			&"grand":
				base = 0.135
			&"apex":
				base = 0.165
			_:
				base = 0.050
		var pressure_ramp: float = 1.0 + minf(0.90, float(wave) / 600.0)
		return base * pressure_ramp

	func _wave_clear_time_factor(wave: int, counts: Dictionary) -> float:
		var normal_count: int = int(counts.get(&"normal", 0))
		var factor: float = 0.72 + minf(1.10, normal_count / 85.0)
		if wave % 5 == 0:
			factor += 0.10
		if wave % 10 == 0:
			factor += 0.06
		if wave % 100 == 0:
			factor += 0.12
		return factor

	func _survival_tolerance(hero: CombatStats, wave: int) -> float:
		var block_bonus: float = 1.0 + _get_helm_block_chance() * 0.75
		var evade_bonus: float = 1.0 + clampf(hero.evasion / 220.0, 0.0, 0.45)
		var utility_bonus: float = 1.0 + _get_boots_haste_chance() * 0.25 + _get_amulet_teleport_chance() * 0.35 + _get_relic_clone_chance() * 0.20
		var milestone_penalty: float = 1.0
		if wave % 5 == 0:
			milestone_penalty -= 0.08
		if wave % 10 == 0:
			milestone_penalty -= 0.05
		if wave % 100 == 0:
			milestone_penalty -= 0.10
		return maxf(0.85, block_bonus * evade_bonus * utility_bonus * milestone_penalty)

	func _on_death(wave: int) -> void:
		death_count += 1
		latest_death_wave = wave
		if first_death_wave < 0:
			first_death_wave = wave
		echo_power += echo_collected
		echo_collected = 0.0
		run_index += 1
		current_wave = 1

	func _spend_gold() -> void:
		var guard_limit: int = int(profile_config.get("gold_spend_limit", 500))
		var guard: int = 0
		while guard < guard_limit:
			guard += 1
			var unlock_id: StringName = _select_next_unlock()
			if unlock_id != &"":
				var unlock_cost: float = float(GameState.get_equipment_unlock_cost(unlock_id))
				if gold >= unlock_cost:
					gold -= unlock_cost
					last_wave_gold_spent += unlock_cost
					last_wave_gold_purchases += 1
					equipment_unlocked[unlock_id] = true
					continue
			var next_id: StringName = _select_next_equipment()
			if next_id == &"":
				break
			var cost: float = _equipment_cost(next_id)
			if gold < cost:
				break
			gold -= cost
			last_wave_gold_spent += cost
			last_wave_gold_purchases += 1
			equipment[next_id] = int(equipment[next_id]) + 1

	func _spend_essence() -> void:
		if artifacts_owned <= 0:
			return
		var guard_limit: int = int(profile_config.get("essence_spend_limit", 200))
		var guard: int = 0
		while guard < guard_limit:
			guard += 1
			var cost: int = 35 + artifact_levels * 20
			if essence < cost:
				break
			essence -= cost
			last_wave_essence_spent += cost
			last_wave_essence_purchases += 1
			artifact_levels += 1

	func _select_next_equipment() -> StringName:
		var ids: Array[StringName] = [&"weapon", &"helm", &"chest", &"gloves", &"boots", &"ring", &"amulet", &"relic"]
		var weights: Dictionary = profile_config.get("weights", {})
		var best: StringName = &""
		var best_score: float = INF
		for i in range(ids.size()):
			var id: StringName = ids[i]
			if not _is_unlocked_by_rule(i):
				continue
			var cost: float = _equipment_cost(id)
			var w: float = float(weights.get(id, 1.0))
			w *= _unlock_pressure_weight(i)
			var score: float = cost / maxf(0.0001, w)
			if score < best_score:
				best_score = score
				best = id
		return best

	func _unlock_pressure_weight(idx: int) -> float:
		return 1.0

	func _is_unlocked_by_rule(idx: int) -> bool:
		var ids: Array[StringName] = [&"weapon", &"helm", &"chest", &"gloves", &"boots", &"ring", &"amulet", &"relic"]
		return bool(equipment_unlocked.get(ids[idx], idx == 0))

	func _select_next_unlock() -> StringName:
		var ids: Array[StringName] = [&"helm", &"chest", &"gloves", &"boots", &"ring", &"amulet", &"relic"]
		var weights: Dictionary = profile_config.get("weights", {})
		var best: StringName = &""
		var best_score: float = INF
		for id in ids:
			if bool(equipment_unlocked.get(id, false)):
				continue
			var unlock_cost: float = float(GameState.get_equipment_unlock_cost(id))
			if unlock_cost <= 0.0:
				continue
			var w: float = float(weights.get(id, 1.0))
			var score: float = unlock_cost / maxf(0.0001, w * 1.35)
			if score < best_score:
				best_score = score
				best = id
		return best

	func _equipment_cost(id: StringName) -> float:
		var idx: int = [&"weapon", &"helm", &"chest", &"gloves", &"boots", &"ring", &"amulet", &"relic"].find(id)
		var base_cost: float = float(GameState.EQUIPMENT_DEFS[id]["base_cost"])
		var level: int = int(equipment[id])
		if idx <= 0:
			return _cost_curve(base_cost, level)
		# Keep simulator aligned with runtime formula:
		# entry upgrade cost for non-weapon items scales from unlock price.
		var unlock_cost: float = float(GameState.get_equipment_unlock_cost(id))
		var anchor: float = maxf(base_cost, unlock_cost * 0.30)
		return _cost_curve(anchor, level)

	func _cost_curve(base_cost: float, level: int) -> float:
		var l0: int = mini(level, GameConstants.BALANCE_COST_PHASE1_CAP)
		var l1: int = mini(maxi(0, level - GameConstants.BALANCE_COST_PHASE1_CAP), GameConstants.BALANCE_COST_PHASE2_CAP - GameConstants.BALANCE_COST_PHASE1_CAP)
		var l2: int = maxi(0, level - GameConstants.BALANCE_COST_PHASE2_CAP)
		var c: float = base_cost
		c *= pow(GameConstants.BALANCE_COST_PHASE1_RATE, l0)
		c *= pow(GameConstants.BALANCE_COST_PHASE2_RATE, l1)
		c *= pow(GameConstants.BALANCE_COST_PHASE3_RATE, l2)
		return c

	func _hero_stats() -> CombatStats:
		var s: CombatStats = CombatStats.new()
		var w: int = int(equipment[&"weapon"])
		var h: int = int(equipment[&"helm"])
		var c: int = int(equipment[&"chest"])
		var g: int = int(equipment[&"gloves"])
		var b: int = int(equipment[&"boots"])
		var r: int = int(equipment[&"ring"])
		var a: int = int(equipment[&"amulet"])
		var re: int = int(equipment[&"relic"])
		var w50: float = floor(float(w) / 50.0)
		var h50: float = floor(float(h) / 50.0)
		var c50: float = floor(float(c) / 50.0)
		var g50: float = floor(float(g) / 50.0)
		var b50: float = floor(float(b) / 50.0)
		var r50: float = floor(float(r) / 50.0)
		var a50: float = floor(float(a) / 50.0)
		var w100: float = floor(float(w) / 100.0)
		var h100: float = floor(float(h) / 100.0)
		var c100: float = floor(float(c) / 100.0)
		var g100: float = floor(float(g) / 100.0)
		var b100: float = floor(float(b) / 100.0)
		var r100: float = floor(float(r) / 100.0)
		var a100: float = floor(float(a) / 100.0)
		var re100: float = floor(float(re) / 100.0)
		var w1000: float = floor(float(w) / 1000.0)
		var h1000: float = floor(float(h) / 1000.0)
		var c1000: float = floor(float(c) / 1000.0)
		var g1000: float = floor(float(g) / 1000.0)
		var b1000: float = floor(float(b) / 1000.0)
		var r1000: float = floor(float(r) / 1000.0)
		var a1000: float = floor(float(a) / 1000.0)
		var re1000: float = floor(float(re) / 1000.0)

		s.damage = GameConstants.HERO_BASE_DAMAGE
		s.max_hp = GameConstants.HERO_BASE_HP
		s.attack_speed = GameConstants.HERO_BASE_ATTACK_SPEED
		s.crit_chance = GameConstants.HERO_BASE_CRIT_CHANCE
		s.crit_multiplier = GameConstants.HERO_BASE_CRIT_MULTIPLIER
		s.defense = GameConstants.HERO_BASE_DEFENSE
		s.evasion = GameConstants.HERO_BASE_EVASION
		s.accuracy = GameConstants.HERO_BASE_ACCURACY

		s.damage += w * (0.16 + w50 * 0.0035)
		s.max_hp += h * (0.42 + h50 * 0.009) + c * (0.74 + c50 * 0.012)
		s.attack_speed += g * (0.0018 + g50 * 0.00004)
		s.evasion += b * (0.034 + b50 * 0.0008)
		s.accuracy += r * (0.06 + r50 * 0.0012) + a * (0.046 + a50 * 0.0009)
		s.defense += h * (0.055 + h50 * 0.0012) + c * (0.095 + c50 * 0.0017)
		s.crit_chance += r * (0.000002 + r50 * 0.00000001)
		s.crit_multiplier += a * (0.00009 + a50 * 0.0000003)

		s.crit_multiplier += w100 * 0.0035
		s.defense += h100 * 0.42 + c100 * 0.62
		s.crit_chance += g100 * 0.0012 + r100 * 0.0012
		s.attack_speed += b100 * 0.0022
		s.damage += a100 * 0.3
		s.accuracy += re100 * 0.3

		s.damage += w1000 * 28.0 + a1000 * 12.0
		s.crit_multiplier += w1000 * 0.07
		s.max_hp += h1000 * 72.0 + c1000 * 105.0
		s.defense += h1000 * 9.0 + c1000 * 13.0
		s.attack_speed += g1000 * 0.05
		s.evasion += b1000 * 6.5
		s.crit_chance += r1000 * 0.015
		s.accuracy += re1000 * 10.0

		# artifacts approximation (owned artifacts + total levels)
		var L: float = float(artifact_levels)
		s.damage += L * 0.9 + maxf(0.0, L - 1.0) * 0.25
		s.max_hp += L * 7.0
		s.attack_speed += L * 0.01
		s.accuracy += L * 0.6
		s.defense += maxf(0.0, L - 4.0) * 0.08
		s.evasion += maxf(0.0, L - 4.0) * 0.05

		# echo active bonuses use the same tier model as runtime game logic.
		var echo_bonus: Dictionary = GameState.get_echo_tier_bonuses(int(echo_power))
		s.damage += float(echo_bonus.get("damage", 0.0))
		s.max_hp += float(echo_bonus.get("max_hp", 0.0))
		s.attack_speed += float(echo_bonus.get("attack_speed", 0.0))
		s.crit_chance += float(echo_bonus.get("crit_chance", 0.0))
		s.crit_multiplier += float(echo_bonus.get("crit_multiplier", 0.0))
		s.defense += float(echo_bonus.get("defense", 0.0))
		s.evasion += float(echo_bonus.get("evasion", 0.0))
		s.accuracy += float(echo_bonus.get("accuracy", 0.0))

		s.crit_chance = clampf(s.crit_chance, 0.0, GameConstants.HERO_MAX_CRIT_CHANCE)
		s.crit_multiplier = clampf(s.crit_multiplier, 1.0, GameConstants.HERO_MAX_CRIT_MULTIPLIER)
		return s

	func _proc_dps_multiplier() -> float:
		var ring: float = floor(float(int(equipment[&"ring"])) / 100.0)
		var relic: float = floor(float(int(equipment[&"relic"])) / 100.0)
		var boots: float = floor(float(int(equipment[&"boots"])) / 100.0)
		var repeat_chance: float = _soft_cap(ring * 0.0013, 0.12, 0.20)
		var clone_chance: float = _soft_cap(relic * 0.0009, 0.08, 0.18)
		var clone_power: float = minf(0.70, 0.40 + floor(float(int(equipment[&"relic"])) / 500.0) * 0.005)
		var haste_chance: float = _soft_cap(boots * 0.0025, 0.20, 0.40)
		var haste_uptime: float = minf(0.45, haste_chance * 2.5)
		return 1.0 + repeat_chance + clone_chance * clone_power + haste_uptime * 0.5

	func _get_helm_block_chance() -> float:
		var tiers: float = floor(float(int(equipment[&"helm"])) / 100.0)
		return _soft_cap(tiers * 0.0025, 0.20, 0.40)

	func _get_boots_haste_chance() -> float:
		var tiers: float = floor(float(int(equipment[&"boots"])) / 100.0)
		return _soft_cap(tiers * 0.0025, 0.20, 0.40)

	func _get_amulet_teleport_chance() -> float:
		var tiers: float = floor(float(int(equipment[&"amulet"])) / 100.0)
		return _soft_cap(tiers * 0.0014, 0.10, 0.20)

	func _get_relic_clone_chance() -> float:
		var tiers: float = floor(float(int(equipment[&"relic"])) / 100.0)
		return _soft_cap(tiers * 0.0009, 0.08, 0.18)

	func _soft_cap(v: float, soft: float, hard: float) -> float:
		if v <= soft:
			return minf(v, hard)
		return minf(hard, soft + (v - soft) * 0.5)

	func _wave_reward_multiplier(wave: int) -> float:
		return GameConstants.progressive_wave_multiplier(
			wave - 1,
			GameConstants.BALANCE_WAVE_REWARD_EARLY,
			GameConstants.BALANCE_WAVE_REWARD_MID,
			GameConstants.BALANCE_WAVE_REWARD_LATE
		)

	func _enemy_stats(wave: int, kind: StringName) -> Dictionary:
		var hp_mul: float = GameConstants.progressive_wave_multiplier(
			wave - 1,
			GameConstants.BALANCE_WAVE_HP_EARLY,
			GameConstants.BALANCE_WAVE_HP_MID,
			GameConstants.BALANCE_WAVE_HP_LATE
		)
		var dmg_mul: float = GameConstants.progressive_wave_multiplier(
			wave - 1,
			GameConstants.BALANCE_WAVE_DMG_EARLY,
			GameConstants.BALANCE_WAVE_DMG_MID,
			GameConstants.BALANCE_WAVE_DMG_LATE
		)
		var eva_mul: float = GameConstants.progressive_wave_multiplier(
			wave - 1,
			GameConstants.BALANCE_WAVE_EVA_EARLY,
			GameConstants.BALANCE_WAVE_EVA_MID,
			GameConstants.BALANCE_WAVE_EVA_LATE
		)
		var acc_mul: float = GameConstants.progressive_wave_multiplier(
			wave - 1,
			GameConstants.BALANCE_WAVE_ACC_EARLY,
			GameConstants.BALANCE_WAVE_ACC_MID,
			GameConstants.BALANCE_WAVE_ACC_LATE
		)
		var hp: float = GameConstants.ENEMY_BASE_HP * hp_mul * _boss_hp_mult(kind)
		var dmg: float = GameConstants.ENEMY_BASE_DAMAGE * dmg_mul * _boss_dmg_mult(kind)
		var eva: float = minf(GameConstants.ENEMY_MAX_EVASION, GameConstants.ENEMY_BASE_EVASION * eva_mul)
		var acc: float = GameConstants.ENEMY_BASE_ACCURACY * acc_mul
		return {"hp": hp, "damage": dmg, "evasion": eva, "accuracy": acc}

	func _wave_enemy_counts(wave: int) -> Dictionary:
		var normal: int = GameConstants.BASE_NORMAL_ENEMIES_PER_WAVE + int(floor((wave - 1) / 2.0)) + (wave - 1)
		var counts: Dictionary = {&"normal": normal, &"wave": 1, &"mini": 0, &"grand": 0, &"apex": 0}
		if wave % 5 == 0:
			if wave % 100 == 0:
				counts[&"apex"] = 1
			elif wave % 10 == 0:
				counts[&"grand"] = 1
			else:
				counts[&"mini"] = 1
		return counts

	func _boss_hp_mult(kind: StringName) -> float:
		match kind:
			&"wave": return GameConstants.WAVE_BOSS_HP_MULTIPLIER
			&"mini": return GameConstants.MINI_BOSS_HP_MULTIPLIER
			&"grand": return GameConstants.GRAND_BOSS_HP_MULTIPLIER
			&"apex": return GameConstants.APEX_BOSS_HP_MULTIPLIER
			_: return 1.0

	func _boss_dmg_mult(kind: StringName) -> float:
		match kind:
			&"wave": return GameConstants.WAVE_BOSS_DAMAGE_MULTIPLIER
			&"mini": return GameConstants.MINI_BOSS_DAMAGE_MULTIPLIER
			&"grand": return GameConstants.GRAND_BOSS_DAMAGE_MULTIPLIER
			&"apex": return GameConstants.APEX_BOSS_DAMAGE_MULTIPLIER
			_: return 1.0

	func _boss_gold_mult(kind: StringName) -> float:
		match kind:
			&"wave": return GameConstants.WAVE_BOSS_REWARD_GOLD_MULTIPLIER
			&"mini": return GameConstants.MINI_BOSS_REWARD_GOLD_MULTIPLIER
			&"grand": return GameConstants.GRAND_BOSS_REWARD_GOLD_MULTIPLIER
			&"apex": return GameConstants.APEX_BOSS_REWARD_GOLD_MULTIPLIER
			_: return 1.0

	func _boss_ess_mult(kind: StringName) -> float:
		match kind:
			&"wave": return GameConstants.WAVE_BOSS_REWARD_ESSENCE_MULTIPLIER
			&"mini": return GameConstants.MINI_BOSS_REWARD_ESSENCE_MULTIPLIER
			&"grand": return GameConstants.GRAND_BOSS_REWARD_ESSENCE_MULTIPLIER
			&"apex": return GameConstants.APEX_BOSS_REWARD_ESSENCE_MULTIPLIER
			_: return 1.0
