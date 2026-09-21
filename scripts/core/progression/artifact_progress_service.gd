extends RefCounted
class_name ArtifactProgressService

const UPGRADE_BASE_COST: int = 35
const UPGRADE_COST_PER_LEVEL: int = 20

static func get_upgrade_cost(artifact_levels: Dictionary, artifact_id: StringName) -> int:
	var level: int = int(artifact_levels.get(artifact_id, 0))
	return UPGRADE_BASE_COST + level * UPGRADE_COST_PER_LEVEL

static func buy_upgrade(artifact_levels: Dictionary, owned_artifacts: Array[StringName], artifact_id: StringName, essence: int) -> Dictionary:
	if not owned_artifacts.has(artifact_id):
		return {"success": false, "essence": essence}
	var cost: int = get_upgrade_cost(artifact_levels, artifact_id)
	if essence < cost:
		return {"success": false, "essence": essence}
	artifact_levels[artifact_id] = int(artifact_levels.get(artifact_id, 0)) + 1
	return {
		"success": true,
		"essence": essence - cost,
	}

static func build_ui_rows(
	artifact_levels: Dictionary,
	owned_artifacts: Array[StringName],
	essence: int,
	language: StringName
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for artifact_id in ArtifactRules.ARTIFACT_POOL:
		var owned: bool = owned_artifacts.has(artifact_id)
		var cost: int = get_upgrade_cost(artifact_levels, artifact_id)
		rows.append({
			"id": artifact_id,
			"name": ArtifactRules.get_display_name(artifact_id, language),
			"owned": owned,
			"level": int(artifact_levels.get(artifact_id, 0)),
			"cost": cost,
			"affordable": owned and essence >= cost,
			"effect": ArtifactRules.get_effect_summary(artifact_id, int(artifact_levels.get(artifact_id, 0)), language),
		})
	return rows

static func grant_random_unowned(
	artifact_levels: Dictionary,
	owned_artifacts: Array[StringName],
	language: StringName
) -> Dictionary:
	var available_artifacts: Array[StringName] = ArtifactRules.get_unowned_pool(owned_artifacts)
	if available_artifacts.is_empty():
		return {}
	var granted: StringName = available_artifacts[randi_range(0, available_artifacts.size() - 1)]
	owned_artifacts.append(granted)
	artifact_levels[granted] = maxi(1, int(artifact_levels.get(granted, 0)))
	return {
		"artifact_id": granted,
		"artifact_name": ArtifactRules.get_display_name(granted, language),
		"artifact_level": int(artifact_levels.get(granted, 0)),
		"was_new": true,
		"effect": ArtifactRules.get_effect_summary(granted, int(artifact_levels.get(granted, 0)), language),
	}

static func build_bonus_totals(artifact_levels: Dictionary, owned_artifacts: Array[StringName]) -> Dictionary:
	var totals: Dictionary = {}
	for artifact_id in owned_artifacts:
		var level: int = int(artifact_levels.get(artifact_id, 0))
		if level <= 0:
			continue
		var effect: Dictionary = ArtifactRules.get_effect(artifact_id)
		if effect.is_empty():
			continue
		var stat: String = String(effect.get("stat", ""))
		if stat.is_empty():
			continue
		totals[stat] = float(totals.get(stat, 0.0)) + ArtifactRules.get_effect_value(artifact_id, level)
	return totals
