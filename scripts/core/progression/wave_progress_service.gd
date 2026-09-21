extends RefCounted
class_name WaveProgressService

const ProgressInfoEventServiceData = preload("res://scripts/core/progression/progress_info_event_service.gd")
const PrestigeRulesData = preload("res://scripts/core/progression/prestige_rules.gd")

static func apply_wave_changed(game_state: Object, current_wave: int) -> void:
	game_state.current_run_wave = maxi(1, current_wave)
	if current_wave <= game_state.highest_wave_reached:
		return

	var previous_highest: int = game_state.highest_wave_reached
	var previous_slot_count: int = SchoolRules.get_skill_slot_count_for_highest_wave(previous_highest)
	var previous_prestige_available: bool = previous_highest >= PrestigeRulesData.UNLOCK_WAVE
	game_state.highest_wave_reached = current_wave
	game_state._rebuild_school_state()
	_emit_wave_progress_info_events(game_state, previous_slot_count, previous_prestige_available)

static func _emit_wave_progress_info_events(
	game_state: Object,
	previous_slot_count: int,
	previous_prestige_available: bool
) -> void:
	var result: Dictionary = ProgressInfoEventServiceData.build_wave_progress_events(
		game_state.highest_wave_reached,
		previous_slot_count,
		previous_prestige_available,
		game_state.shown_info_event_keys,
		game_state.get_prestige_shards_for_current_run()
	)
	game_state.shown_info_event_keys = result.get("shown_info_event_keys", game_state.shown_info_event_keys)
	for event in result.get("skill_slot_events", []):
		game_state.skill_slot_unlocked.emit(event)
	var prestige_event: Dictionary = result.get("prestige_event", {})
	if not prestige_event.is_empty():
		game_state.prestige_unlocked.emit(prestige_event)
