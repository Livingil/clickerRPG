extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

func _ready() -> void:
	SaveSystem._loading = true
	GameState.equipment_levels[&"chest"] = 1000
	GameState.equipment_unlocked[&"chest"] = true
	GameState._rebuild_all_bonuses()

	var main_scene := MAIN_SCENE.instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var hero := main_scene.get_node("GameplayRoot/Hero") as Hero
	hero.hp = hero.max_hp * 0.5
	var hp_before := hero.hp
	await get_tree().physics_frame
	await get_tree().physics_frame

	if GameState.get_chest_hp_regen_percent_per_sec() <= 0.0:
		push_error("Chest regen smoke failed: regen percent is zero.")
		get_tree().quit(1)
		return
	if hero.hp <= hp_before:
		push_error("Chest regen smoke failed: hero HP did not regenerate.")
		get_tree().quit(1)
		return

	print("chest_regen_smoke ok regen=%.4f hp_delta=%.3f" % [
		GameState.get_chest_hp_regen_percent_per_sec(),
		hero.hp - hp_before,
	])
	get_tree().quit()
