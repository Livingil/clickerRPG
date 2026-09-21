extends RefCounted
class_name AdBoostStateRules

static func build_offer(boost_id: StringName) -> Dictionary:
	if not AdBoostRules.has_boost(boost_id):
		return {}
	return {
		"id": boost_id,
		"time_left": AdBoostRules.OFFER_VISIBLE_SEC,
		"duration": AdBoostRules.get_duration(boost_id),
	}

static func build_active_snapshot(active_boosts: Dictionary, language: StringName) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for boost_id_variant in active_boosts.keys():
		var boost_id: StringName = boost_id_variant as StringName
		rows.append({
			"id": boost_id,
			"time_left": float(active_boosts.get(boost_id, 0.0)),
			"duration": AdBoostRules.get_duration(boost_id),
			"name": AdBoostRules.get_display_name(boost_id, language),
			"short": AdBoostRules.get_short_text(boost_id, language),
		})
	return rows

static func tick_active_boosts(active_boosts: Dictionary, delta: float) -> Dictionary:
	var next_active: Dictionary = active_boosts.duplicate(true)
	var expired: Array[StringName] = []
	var expired_stat_boost: bool = false
	for boost_id_variant in active_boosts.keys():
		var boost_id: StringName = boost_id_variant as StringName
		var time_left: float = maxf(0.0, float(active_boosts[boost_id]) - delta)
		if time_left <= 0.0:
			expired.append(boost_id)
			next_active.erase(boost_id)
			if is_stat_boost(boost_id):
				expired_stat_boost = true
		else:
			next_active[boost_id] = time_left
	return {
		"active_boosts": next_active,
		"expired": expired,
		"expired_stat_boost": expired_stat_boost,
	}

static func build_saved_active_boosts(source: Variant, elapsed_sec: int) -> Dictionary:
	var active_boosts: Dictionary = {}
	if source is not Dictionary:
		return active_boosts
	var source_dict: Dictionary = source as Dictionary
	for key in source_dict.keys():
		var boost_id: StringName = StringName(String(key))
		if not AdBoostRules.has_boost(boost_id):
			continue
		var remaining: float = maxf(0.0, float(source_dict[key]) - float(elapsed_sec))
		if remaining > 0.0:
			active_boosts[boost_id] = remaining
	return active_boosts

static func is_stat_boost(boost_id: StringName) -> bool:
	return boost_id == AdBoostRules.BATTLE_FOCUS or boost_id == AdBoostRules.HASTE_SPARK
