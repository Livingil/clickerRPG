extends RefCounted
class_name GameStateLifecycleService

const ArtifactRulesData = preload("res://scripts/core/progression/artifact_rules.gd")
const EquipmentRulesData = preload("res://scripts/core/progression/equipment_rules.gd")
const PrestigeRulesData = preload("res://scripts/core/progression/prestige_rules.gd")
const GameStateSaveAdapterData = preload("res://scripts/core/progression/game_state_save_adapter.gd")

static func initialize_defaults(game_state: Object) -> void:
	for school_id: StringName in SchoolRules.SCHOOL_ORDER:
		game_state.school_mastery_xp[school_id] = 0
	for equipment_id in EquipmentRulesData.ORDER:
		game_state.equipment_levels[equipment_id] = 0
		game_state.equipment_unlocked[equipment_id] = equipment_id == &"weapon"
	for artifact_id in ArtifactRulesData.ARTIFACT_POOL:
		game_state.artifact_levels[artifact_id] = 0
	for skill_id_variant in SchoolRules.SKILL_DEFINITIONS.keys():
		var skill_id: StringName = skill_id_variant as StringName
		game_state.skill_upgrade_levels[skill_id] = {"dmg": 0, "cd": 0, "proc": 0}
	for school_id: StringName in SchoolRules.SCHOOL_ORDER:
		game_state.weapon_school_upgrade_levels[school_id] = 0
	for prestige_upgrade_id in PrestigeRulesData.UPGRADE_ORDER:
		game_state.prestige_upgrade_levels[prestige_upgrade_id] = 0

static func apply_save_data(game_state: Object, data: Dictionary, save_version: int) -> void:
	if data.is_empty():
		return
	GameStateSaveAdapterData.apply_save_data(game_state, data, save_version)
	emit_full_loaded_state(game_state)

static func emit_full_loaded_state(game_state: Object) -> void:
	game_state.resources_changed.emit(game_state.gold, game_state.essence)
	game_state.echo_changed.emit(game_state.echo_collected, game_state.echo_power)
	game_state.hero_stats_changed.emit()
	game_state.upgrades_changed.emit()
	game_state.school_mastery_changed.emit()
	game_state.combat_text_settings_changed.emit()
	game_state.language_changed.emit()
	game_state.ad_boost_offer_changed.emit(game_state.get_current_ad_boost_offer())
	game_state.ad_boosts_changed.emit()
	if not game_state.pending_offline_reward_report.is_empty():
		game_state.offline_rewards_granted.emit(game_state.get_pending_offline_reward_report())

static func emit_full_progress_refresh(game_state: Object) -> void:
	game_state.resources_changed.emit(game_state.gold, game_state.essence)
	game_state.echo_changed.emit(game_state.echo_collected, game_state.echo_power)
	game_state.hero_stats_changed.emit()
	game_state.upgrades_changed.emit()
	game_state.school_state_changed.emit()
	game_state.school_mastery_changed.emit()
	game_state.ad_boost_offer_changed.emit({})
	game_state.ad_boosts_changed.emit()
