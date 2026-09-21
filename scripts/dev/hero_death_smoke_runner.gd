extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

func _ready() -> void:
	SaveSystem._loading = true
	var main_scene := MAIN_SCENE.instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var deaths_before := GameState.total_deaths
	var gameplay_root := main_scene.get_node("GameplayRoot")
	var hero := gameplay_root.get_node("Hero") as Hero
	hero.hp = 1.0
	hero.take_damage(999999.0)
	await get_tree().process_frame
	await get_tree().process_frame

	if GameState.total_deaths <= deaths_before:
		push_error("Hero death smoke failed: death was not registered.")
		get_tree().quit(1)
		return
	if hero.hp <= 0.0:
		push_error("Hero death smoke failed: hero was not reset after death.")
		get_tree().quit(1)
		return

	print("hero_death_smoke ok deaths=%d hp=%.1f" % [GameState.total_deaths, hero.hp])
	get_tree().quit()
