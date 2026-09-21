extends Node

func _ready() -> void:
	SaveSystem._loading = true
	GameState.dev_reset_all_progress()
	GameState.active_school = SchoolRules.SCHOOL_LIGHTNING
	GameState.school_mastery_xp[SchoolRules.SCHOOL_LIGHTNING] = 7000
	var main_scene := preload("res://scenes/main/main.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var controller := main_scene.get_node("AbilityController") as AbilityController
	var names := controller.get_active_ability_names()
	if not names.has("Spark Jump") or not names.has("Volt Lance") or not names.has("Thunder Crown"):
		push_error("Lightning smoke failed: lightning abilities were not active. %s" % names)
		get_tree().quit(1)
		return

	var enemy := preload("res://scenes/enemies/enemy_base.tscn").instantiate() as Enemy
	enemy.global_position = GameConstants.ARENA_CENTER + Vector2(90.0, 0.0)
	main_scene.add_child(enemy)
	await get_tree().process_frame

	for _i in range(4):
		enemy.receive_school_hit(1.0, SchoolRules.SCHOOL_LIGHTNING, 999.0)
	if not enemy.vulnerability_label.text.contains("L4"):
		push_error("Lightning smoke failed: lightning stack label was not visible. label=%s" % enemy.vulnerability_label.text)
		get_tree().quit(1)
		return

	var hp_before_discharge := enemy.hp
	enemy.receive_school_hit(1.0, SchoolRules.SCHOOL_LIGHTNING, 999.0)
	var lightning_stacks := int(enemy.vulnerability_stacks.get(SchoolRules.SCHOOL_LIGHTNING, 0))
	if lightning_stacks != 0:
		push_error("Lightning smoke failed: discharge did not reset lightning stacks. stacks=%d" % lightning_stacks)
		get_tree().quit(1)
		return
	if enemy.hp >= hp_before_discharge:
		push_error("Lightning smoke failed: discharge did not add damage.")
		get_tree().quit(1)
		return

	print("lightning_school_smoke ok abilities=%s hp=%.1f->%.1f" % [
		names,
		hp_before_discharge,
		enemy.hp,
	])
	get_tree().quit()
