extends RefCounted
class_name AdBoostService

static func has_active(active_boosts: Dictionary, boost_id: StringName) -> bool:
	return float(active_boosts.get(boost_id, 0.0)) > 0.0

static func get_time_left(active_boosts: Dictionary, boost_id: StringName) -> float:
	return float(active_boosts.get(boost_id, 0.0))

static func accept_offer(current_offer: Dictionary) -> Dictionary:
	if current_offer.is_empty():
		return {"boost_id": &"", "offer": {}, "offer_time_left": 0.0, "offer_cooldown_left": AdBoostRules.OFFER_INTERVAL_SEC}
	var boost_id: StringName = current_offer.get("id", &"") as StringName
	return {
		"boost_id": boost_id,
		"offer": {},
		"offer_time_left": 0.0,
		"offer_cooldown_left": AdBoostRules.OFFER_INTERVAL_SEC,
	}

static func dismiss_offer() -> Dictionary:
	return {
		"offer": {},
		"offer_time_left": 0.0,
		"offer_cooldown_left": AdBoostRules.OFFER_INTERVAL_SEC,
	}

static func tick(
	active_boosts: Dictionary,
	current_offer: Dictionary,
	offer_time_left: float,
	offer_cooldown_left: float,
	delta: float
) -> Dictionary:
	var active_result: Dictionary = AdBoostStateRules.tick_active_boosts(active_boosts, delta)
	var next_offer: Dictionary = current_offer.duplicate(true)
	var next_offer_time_left: float = offer_time_left
	var next_offer_cooldown_left: float = offer_cooldown_left
	var offer_changed: bool = false

	if next_offer.is_empty():
		next_offer_cooldown_left = maxf(0.0, next_offer_cooldown_left - delta)
		if next_offer_cooldown_left <= 0.0:
			var boost_id: StringName = AdBoostRules.roll_offer_id()
			if boost_id != &"":
				next_offer = AdBoostStateRules.build_offer(boost_id)
				next_offer_time_left = AdBoostRules.OFFER_VISIBLE_SEC
				offer_changed = true
	else:
		next_offer_time_left = maxf(0.0, next_offer_time_left - delta)
		next_offer["time_left"] = next_offer_time_left
		if next_offer_time_left <= 0.0:
			next_offer.clear()
			next_offer_time_left = 0.0
			next_offer_cooldown_left = AdBoostRules.OFFER_INTERVAL_SEC
			offer_changed = true

	return {
		"active_boosts": active_result.get("active_boosts", {}),
		"expired": active_result.get("expired", []),
		"expired_stat_boost": bool(active_result.get("expired_stat_boost", false)),
		"offer": next_offer,
		"offer_time_left": next_offer_time_left,
		"offer_cooldown_left": next_offer_cooldown_left,
		"offer_changed": offer_changed,
	}

static func activate(active_boosts: Dictionary, boost_id: StringName) -> Dictionary:
	if not AdBoostRules.has_boost(boost_id):
		return {"active_boosts": active_boosts, "activated": false, "stat_boost": false}
	var next_active: Dictionary = active_boosts.duplicate(true)
	var duration: float = AdBoostRules.get_duration(boost_id)
	if duration > 0.0:
		next_active[boost_id] = maxf(float(next_active.get(boost_id, 0.0)), duration)
	return {
		"active_boosts": next_active,
		"activated": duration > 0.0,
		"stat_boost": AdBoostStateRules.is_stat_boost(boost_id),
	}

static func apply_reward_multiplier(active_boosts: Dictionary, value: int, boost_id: StringName) -> int:
	var clamped_value: int = maxi(0, value)
	if has_active(active_boosts, boost_id):
		return clamped_value * 2
	return clamped_value

static func accept_offer_on_game_state(game_state: Object) -> StringName:
	var result: Dictionary = accept_offer_state(build_state_from_game_state(game_state))
	apply_result_to_game_state(game_state, result)
	return result.get("boost_id", &"") as StringName

static func activate_game_speed_on_game_state(game_state: Object) -> void:
	apply_result_to_game_state(game_state, activate_state(build_state_from_game_state(game_state), AdBoostRules.GAME_SPEED))

static func dismiss_offer_on_game_state(game_state: Object) -> void:
	apply_result_to_game_state(game_state, dismiss_offer_state(build_state_from_game_state(game_state)))

static func tick_game_state(game_state: Object, delta: float) -> void:
	apply_result_to_game_state(game_state, tick_state(build_state_from_game_state(game_state), delta))

static func build_state_from_game_state(game_state: Object) -> Dictionary:
	return {
		"active_ad_boosts": game_state.active_ad_boosts,
		"current_ad_boost_offer": game_state.current_ad_boost_offer,
		"ad_offer_time_left": game_state.ad_offer_time_left,
		"ad_offer_cooldown_left": game_state.ad_offer_cooldown_left,
	}

static func apply_result_to_game_state(game_state: Object, result: Dictionary) -> void:
	var state: Dictionary = result.get("state", {})
	game_state.active_ad_boosts = state.get("active_ad_boosts", game_state.active_ad_boosts)
	game_state.current_ad_boost_offer = state.get("current_ad_boost_offer", game_state.current_ad_boost_offer)
	game_state.ad_offer_time_left = float(state.get("ad_offer_time_left", game_state.ad_offer_time_left))
	game_state.ad_offer_cooldown_left = float(state.get("ad_offer_cooldown_left", game_state.ad_offer_cooldown_left))
	if bool(result.get("game_speed_changed", false)):
		_apply_game_speed_time_scale(game_state.active_ad_boosts)
	if bool(result.get("active_changed", false)):
		game_state.ad_boosts_changed.emit()
	if bool(result.get("stat_changed", false)):
		game_state.hero_stats_changed.emit()
	if bool(result.get("offer_changed", false)):
		game_state.ad_boost_offer_changed.emit(game_state.get_current_ad_boost_offer())

static func apply_game_speed_time_scale(active_boosts: Dictionary) -> void:
	_apply_game_speed_time_scale(active_boosts)

static func _apply_game_speed_time_scale(active_boosts: Dictionary) -> void:
	Engine.time_scale = 2.0 if has_active(active_boosts, AdBoostRules.GAME_SPEED) else 1.0

static func accept_offer_state(state: Dictionary) -> Dictionary:
	var accepted: Dictionary = accept_offer(state.get("current_ad_boost_offer", {}))
	var boost_id: StringName = accepted.get("boost_id", &"") as StringName
	var next_state: Dictionary = _with_offer_result(state, accepted)
	var result: Dictionary = {
		"state": next_state,
		"boost_id": boost_id,
		"offer_changed": true,
		"active_changed": false,
		"stat_changed": false,
		"game_speed_changed": false,
	}
	if boost_id == &"":
		return result
	return _merge_activation_result(result, activate_state(next_state, boost_id))

static func dismiss_offer_state(state: Dictionary) -> Dictionary:
	return {
		"state": _with_offer_result(state, dismiss_offer()),
		"offer_changed": true,
		"active_changed": false,
		"stat_changed": false,
		"game_speed_changed": false,
	}

static func activate_state(state: Dictionary, boost_id: StringName) -> Dictionary:
	var activated: Dictionary = activate(state.get("active_ad_boosts", {}), boost_id)
	var next_state: Dictionary = state.duplicate(true)
	next_state["active_ad_boosts"] = activated.get("active_boosts", state.get("active_ad_boosts", {}))
	var changed: bool = bool(activated.get("activated", false))
	return {
		"state": next_state,
		"offer_changed": false,
		"active_changed": changed,
		"stat_changed": bool(activated.get("stat_boost", false)),
		"game_speed_changed": changed and boost_id == AdBoostRules.GAME_SPEED,
	}

static func tick_state(state: Dictionary, delta: float) -> Dictionary:
	var ticked: Dictionary = tick(
		state.get("active_ad_boosts", {}),
		state.get("current_ad_boost_offer", {}),
		float(state.get("ad_offer_time_left", 0.0)),
		float(state.get("ad_offer_cooldown_left", 0.0)),
		delta
	)
	var next_state: Dictionary = _with_offer_result(state, ticked)
	next_state["active_ad_boosts"] = ticked.get("active_boosts", {})
	var expired: Array[StringName] = ticked.get("expired", [])
	return {
		"state": next_state,
		"offer_changed": bool(ticked.get("offer_changed", false)),
		"active_changed": not expired.is_empty(),
		"stat_changed": bool(ticked.get("expired_stat_boost", false)),
		"game_speed_changed": expired.has(AdBoostRules.GAME_SPEED),
	}

static func _with_offer_result(state: Dictionary, result: Dictionary) -> Dictionary:
	var out: Dictionary = state.duplicate(true)
	out["current_ad_boost_offer"] = result.get("offer", {})
	out["ad_offer_time_left"] = float(result.get("offer_time_left", 0.0))
	out["ad_offer_cooldown_left"] = float(result.get("offer_cooldown_left", AdBoostRules.OFFER_INTERVAL_SEC))
	return out

static func _merge_activation_result(base_result: Dictionary, activation_result: Dictionary) -> Dictionary:
	var out: Dictionary = base_result.duplicate(true)
	out["state"] = activation_result.get("state", base_result.get("state", {}))
	out["active_changed"] = bool(base_result.get("active_changed", false)) or bool(activation_result.get("active_changed", false))
	out["stat_changed"] = bool(base_result.get("stat_changed", false)) or bool(activation_result.get("stat_changed", false))
	out["game_speed_changed"] = bool(base_result.get("game_speed_changed", false)) or bool(activation_result.get("game_speed_changed", false))
	return out
