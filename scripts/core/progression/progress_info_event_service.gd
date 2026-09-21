extends RefCounted
class_name ProgressInfoEventService

static func build_wave_progress_events(
	highest_wave_reached: int,
	previous_slot_count: int,
	previous_prestige_available: bool,
	shown_info_event_keys: Array[String],
	shards_now: int
) -> Dictionary:
	var updated_keys: Array[String] = shown_info_event_keys.duplicate()
	var skill_slot_events: Array[Dictionary] = []
	var current_slot_count: int = SchoolRules.get_skill_slot_count_for_highest_wave(highest_wave_reached)
	if current_slot_count > previous_slot_count:
		for slot_count in range(previous_slot_count + 1, current_slot_count + 1):
			var event_key: String = "skill_slot_%d" % slot_count
			if _mark_event_shown(updated_keys, event_key):
				skill_slot_events.append({
					"slot_count": slot_count,
					"slot_index": slot_count - 1,
					"wave": highest_wave_reached,
				})

	var prestige_event: Dictionary = {}
	if not previous_prestige_available and highest_wave_reached >= PrestigeRules.UNLOCK_WAVE:
		if _mark_event_shown(updated_keys, "prestige_unlocked"):
			prestige_event = {
				"wave": highest_wave_reached,
				"unlock_wave": PrestigeRules.UNLOCK_WAVE,
				"shards_now": shards_now,
			}

	return {
		"shown_info_event_keys": updated_keys,
		"skill_slot_events": skill_slot_events,
		"prestige_event": prestige_event,
	}

static func _mark_event_shown(shown_info_event_keys: Array[String], event_key: String) -> bool:
	if event_key.is_empty() or shown_info_event_keys.has(event_key):
		return false
	shown_info_event_keys.append(event_key)
	return true
