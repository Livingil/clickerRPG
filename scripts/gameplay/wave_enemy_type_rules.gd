extends RefCounted
class_name WaveEnemyTypeRules

static func roll_mono_normal_enemy_type(wave: int) -> StringName:
	var available_types: Array[StringName] = get_available_normal_enemy_types(wave)
	if available_types.size() < 2:
		return &""
	if randf() >= GameConstants.ENEMY_MONO_WAVE_CHANCE:
		return &""
	return available_types[randi_range(0, available_types.size() - 1)] as StringName

static func roll_normal_enemy_type(wave: int, mono_normal_enemy_type: StringName) -> StringName:
	if mono_normal_enemy_type != &"":
		return mono_normal_enemy_type
	var weighted_types: Array[Dictionary] = get_weighted_normal_enemy_types(wave)
	if weighted_types.is_empty():
		return GameConstants.ENEMY_TYPE_BASIC
	var total_weight: int = 0
	for entry in weighted_types:
		total_weight += int(entry.get("weight", 0))
	if total_weight <= 0:
		return GameConstants.ENEMY_TYPE_BASIC
	var roll: int = randi_range(1, total_weight)
	var cursor: int = 0
	for entry in weighted_types:
		cursor += int(entry.get("weight", 0))
		if roll <= cursor:
			return entry.get("type", GameConstants.ENEMY_TYPE_BASIC) as StringName
	return GameConstants.ENEMY_TYPE_BASIC

static func get_available_normal_enemy_types(wave: int) -> Array[StringName]:
	var types: Array[StringName] = [GameConstants.ENEMY_TYPE_BASIC]
	if wave >= GameConstants.ENEMY_TANK_UNLOCK_WAVE:
		types.append(GameConstants.ENEMY_TYPE_TANK)
	if wave >= GameConstants.ENEMY_FAST_UNLOCK_WAVE:
		types.append(GameConstants.ENEMY_TYPE_FAST)
	if wave >= GameConstants.ENEMY_RANGED_UNLOCK_WAVE:
		types.append(GameConstants.ENEMY_TYPE_RANGED)
	return types

static func get_weighted_normal_enemy_types(wave: int) -> Array[Dictionary]:
	if wave >= GameConstants.ENEMY_RANGED_UNLOCK_WAVE:
		return [
			{"type": GameConstants.ENEMY_TYPE_BASIC, "weight": 45},
			{"type": GameConstants.ENEMY_TYPE_TANK, "weight": 25},
			{"type": GameConstants.ENEMY_TYPE_FAST, "weight": 20},
			{"type": GameConstants.ENEMY_TYPE_RANGED, "weight": 10},
		]
	if wave >= GameConstants.ENEMY_FAST_UNLOCK_WAVE:
		return [
			{"type": GameConstants.ENEMY_TYPE_BASIC, "weight": 55},
			{"type": GameConstants.ENEMY_TYPE_TANK, "weight": 25},
			{"type": GameConstants.ENEMY_TYPE_FAST, "weight": 20},
		]
	if wave >= GameConstants.ENEMY_TANK_UNLOCK_WAVE:
		return [
			{"type": GameConstants.ENEMY_TYPE_BASIC, "weight": 70},
			{"type": GameConstants.ENEMY_TYPE_TANK, "weight": 30},
		]
	return [{"type": GameConstants.ENEMY_TYPE_BASIC, "weight": 100}]
