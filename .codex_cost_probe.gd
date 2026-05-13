extends SceneTree
func _init():
	for id in GameState.get_equipment_ids():
		var unlocked := GameState.is_equipment_unlocked(id)
		print(str(id), ' unlocked=', unlocked, ' unlock_cost=', GameState.get_equipment_unlock_cost(id), ' upgrade_cost=', GameState.get_equipment_upgrade_cost(id))
	quit()
