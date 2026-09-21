extends Node
signal resources_changed(gold: int, essence: int)
signal echo_changed(collected_echo: int, active_echo_power: int)
signal hero_stats_changed
signal upgrades_changed
signal school_state_changed
signal school_mastery_changed
signal school_mastery_level_reached(report: Dictionary)
signal prestige_performed
signal prestige_report_ready(report: Dictionary)
signal run_death_report_ready(report: Dictionary)
signal prestige_unlocked(report: Dictionary)
signal skill_slot_unlocked(report: Dictionary)
signal milestone_boss_reward_granted(report: Dictionary)
signal combat_text_settings_changed
signal language_changed
signal ad_boost_offer_changed(offer: Dictionary)
signal ad_boosts_changed
signal offline_rewards_granted(report: Dictionary)

const PrestigeRulesData = preload("res://scripts/core/progression/prestige_rules.gd")
const AdBoostRulesData = preload("res://scripts/core/progression/ad_boost_rules.gd")
const EchoRulesData = preload("res://scripts/core/progression/echo_rules.gd")
const LocalizationRulesData = preload("res://scripts/core/progression/localization_rules.gd")
const SchoolProgressRulesData = preload("res://scripts/core/progression/school_progress_rules.gd")
const AdBoostStateRulesData = preload("res://scripts/core/progression/ad_boost_state_rules.gd")
const EquipmentProgressRulesData = preload("res://scripts/core/progression/equipment_progress_rules.gd")
const HeroStatsBuilderData = preload("res://scripts/core/stats/hero_stats_builder.gd")
const AdBoostServiceData = preload("res://scripts/core/progression/ad_boost_service.gd")
const PrestigeServiceData = preload("res://scripts/core/progression/prestige_service.gd")
const GameStateSaveAdapterData = preload("res://scripts/core/progression/game_state_save_adapter.gd")
const ProgressResetServiceData = preload("res://scripts/core/progression/progress_reset_service.gd")
const PlayerBonusBuilderData = preload("res://scripts/core/progression/player_bonus_builder.gd")
const RunDeathReportBuilderData = preload("res://scripts/core/progression/run_death_report_builder.gd")
const SkillPowerServiceData = preload("res://scripts/core/progression/skill_power_service.gd")
const EchoProgressServiceData = preload("res://scripts/core/progression/echo_progress_service.gd")
const EquipmentCombatProcServiceData = preload("res://scripts/core/progression/equipment_combat_proc_service.gd")
const SchoolStateServiceData = preload("res://scripts/core/progression/school_state_service.gd")
const InventoryProgressServiceData = preload("res://scripts/core/progression/inventory_progress_service.gd")
const ResourceProgressServiceData = preload("res://scripts/core/progression/resource_progress_service.gd")
const GameStateLifecycleServiceData = preload("res://scripts/core/progression/game_state_lifecycle_service.gd")
const WaveProgressServiceData = preload("res://scripts/core/progression/wave_progress_service.gd")

const SAVE_VERSION: int = 2
var gold: int = 0
var essence: int = 0
var echo_collected: int = 0
var echo_power: int = 0
var current_run_wave: int = 1
var highest_wave_reached: int = 1
var total_deaths: int = 0
var best_run_time_sec: float = 0.0
var prestige_count: int = 0
var prestige_shards: int = 0
var prestige_shards_earned_total: int = 0
var prestige_upgrade_levels: Dictionary = {}
var last_prestige_report: Dictionary = {}
var last_run_death_report: Dictionary = {}
var active_school: StringName = SchoolRules.SCHOOL_FIRE
var school_mastery_xp: Dictionary = {}
var unlocked_global_skill_ids: Array[StringName] = []
var equipped_skill_ids: Array[StringName] = []
var show_damage_text: bool = true
var show_crit_text: bool = true
var show_miss_text: bool = true
var show_hero_damage_text: bool = true
var show_hero_miss_text: bool = true
var current_language: StringName = &"ru"
var equipment_levels: Dictionary = {}
var equipment_unlocked: Dictionary = {}
var artifact_levels: Dictionary = {}
var owned_artifacts: Array[StringName] = []
var defeated_apex_wave_rewards: Array[int] = []
var incoming_hits_since_absorb: int = 0
var pending_weapon_skill_offers: Array[Dictionary] = []
var skill_upgrade_levels: Dictionary = {}
var weapon_school_upgrade_levels: Dictionary = {}
var shown_info_event_keys: Array[String] = []
var repeat_action_icd_left: float = 0.0
var haste_buff_time_left: float = 0.0
var clone_buff_time_left: float = 0.0
var clone_stat_multiplier: float = 0.0
var teleport_icd_left: float = 0.0
var haste_icd_left: float = 0.0
var clone_icd_left: float = 0.0
var ad_offer_cooldown_left: float = 0.0
var ad_offer_time_left: float = 0.0
var current_ad_boost_offer: Dictionary = {}
var active_ad_boosts: Dictionary = {}
var last_save_unix: int = 0
var server_revision: int = 0
var pending_offline_reward_report: Dictionary = {}

var bonus_totals: Dictionary = {}

var upgrade_levels: Dictionary = {}

func _ready() -> void:
	set_process(true)
	GameStateLifecycleServiceData.initialize_defaults(self)
	SignalBus.wave_changed.connect(_on_wave_changed)
	_rebuild_all_bonuses()
	_rebuild_school_state()

func _process(delta: float) -> void:
	EquipmentCombatProcServiceData.tick_game_state(self, delta)
	_tick_ad_boosts(_get_unscaled_delta(delta))

func add_gold(value: int) -> void:
	ResourceProgressServiceData.add_gold_to_game_state(self, value)

func add_essence(value: int) -> void:
	ResourceProgressServiceData.add_essence_to_game_state(self, value)

func add_echo(value: int) -> void:
	ResourceProgressServiceData.add_echo_to_game_state(self, value)

func register_run_death(run_time_sec: float) -> void:
	var result: Dictionary = ResourceProgressServiceData.build_run_death_result(
		total_deaths,
		best_run_time_sec,
		run_time_sec
	)
	total_deaths = int(result.get("total_deaths", total_deaths))
	best_run_time_sec = float(result.get("best_run_time_sec", best_run_time_sec))
	upgrades_changed.emit()

func build_run_death_report(run_time_sec: float, echo_before: int, echo_after: int, collected_echo: int) -> Dictionary:
	return RunDeathReportBuilderData.build_on_game_state(self, run_time_sec, echo_before, echo_after, collected_echo)

func emit_run_death_report(report: Dictionary) -> void:
	RunDeathReportBuilderData.emit_on_game_state(self, report)

func format_duration_short(seconds: float) -> String:
	var total: int = maxi(0, int(floor(seconds)))
	var hours: int = int(floor(float(total) / 3600.0))
	var mins: int = int(floor(float(total % 3600) / 60.0))
	var secs: int = total % 60
	if hours > 0:
		return "%02d:%02d:%02d" % [hours, mins, secs]
	return "%02d:%02d" % [mins, secs]

func build_hero_stats() -> CombatStats:
	return HeroStatsBuilderData.build_current_from_game_state(self)

func get_hero_dps() -> float:
	return build_hero_stats().compute_dps()

func get_school_ids() -> Array[StringName]:
	return SchoolProgressRulesData.get_school_ids()

func get_school_definition(school_id: StringName) -> Dictionary:
	return SchoolProgressRulesData.get_school_definition(school_id)

func get_active_school_summary() -> Dictionary:
	return SchoolProgressRulesData.build_active_school_summary(active_school, school_mastery_xp)

func get_school_mastery_xp(school_id: StringName) -> int:
	return SchoolProgressRulesData.get_school_mastery_xp(school_id, school_mastery_xp)

func get_school_mastery_level(school_id: StringName) -> int:
	return SchoolProgressRulesData.get_school_mastery_level(school_id, school_mastery_xp)

func get_school_core_mastery_level(school_id: StringName) -> int:
	return SchoolProgressRulesData.get_school_core_mastery_level(school_id, school_mastery_xp)

func get_school_mastery_skill_bonuses(school_id: StringName) -> Dictionary:
	var level: int = get_school_core_mastery_level(school_id)
	return SchoolProgressRulesData.get_school_mastery_skill_bonuses(school_id, level)

func add_active_school_mastery_xp(value: int) -> void:
	add_school_mastery_xp(active_school, value)

func add_school_mastery_xp(school_id: StringName, value: int) -> void:
	if BackendClient.queue_school_xp(school_id, value):
		return
	if not BackendClient.should_apply_local_progress_fallback():
		return
	SchoolStateServiceData.add_mastery_xp_to_game_state(self, school_id, value)

func set_active_school(school_id: StringName) -> void:
	SchoolStateServiceData.set_active_school_on_game_state(self, school_id)

func get_permanent_skill_slot_count() -> int:
	return SchoolProgressRulesData.get_permanent_skill_slot_count(highest_wave_reached, GameConstants.DEV_UNLOCK_ALL_SKILLS)

func get_available_skill_ids() -> Array[StringName]:
	return SchoolProgressRulesData.get_available_skill_ids(active_school, school_mastery_xp, unlocked_global_skill_ids, GameConstants.DEV_UNLOCK_ALL_SKILLS)

func get_equipped_skill_ids() -> Array[StringName]:
	return equipped_skill_ids.duplicate()

func equip_skill(slot_index: int, skill_id: StringName) -> bool:
	return SchoolStateServiceData.equip_skill_on_game_state(self, slot_index, skill_id)

func equip_skill_to_first_open_slot(skill_id: StringName) -> bool:
	return SchoolStateServiceData.equip_skill_to_first_open_slot_on_game_state(self, skill_id)

func clear_skill_slot(slot_index: int) -> bool:
	return SchoolStateServiceData.clear_skill_slot_on_game_state(self, slot_index)

func replace_skill(slot_index: int, skill_id: StringName) -> bool:
	return SchoolStateServiceData.replace_skill_on_game_state(self, slot_index, skill_id)

func activate_collected_echo() -> void:
	EchoProgressServiceData.activate_collected_on_game_state(self)

func get_echo_tier_bonuses(echo_value: int) -> Dictionary:
	return EchoRulesData.get_tier_bonuses(echo_value)

func get_echo_progress_info(echo_value: int) -> Dictionary:
	return EchoRulesData.get_progress_info(echo_value)

func get_active_echo_bonuses() -> Dictionary:
	return get_echo_tier_bonuses(echo_power)

func get_collected_echo_bonuses() -> Dictionary:
	return get_echo_tier_bonuses(echo_collected)

func set_combat_text_settings(show_damage: bool, show_crit: bool, show_miss: bool, show_hero_damage: bool = true, show_hero_miss: bool = true) -> void:
	show_damage_text = show_damage
	show_crit_text = show_crit
	show_miss_text = show_miss
	show_hero_damage_text = show_hero_damage
	show_hero_miss_text = show_hero_miss
	combat_text_settings_changed.emit()

func unlock_equipment(equipment_id: StringName) -> bool:
	return InventoryProgressServiceData.unlock_equipment_on_game_state(self, equipment_id)

func get_equipment_ui_rows() -> Array[Dictionary]:
	return InventoryProgressServiceData.build_equipment_ui_rows_for_game_state(self)

func get_equipment_level(equipment_id: StringName) -> int:
	return int(equipment_levels.get(equipment_id, 0))

func buy_equipment_upgrade(equipment_id: StringName) -> bool:
	return InventoryProgressServiceData.buy_equipment_upgrade_on_game_state(self, equipment_id)

func buy_artifact_upgrade(artifact_id: StringName) -> bool:
	return InventoryProgressServiceData.buy_artifact_upgrade_on_game_state(self, artifact_id)

func get_artifact_ui_rows() -> Array[Dictionary]:
	return InventoryProgressServiceData.build_artifact_ui_rows_for_game_state(self)

func register_apex_boss_kill(wave_number: int) -> void:
	if not BackendClient.should_apply_local_progress_fallback():
		return
	InventoryProgressServiceData.register_apex_boss_kill_on_game_state(self, wave_number)

func should_block_incoming_hit() -> bool:
	return EquipmentCombatProcServiceData.should_block_incoming_hit(equipment_levels, get_bonus_total("artifact_bonus_block_chance"))

func get_chest_hp_regen_percent_per_sec() -> float:
	return EquipmentCombatProcServiceData.get_hp_regen_percent_per_sec(equipment_levels)

func get_hero_hp_regen_per_sec(max_hp: float) -> float:
	return EquipmentCombatProcServiceData.get_hp_regen_per_sec(equipment_levels, max_hp)

func get_hero_move_speed() -> float:
	return EquipmentCombatProcServiceData.get_hero_move_speed(equipment_levels)

func should_trigger_repeat_action() -> bool:
	return EquipmentCombatProcServiceData.trigger_repeat_action_for_game_state(self)

func get_runtime_attack_speed_multiplier() -> float:
	return EquipmentCombatProcServiceData.get_runtime_attack_speed_multiplier_for_game_state(self)

func get_clone_attack_multiplier() -> float:
	return EquipmentCombatProcServiceData.get_clone_attack_multiplier_for_game_state(self)

func _get_unscaled_delta(delta: float) -> float:
	return delta / maxf(Engine.time_scale, 0.001)

func has_active_ad_boost(boost_id: StringName) -> bool:
	return AdBoostServiceData.has_active(active_ad_boosts, boost_id)

func get_active_ad_boost_time_left(boost_id: StringName) -> float:
	return AdBoostServiceData.get_time_left(active_ad_boosts, boost_id)

func get_current_ad_boost_offer() -> Dictionary:
	return current_ad_boost_offer.duplicate(true)

func get_active_ad_boosts_snapshot() -> Array[Dictionary]:
	return AdBoostStateRulesData.build_active_snapshot(active_ad_boosts, current_language)

func get_ad_boost_display_name(boost_id: StringName) -> String:
	return AdBoostRulesData.get_display_name(boost_id, current_language)

func get_ad_boost_short_text(boost_id: StringName) -> String:
	return AdBoostRulesData.get_short_text(boost_id, current_language)

func accept_ad_boost_offer() -> StringName:
	return AdBoostServiceData.accept_offer_on_game_state(self)

func accept_game_speed_ad_boost() -> void:
	AdBoostServiceData.activate_game_speed_on_game_state(self)

func dismiss_ad_boost_offer() -> void:
	AdBoostServiceData.dismiss_offer_on_game_state(self)

func _tick_ad_boosts(delta: float) -> void:
	AdBoostServiceData.tick_game_state(self, delta)

func _apply_game_speed_time_scale() -> void:
	AdBoostServiceData.apply_game_speed_time_scale(active_ad_boosts)

func get_pending_offline_reward_report() -> Dictionary:
	return pending_offline_reward_report.duplicate(true)

func clear_pending_offline_reward_report() -> void:
	pending_offline_reward_report.clear()

func _apply_offline_rewards(saved_unix: int, now_unix: int) -> void:
	ResourceProgressServiceData.apply_offline_rewards_to_game_state(self, saved_unix, now_unix)

func on_hero_damaged(hero: Node2D, attacker: Enemy, damage_taken: float) -> void:
	EquipmentCombatProcServiceData.apply_hero_damage_reactions_for_game_state(self, hero, attacker, damage_taken)

func get_skill_damage_multiplier(skill_id: StringName) -> float:
	return SkillPowerServiceData.get_damage_multiplier_for_game_state(self, skill_id)

func get_skill_cooldown_multiplier(skill_id: StringName) -> float:
	return SkillPowerServiceData.get_cooldown_multiplier_for_game_state(self, skill_id)

func get_skill_proc_multiplier(skill_id: StringName) -> float:
	return SkillPowerServiceData.get_proc_multiplier_for_game_state(self, skill_id)

func get_pending_weapon_skill_offers() -> Array[Dictionary]:
	return pending_weapon_skill_offers.duplicate(true)

func apply_weapon_skill_offer(offer_index: int) -> bool:
	return SkillPowerServiceData.apply_weapon_skill_offer_on_game_state(self, offer_index)

func set_language(language_code: StringName) -> void:
	if not LocalizationRulesData.has_language(language_code):
		return
	if current_language == language_code:
		return
	current_language = language_code
	language_changed.emit()

func loc(key: String) -> String:
	return LocalizationRulesData.translate(current_language, key)

func get_echo_gain_for_enemy(boss_kind: StringName, wave_number: int = -1) -> int:
	var wave: int = wave_number if wave_number > 0 else highest_wave_reached
	return ResourceProgressServiceData.get_echo_gain_for_enemy(boss_kind, wave)

func _apply_upgrade_bonuses() -> void:
	PlayerBonusBuilderData.apply_to_game_state(self, PlayerBonusBuilderData.build(
		equipment_levels,
		artifact_levels,
		owned_artifacts
	))

func get_bonus_total(stat_key: String, default_value: float = 0.0) -> float:
	return float(bonus_totals.get(stat_key, default_value))

func _rebuild_all_bonuses() -> void:
	_apply_upgrade_bonuses()

func _try_generate_weapon_skill_offers(previous_level: int, new_level: int) -> void:
	pending_weapon_skill_offers = SkillPowerServiceData.maybe_roll_weapon_skill_offers(
		pending_weapon_skill_offers,
		previous_level,
		new_level,
		current_language
	)

func _get_weapon_school_focus_summary() -> String:
	return EquipmentProgressRulesData.get_weapon_school_focus_summary(weapon_school_upgrade_levels, current_language)

func _get_school_display_name(school_id: StringName) -> String:
	return EquipmentProgressRulesData.get_school_display_name(school_id, current_language)

func can_perform_prestige() -> bool:
	return PrestigeRulesData.can_perform(highest_wave_reached)

func get_prestige_unlock_wave() -> int:
	return PrestigeRulesData.UNLOCK_WAVE

func get_prestige_unlock_text() -> String:
	return PrestigeRulesData.get_unlock_text(current_language)

func perform_prestige() -> bool:
	return PrestigeServiceData.perform_prestige_on_game_state(self)

func build_prestige_preview_report() -> Dictionary:
	return PrestigeServiceData.build_preview_report(
		highest_wave_reached,
		prestige_count,
		prestige_shards,
		prestige_shards_earned_total,
		get_school_xp_multiplier(),
		current_language
	)

func get_prestige_shards_for_current_run() -> int:
	return PrestigeRulesData.get_shards_for_wave(highest_wave_reached)

func get_prestige_panel_data() -> Dictionary:
	return PrestigeServiceData.build_panel_data(
		build_prestige_preview_report(),
		prestige_upgrade_levels,
		prestige_shards,
		prestige_shards_earned_total,
		prestige_count,
		can_perform_prestige(),
		get_prestige_unlock_text(),
		current_language
	)

func get_last_prestige_report() -> Dictionary:
	return last_prestige_report.duplicate(true)

func get_last_run_death_report() -> Dictionary:
	return last_run_death_report.duplicate(true)

func get_prestige_upgrade_level(upgrade_id: StringName) -> int:
	return PrestigeServiceData.get_upgrade_level(prestige_upgrade_levels, upgrade_id)

func buy_prestige_upgrade(upgrade_id: StringName) -> bool:
	var result: Dictionary = PrestigeServiceData.buy_upgrade(prestige_upgrade_levels, upgrade_id, prestige_shards)
	if not bool(result.get("success", false)):
		return false
	prestige_shards = int(result.get("prestige_shards", prestige_shards))
	hero_stats_changed.emit()
	upgrades_changed.emit()
	return true

func get_prestige_attack_multiplier() -> float:
	return PrestigeServiceData.get_attack_multiplier(prestige_upgrade_levels)

func get_prestige_hp_multiplier() -> float:
	return PrestigeServiceData.get_hp_multiplier(prestige_upgrade_levels)

func get_prestige_defense_multiplier() -> float:
	return PrestigeServiceData.get_defense_multiplier(prestige_upgrade_levels)

func get_prestige_crit_chance_bonus() -> float:
	return PrestigeServiceData.get_crit_chance_bonus(prestige_upgrade_levels)

func get_prestige_crit_multiplier_bonus() -> float:
	return PrestigeServiceData.get_crit_multiplier_bonus(prestige_upgrade_levels)

func get_school_xp_multiplier() -> float:
	return PrestigeServiceData.get_school_xp_multiplier(prestige_upgrade_levels, prestige_shards_earned_total, get_bonus_total("artifact_bonus_school_xp_mult"))

func get_gold_multiplier() -> float:
	return PrestigeServiceData.get_gold_multiplier(prestige_upgrade_levels, get_bonus_total("artifact_bonus_gold_mult"))

func get_essence_multiplier() -> float:
	return 1.0 + get_bonus_total("artifact_bonus_essence_mult")

func get_echo_multiplier() -> float:
	return 1.0 + get_bonus_total("artifact_bonus_echo_mult")

func get_boss_damage_multiplier() -> float:
	return 1.0 + get_bonus_total("artifact_bonus_boss_damage_mult")

func get_boss_incoming_damage_multiplier() -> float:
	return maxf(0.0, 1.0 - get_bonus_total("artifact_bonus_boss_damage_reduction"))

func get_milestone_challenge_time_limit() -> float:
	return 30.0 + get_bonus_total("artifact_bonus_boss_timer_sec")

func get_equipment_cost_discount() -> float:
	return PrestigeServiceData.get_equipment_cost_discount(prestige_upgrade_levels, get_bonus_total("artifact_bonus_equipment_discount"))

func dev_reset_all_progress() -> void:
	ProgressResetServiceData.reset_all_progress(self)
	_apply_upgrade_bonuses()
	_rebuild_school_state()
	_emit_full_progress_refresh()
	prestige_performed.emit()

func _reset_run_progress() -> void:
	ProgressResetServiceData.reset_run_progress(self)

func _emit_full_progress_refresh() -> void:
	GameStateLifecycleServiceData.emit_full_progress_refresh(self)

func _on_wave_changed(current_wave: int) -> void:
	WaveProgressServiceData.apply_wave_changed(self, current_wave)

func _rebuild_school_state() -> void:
	SchoolStateServiceData.rebuild_game_state_school_state(self)

func build_save_data() -> Dictionary:
	return GameStateSaveAdapterData.build_save_data(self, SAVE_VERSION)

func apply_save_data(data: Dictionary) -> void:
	GameStateLifecycleServiceData.apply_save_data(self, data, SAVE_VERSION)

func migrate_save_data(data: Dictionary) -> Dictionary:
	return GameStateSaveAdapterData.migrate_save_data(data, SAVE_VERSION)

func _apply_saved_active_ad_boosts(source: Variant, elapsed_sec: int) -> void:
	active_ad_boosts = AdBoostStateRulesData.build_saved_active_boosts(source, elapsed_sec)
	_apply_game_speed_time_scale()
