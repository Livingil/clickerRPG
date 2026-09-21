extends RefCounted
class_name EquipmentProgressService

static func is_unlocked(equipment_unlocked: Dictionary, equipment_id: StringName) -> bool:
	if not EquipmentRules.has_equipment(equipment_id):
		return false
	return bool(equipment_unlocked.get(equipment_id, equipment_id == &"weapon"))

static func can_unlock(equipment_unlocked: Dictionary, equipment_id: StringName, gold: int) -> bool:
	if is_unlocked(equipment_unlocked, equipment_id):
		return false
	var unlock_cost: int = EquipmentRules.get_unlock_cost(equipment_id)
	return unlock_cost > 0 and gold >= unlock_cost

static func unlock(
	equipment_levels: Dictionary,
	equipment_unlocked: Dictionary,
	equipment_id: StringName,
	gold: int
) -> Dictionary:
	if is_unlocked(equipment_unlocked, equipment_id):
		return {"success": false, "gold": gold, "previous_level": 0, "new_level": 0}
	var unlock_cost: int = EquipmentRules.get_unlock_cost(equipment_id)
	if unlock_cost <= 0 or gold < unlock_cost:
		return {"success": false, "gold": gold, "previous_level": 0, "new_level": 0}

	var previous_level: int = int(equipment_levels.get(equipment_id, 0))
	equipment_unlocked[equipment_id] = true
	if previous_level <= 0:
		equipment_levels[equipment_id] = 1
	return {
		"success": true,
		"gold": gold - unlock_cost,
		"previous_level": previous_level,
		"new_level": int(equipment_levels.get(equipment_id, previous_level)),
	}

static func get_upgrade_cost(equipment_levels: Dictionary, equipment_id: StringName, discount: float) -> int:
	var level: int = int(equipment_levels.get(equipment_id, 0))
	return EquipmentRules.get_upgrade_cost(equipment_id, level, discount)

static func buy_upgrade(
	equipment_levels: Dictionary,
	equipment_unlocked: Dictionary,
	equipment_id: StringName,
	gold: int,
	discount: float
) -> Dictionary:
	if not EquipmentRules.has_equipment(equipment_id):
		return {"success": false, "gold": gold, "previous_level": 0, "new_level": 0}
	if not is_unlocked(equipment_unlocked, equipment_id):
		return {"success": false, "gold": gold, "previous_level": 0, "new_level": 0}

	var previous_level: int = int(equipment_levels.get(equipment_id, 0))
	var cost: int = get_upgrade_cost(equipment_levels, equipment_id, discount)
	if gold < cost:
		return {"success": false, "gold": gold, "previous_level": previous_level, "new_level": previous_level}

	equipment_levels[equipment_id] = previous_level + 1
	return {
		"success": true,
		"gold": gold - cost,
		"previous_level": previous_level,
		"new_level": previous_level + 1,
	}
