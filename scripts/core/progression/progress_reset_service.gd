extends RefCounted
class_name ProgressResetService

static func reset_run_progress(game_state: Variant) -> void:
	game_state.gold = 0
	game_state.essence = 0
	game_state.echo_collected = 0
	game_state.echo_power = 0
	game_state.current_run_wave = 1
	game_state.highest_wave_reached = 1
	game_state.total_deaths = 0
	game_state.best_run_time_sec = 0.0
	game_state.incoming_hits_since_absorb = 0
	game_state.pending_weapon_skill_offers.clear()
	game_state.repeat_action_icd_left = 0.0
	game_state.haste_buff_time_left = 0.0
	game_state.clone_buff_time_left = 0.0
	game_state.clone_stat_multiplier = 0.0
	game_state.teleport_icd_left = 0.0
	game_state.haste_icd_left = 0.0
	game_state.clone_icd_left = 0.0
	game_state.current_ad_boost_offer.clear()
	game_state.active_ad_boosts.clear()
	game_state._apply_game_speed_time_scale()
	game_state.ad_offer_time_left = 0.0
	game_state.ad_offer_cooldown_left = 0.0
	game_state.pending_offline_reward_report.clear()
	for equipment_id in EquipmentRules.ORDER:
		game_state.equipment_levels[equipment_id] = 0
		game_state.equipment_unlocked[equipment_id] = equipment_id == &"weapon"
	game_state.upgrade_levels.clear()

static func reset_all_progress(game_state: Variant) -> void:
	reset_run_progress(game_state)
	game_state.prestige_count = 0
	game_state.prestige_shards = 0
	game_state.prestige_shards_earned_total = 0
	game_state.last_prestige_report.clear()
	game_state.last_run_death_report.clear()
	for prestige_upgrade_id in PrestigeRules.UPGRADE_ORDER:
		game_state.prestige_upgrade_levels[prestige_upgrade_id] = 0
	game_state.highest_wave_reached = 1
	game_state.current_run_wave = 1
	game_state.active_school = SchoolRules.SCHOOL_FIRE
	for school_id: StringName in SchoolRules.SCHOOL_ORDER:
		game_state.school_mastery_xp[school_id] = 0
	game_state.equipped_skill_ids.clear()
	game_state.unlocked_global_skill_ids.clear()
	game_state.owned_artifacts.clear()
	game_state.defeated_apex_wave_rewards.clear()
	for artifact_id in ArtifactRules.ARTIFACT_POOL:
		game_state.artifact_levels[artifact_id] = 0
	for skill_id_variant in SchoolRules.SKILL_DEFINITIONS.keys():
		var skill_id: StringName = skill_id_variant as StringName
		game_state.skill_upgrade_levels[skill_id] = {"dmg": 0, "cd": 0, "proc": 0}
	for school_id: StringName in SchoolRules.SCHOOL_ORDER:
		game_state.weapon_school_upgrade_levels[school_id] = 0
	game_state.shown_info_event_keys.clear()
	game_state.last_save_unix = Time.get_unix_time_from_system()
	game_state.pending_offline_reward_report.clear()
