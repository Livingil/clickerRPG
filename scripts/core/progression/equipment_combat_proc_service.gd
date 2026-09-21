extends RefCounted
class_name EquipmentCombatProcService

static func tick_state(state: Dictionary, delta: float) -> Dictionary:
	var out: Dictionary = state.duplicate(true)
	out["repeat_action_icd_left"] = maxf(0.0, float(out.get("repeat_action_icd_left", 0.0)) - delta)
	out["teleport_icd_left"] = maxf(0.0, float(out.get("teleport_icd_left", 0.0)) - delta)
	out["haste_icd_left"] = maxf(0.0, float(out.get("haste_icd_left", 0.0)) - delta)
	out["clone_icd_left"] = maxf(0.0, float(out.get("clone_icd_left", 0.0)) - delta)
	out["haste_buff_time_left"] = maxf(0.0, float(out.get("haste_buff_time_left", 0.0)) - delta)
	out["clone_buff_time_left"] = maxf(0.0, float(out.get("clone_buff_time_left", 0.0)) - delta)
	return out

static func tick_game_state(game_state: Object, delta: float) -> void:
	apply_state_to_game_state(game_state, tick_state(build_state_from_game_state(game_state), delta))

static func should_block_incoming_hit(equipment_levels: Dictionary, artifact_bonus_block_chance: float) -> bool:
	return randf() < EquipmentProgressRules.get_helm_block_chance(equipment_levels, artifact_bonus_block_chance)

static func get_reflect_chance(equipment_levels: Dictionary, artifact_bonus_reflect_chance: float) -> float:
	return EquipmentProgressRules.get_chest_reflect_chance(equipment_levels, artifact_bonus_reflect_chance)

static func get_reflect_ratio(equipment_levels: Dictionary, artifact_bonus_reflect_ratio: float) -> float:
	return EquipmentProgressRules.get_gloves_reflect_ratio(equipment_levels, artifact_bonus_reflect_ratio)

static func get_hp_regen_percent_per_sec(equipment_levels: Dictionary) -> float:
	return EquipmentProgressRules.get_chest_hp_regen_percent_per_sec(equipment_levels)

static func get_hp_regen_per_sec(equipment_levels: Dictionary, max_hp: float) -> float:
	return maxf(0.0, max_hp * get_hp_regen_percent_per_sec(equipment_levels))

static func get_hero_move_speed(equipment_levels: Dictionary) -> float:
	return EquipmentProgressRules.get_hero_move_speed(equipment_levels)

static func get_runtime_attack_speed_multiplier(state: Dictionary) -> float:
	return 1.5 if float(state.get("haste_buff_time_left", 0.0)) > 0.0 else 1.0

static func get_clone_attack_multiplier(state: Dictionary) -> float:
	return float(state.get("clone_stat_multiplier", 0.0)) if float(state.get("clone_buff_time_left", 0.0)) > 0.0 else 0.0

static func get_runtime_attack_speed_multiplier_for_game_state(game_state: Object) -> float:
	return get_runtime_attack_speed_multiplier(build_state_from_game_state(game_state))

static func get_clone_attack_multiplier_for_game_state(game_state: Object) -> float:
	return get_clone_attack_multiplier(build_state_from_game_state(game_state))

static func trigger_repeat_action(
	state: Dictionary,
	equipment_levels: Dictionary,
	artifact_bonus_repeat_chance: float
) -> Dictionary:
	var out: Dictionary = state.duplicate(true)
	if float(out.get("repeat_action_icd_left", 0.0)) > 0.0:
		return {"triggered": false, "state": out}
	var chance: float = EquipmentProgressRules.get_ring_repeat_chance(equipment_levels, artifact_bonus_repeat_chance)
	if randf() >= chance:
		return {"triggered": false, "state": out}
	out["repeat_action_icd_left"] = 1.5
	return {"triggered": true, "state": out}

static func trigger_repeat_action_for_game_state(game_state: Object) -> bool:
	var result: Dictionary = trigger_repeat_action(
		build_state_from_game_state(game_state),
		game_state.equipment_levels,
		game_state.get_bonus_total("artifact_bonus_repeat_chance")
	)
	apply_state_to_game_state(game_state, result.get("state", build_state_from_game_state(game_state)))
	return bool(result.get("triggered", false))

static func apply_hero_damage_reactions(
	state: Dictionary,
	equipment_levels: Dictionary,
	artifact_bonuses: Dictionary,
	hero: Node2D,
	attacker: Enemy,
	damage_taken: float
) -> Dictionary:
	var out: Dictionary = state.duplicate(true)
	if hero == null:
		return out
	if randf() < EquipmentProgressRules.get_boots_haste_chance(equipment_levels, float(artifact_bonuses.get("haste_chance", 0.0))) and float(out.get("haste_icd_left", 0.0)) <= 0.0:
		out["haste_icd_left"] = 4.0
		out["haste_buff_time_left"] = maxf(
			float(out.get("haste_buff_time_left", 0.0)),
			EquipmentProgressRules.get_boots_haste_duration(equipment_levels, float(artifact_bonuses.get("haste_duration", 0.0)))
		)
	if randf() < EquipmentProgressRules.get_amulet_teleport_chance(equipment_levels, float(artifact_bonuses.get("teleport_chance", 0.0))) and float(out.get("teleport_icd_left", 0.0)) <= 0.0:
		out["teleport_icd_left"] = 8.0
		hero.global_position = find_safe_teleport_position(hero)
	if randf() < EquipmentProgressRules.get_relic_clone_chance(equipment_levels, float(artifact_bonuses.get("clone_chance", 0.0))) and float(out.get("clone_icd_left", 0.0)) <= 0.0:
		out["clone_icd_left"] = 8.0
		out["clone_buff_time_left"] = maxf(
			float(out.get("clone_buff_time_left", 0.0)),
			EquipmentProgressRules.get_relic_clone_duration(equipment_levels, float(artifact_bonuses.get("clone_duration", 0.0)))
		)
		out["clone_stat_multiplier"] = maxf(
			float(out.get("clone_stat_multiplier", 0.0)),
			EquipmentProgressRules.get_relic_clone_stat_multiplier(equipment_levels, float(artifact_bonuses.get("clone_stats", 0.0)))
		)
	if attacker != null and is_instance_valid(attacker):
		var reflect_chance: float = EquipmentProgressRules.get_chest_reflect_chance(equipment_levels, float(artifact_bonuses.get("reflect_chance", 0.0)))
		if randf() < reflect_chance:
			var reflect_ratio: float = EquipmentProgressRules.get_gloves_reflect_ratio(equipment_levels, float(artifact_bonuses.get("reflect_ratio", 0.0)))
			attacker.take_damage(damage_taken * reflect_ratio)
	return out

static func apply_hero_damage_reactions_for_game_state(
	game_state: Object,
	hero: Node2D,
	attacker: Enemy,
	damage_taken: float
) -> void:
	apply_state_to_game_state(game_state, apply_hero_damage_reactions(
		build_state_from_game_state(game_state),
		game_state.equipment_levels,
		build_artifact_proc_bonuses_from_game_state(game_state),
		hero,
		attacker,
		damage_taken
	))

static func build_state_from_game_state(game_state: Object) -> Dictionary:
	return {
		"repeat_action_icd_left": game_state.repeat_action_icd_left,
		"haste_buff_time_left": game_state.haste_buff_time_left,
		"clone_buff_time_left": game_state.clone_buff_time_left,
		"clone_stat_multiplier": game_state.clone_stat_multiplier,
		"teleport_icd_left": game_state.teleport_icd_left,
		"haste_icd_left": game_state.haste_icd_left,
		"clone_icd_left": game_state.clone_icd_left,
	}

static func apply_state_to_game_state(game_state: Object, state: Dictionary) -> void:
	game_state.repeat_action_icd_left = float(state.get("repeat_action_icd_left", game_state.repeat_action_icd_left))
	game_state.haste_buff_time_left = float(state.get("haste_buff_time_left", game_state.haste_buff_time_left))
	game_state.clone_buff_time_left = float(state.get("clone_buff_time_left", game_state.clone_buff_time_left))
	game_state.clone_stat_multiplier = float(state.get("clone_stat_multiplier", game_state.clone_stat_multiplier))
	game_state.teleport_icd_left = float(state.get("teleport_icd_left", game_state.teleport_icd_left))
	game_state.haste_icd_left = float(state.get("haste_icd_left", game_state.haste_icd_left))
	game_state.clone_icd_left = float(state.get("clone_icd_left", game_state.clone_icd_left))

static func build_artifact_proc_bonuses_from_game_state(game_state: Object) -> Dictionary:
	return {
		"reflect_chance": game_state.get_bonus_total("artifact_bonus_reflect_chance"),
		"reflect_ratio": game_state.get_bonus_total("artifact_bonus_reflect_ratio"),
		"haste_chance": game_state.get_bonus_total("artifact_bonus_haste_chance"),
		"haste_duration": game_state.get_bonus_total("artifact_bonus_haste_duration"),
		"teleport_chance": game_state.get_bonus_total("artifact_bonus_teleport_chance"),
		"clone_chance": game_state.get_bonus_total("artifact_bonus_clone_chance"),
		"clone_duration": game_state.get_bonus_total("artifact_bonus_clone_duration"),
		"clone_stats": game_state.get_bonus_total("artifact_bonus_clone_stat_multiplier"),
	}

static func find_safe_teleport_position(hero: Node2D) -> Vector2:
	var origin: Vector2 = hero.global_position
	var enemies: Array[Node] = hero.get_tree().get_nodes_in_group("enemies")
	var best: Vector2 = origin
	var best_score: float = -INF
	for _i in range(16):
		var candidate: Vector2 = Vector2(
			randf_range(GameConstants.ARENA_MIN.x + 28.0, GameConstants.ARENA_MAX.x - 28.0),
			randf_range(GameConstants.ARENA_MIN.y + 28.0, GameConstants.ARENA_MAX.y - 28.0)
		)
		var nearest: float = INF
		for enemy in enemies:
			if enemy is not Enemy or not is_instance_valid(enemy):
				continue
			var dist: float = candidate.distance_to((enemy as Enemy).global_position)
			if dist < nearest:
				nearest = dist
		if nearest > best_score:
			best_score = nearest
			best = candidate
	return best
