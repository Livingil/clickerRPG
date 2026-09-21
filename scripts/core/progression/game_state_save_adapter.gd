extends RefCounted
class_name GameStateSaveAdapter

static func build_save_data(game_state: Variant, save_version: int) -> Dictionary:
	game_state.last_save_unix = Time.get_unix_time_from_system()
	return {
		"version": save_version,
		"server_revision": game_state.server_revision,
		"last_save_unix": game_state.last_save_unix,
		"gold": game_state.gold,
		"essence": game_state.essence,
		"echo_collected": game_state.echo_collected,
		"echo_power": game_state.echo_power,
		"current_run_wave": game_state.current_run_wave,
		"highest_wave_reached": game_state.highest_wave_reached,
		"total_deaths": game_state.total_deaths,
		"best_run_time_sec": game_state.best_run_time_sec,
		"prestige_count": game_state.prestige_count,
		"prestige_shards": game_state.prestige_shards,
		"prestige_shards_earned_total": game_state.prestige_shards_earned_total,
		"prestige_upgrade_levels": SaveDataCodec.string_keyed_dict(game_state.prestige_upgrade_levels),
		"active_school": String(game_state.active_school),
		"school_mastery_xp": SaveDataCodec.string_keyed_dict(game_state.school_mastery_xp),
		"equipped_skill_ids": SaveDataCodec.string_array(game_state.equipped_skill_ids),
		"show_damage_text": game_state.show_damage_text,
		"show_crit_text": game_state.show_crit_text,
		"show_miss_text": game_state.show_miss_text,
		"show_hero_damage_text": game_state.show_hero_damage_text,
		"show_hero_miss_text": game_state.show_hero_miss_text,
		"current_language": String(game_state.current_language),
		"equipment_levels": SaveDataCodec.string_keyed_dict(game_state.equipment_levels),
		"equipment_unlocked": SaveDataCodec.string_keyed_dict(game_state.equipment_unlocked),
		"artifact_levels": SaveDataCodec.string_keyed_dict(game_state.artifact_levels),
		"owned_artifacts": SaveDataCodec.string_array(game_state.owned_artifacts),
		"defeated_apex_wave_rewards": game_state.defeated_apex_wave_rewards.duplicate(),
		"skill_upgrade_levels": SaveDataCodec.string_keyed_dict(game_state.skill_upgrade_levels),
		"weapon_school_upgrade_levels": SaveDataCodec.string_keyed_dict(game_state.weapon_school_upgrade_levels),
		"pending_weapon_skill_offer_schools": serialize_pending_weapon_skill_offer_schools(game_state.pending_weapon_skill_offers),
		"active_ad_boosts": SaveDataCodec.string_keyed_dict(game_state.active_ad_boosts),
		"shown_info_event_keys": game_state.shown_info_event_keys.duplicate(),
	}

static func apply_save_data(game_state: Variant, data: Dictionary, save_version: int) -> void:
	if data.is_empty():
		return
	data = migrate_save_data(data, save_version)
	var now_unix: int = Time.get_unix_time_from_system()
	var saved_unix: int = int(data.get("last_save_unix", 0))
	game_state.server_revision = maxi(0, int(data.get("server_revision", game_state.server_revision)))
	if Engine.has_singleton("BackendClient"):
		BackendClient.server_revision = maxi(BackendClient.server_revision, game_state.server_revision)

	game_state.gold = maxi(0, int(data.get("gold", game_state.gold)))
	game_state.essence = maxi(0, int(data.get("essence", game_state.essence)))
	game_state.echo_collected = maxi(0, int(data.get("echo_collected", game_state.echo_collected)))
	game_state.echo_power = maxi(0, int(data.get("echo_power", game_state.echo_power)))
	game_state.highest_wave_reached = maxi(1, int(data.get("highest_wave_reached", game_state.highest_wave_reached)))
	game_state.current_run_wave = maxi(1, int(data.get("current_run_wave", game_state.highest_wave_reached)))
	if game_state.current_run_wave > game_state.highest_wave_reached:
		game_state.highest_wave_reached = game_state.current_run_wave
	game_state.total_deaths = maxi(0, int(data.get("total_deaths", game_state.total_deaths)))
	game_state.best_run_time_sec = maxf(0.0, float(data.get("best_run_time_sec", game_state.best_run_time_sec)))
	game_state.prestige_count = maxi(0, int(data.get("prestige_count", game_state.prestige_count)))
	game_state.prestige_shards = maxi(0, int(data.get("prestige_shards", game_state.prestige_shards)))
	game_state.prestige_shards_earned_total = maxi(game_state.prestige_shards, int(data.get("prestige_shards_earned_total", game_state.prestige_shards_earned_total)))
	SaveDataCodec.apply_int_dict(data.get("prestige_upgrade_levels", {}), game_state.prestige_upgrade_levels, PrestigeRules.UPGRADE_ORDER)

	var saved_school: StringName = StringName(String(data.get("active_school", game_state.active_school)))
	if SchoolRules.SCHOOL_DEFINITIONS.has(saved_school):
		game_state.active_school = saved_school

	SaveDataCodec.apply_int_dict(data.get("school_mastery_xp", {}), game_state.school_mastery_xp, SchoolRules.SCHOOL_ORDER)
	game_state.equipped_skill_ids = SaveDataCodec.parse_string_name_array(data.get("equipped_skill_ids", []))
	game_state.equipped_skill_ids = game_state.equipped_skill_ids.filter(func(skill_id: StringName) -> bool:
		return skill_id == &"" or SchoolRules.SKILL_DEFINITIONS.has(skill_id)
	)

	game_state.show_damage_text = bool(data.get("show_damage_text", game_state.show_damage_text))
	game_state.show_crit_text = bool(data.get("show_crit_text", game_state.show_crit_text))
	game_state.show_miss_text = bool(data.get("show_miss_text", game_state.show_miss_text))
	game_state.show_hero_damage_text = bool(data.get("show_hero_damage_text", game_state.show_hero_damage_text))
	game_state.show_hero_miss_text = bool(data.get("show_hero_miss_text", game_state.show_hero_miss_text))

	var saved_language: StringName = StringName(String(data.get("current_language", game_state.current_language)))
	if LocalizationRules.has_language(saved_language):
		game_state.current_language = saved_language

	SaveDataCodec.apply_int_dict(data.get("equipment_levels", {}), game_state.equipment_levels, EquipmentRules.ORDER)
	SaveDataCodec.apply_bool_dict(data.get("equipment_unlocked", {}), game_state.equipment_unlocked, EquipmentRules.ORDER)
	game_state.equipment_unlocked[&"weapon"] = true
	SaveDataCodec.apply_int_dict(data.get("artifact_levels", {}), game_state.artifact_levels, ArtifactRules.ARTIFACT_POOL)
	game_state.owned_artifacts = SaveDataCodec.parse_string_name_array(data.get("owned_artifacts", []))
	game_state.owned_artifacts = game_state.owned_artifacts.filter(func(artifact_id: StringName) -> bool:
		return ArtifactRules.ARTIFACT_POOL.has(artifact_id)
	)
	game_state.defeated_apex_wave_rewards = SaveDataCodec.parse_int_array(data.get("defeated_apex_wave_rewards", []))
	apply_skill_upgrade_levels(data.get("skill_upgrade_levels", {}), game_state.skill_upgrade_levels)
	SaveDataCodec.apply_int_dict(data.get("weapon_school_upgrade_levels", {}), game_state.weapon_school_upgrade_levels, SchoolRules.SCHOOL_ORDER)
	game_state.pending_weapon_skill_offers = parse_pending_weapon_skill_offers(data.get("pending_weapon_skill_offer_schools", []), game_state.current_language)
	game_state.shown_info_event_keys = SaveDataCodec.parse_string_array(data.get("shown_info_event_keys", []))
	var offline_report: Variant = data.get("pending_offline_reward_report", {})
	if offline_report is Dictionary:
		game_state.pending_offline_reward_report = offline_report as Dictionary
	else:
		game_state.pending_offline_reward_report = {}

	game_state.current_ad_boost_offer.clear()
	game_state.ad_offer_time_left = 0.0
	game_state.ad_offer_cooldown_left = 0.0
	game_state.active_ad_boosts.clear()
	game_state._apply_game_speed_time_scale()
	game_state._rebuild_all_bonuses()
	if not bool(data.get("server_authoritative", false)):
		game_state._apply_offline_rewards(saved_unix, now_unix)
	game_state._apply_saved_active_ad_boosts(data.get("active_ad_boosts", {}), maxi(0, now_unix - saved_unix))
	game_state._rebuild_school_state()
	game_state.last_save_unix = now_unix

static func migrate_save_data(data: Dictionary, save_version: int) -> Dictionary:
	return SaveDataCodec.migrate(data, save_version)

static func serialize_pending_weapon_skill_offer_schools(pending_weapon_skill_offers: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for offer_variant in pending_weapon_skill_offers:
		var offer: Dictionary = offer_variant as Dictionary
		var school_id: StringName = offer.get("school_id", &"") as StringName
		if SchoolRules.SCHOOL_DEFINITIONS.has(school_id):
			out.append(String(school_id))
	return out

static func parse_pending_weapon_skill_offers(source: Variant, language: StringName) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	if source is not Array:
		return offers
	for value in source:
		var school_id: StringName = StringName(String(value))
		if not SchoolRules.SCHOOL_DEFINITIONS.has(school_id):
			continue
		offers.append({
			"school_id": school_id,
			"text": EquipmentProgressRules.format_weapon_school_offer_text(school_id, language),
		})
		if offers.size() >= 3:
			break
	return offers

static func apply_skill_upgrade_levels(source: Variant, skill_upgrade_levels: Dictionary) -> void:
	if source is not Dictionary:
		return
	var source_dict: Dictionary = source as Dictionary
	for skill_key in source_dict.keys():
		var skill_id: StringName = StringName(String(skill_key))
		if not SchoolRules.SKILL_DEFINITIONS.has(skill_id):
			continue
		var raw_data: Variant = source_dict[skill_key]
		if raw_data is not Dictionary:
			continue
		var raw_dict: Dictionary = raw_data as Dictionary
		skill_upgrade_levels[skill_id] = {
			"dmg": maxi(0, int(raw_dict.get("dmg", 0))),
			"cd": maxi(0, int(raw_dict.get("cd", 0))),
			"proc": maxi(0, int(raw_dict.get("proc", 0))),
		}
