extends Node

func _ready() -> void:
	SaveSystem._loading = true
	GameState.dev_reset_all_progress()
	GameState.active_school = SchoolRules.SCHOOL_AIR
	GameState.school_mastery_xp[SchoolRules.SCHOOL_AIR] = 7000
	var main_scene := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var controller := main_scene.get_node("AbilityController") as AbilityController
	var names := controller.get_active_ability_names()
	if not names.has("Razor Gust") or not names.has("Cyclone Arc") or not names.has("Sky Flurry"):
		push_error("Air smoke failed: air abilities were not active. %s" % names)
		get_tree().quit(1)
		return

	var enemy := preload("res://scenes/enemies/enemy_base.tscn").instantiate() as Enemy
	enemy.global_position = GameConstants.ARENA_CENTER + Vector2(80.0, 0.0)
	main_scene.add_child(enemy)
	await get_tree().process_frame

	var base_accuracy := enemy.get_effective_accuracy()
	for _i in range(3):
		enemy.receive_school_hit(1.0, SchoolRules.SCHOOL_AIR, 999.0)
	var reduced_accuracy := enemy.get_effective_accuracy()
	if reduced_accuracy >= base_accuracy:
		push_error("Air smoke failed: air stacks did not reduce enemy accuracy.")
		get_tree().quit(1)
		return
	if not enemy.vulnerability_label.text.contains("A3"):
		push_error("Air smoke failed: air stack label was not visible.")
		get_tree().quit(1)
		return

	var before_knockback := enemy.global_position
	enemy.apply_knockback_from(GameConstants.ARENA_CENTER, 82.0)
	if enemy.global_position.distance_to(GameConstants.ARENA_CENTER) <= before_knockback.distance_to(GameConstants.ARENA_CENTER):
		push_error("Air smoke failed: knockback did not move enemy away.")
		get_tree().quit(1)
		return

	var before_pull := enemy.global_position
	enemy.apply_pull_towards(GameConstants.ARENA_CENTER, 58.0)
	if enemy.global_position.distance_to(GameConstants.ARENA_CENTER) >= before_pull.distance_to(GameConstants.ARENA_CENTER):
		push_error("Air smoke failed: pull did not move enemy inward.")
		get_tree().quit(1)
		return

	print("air_school_smoke ok abilities=%s label=%s acc=%.1f->%.1f" % [
		names,
		enemy.vulnerability_label.text,
		base_accuracy,
		reduced_accuracy,
	])
	get_tree().quit()
