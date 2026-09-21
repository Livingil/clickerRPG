extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

func _ready() -> void:
	SaveSystem._loading = true
	GameState.dev_reset_all_progress()
	var main_scene := MAIN_SCENE.instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var gameplay_root := main_scene.get_node("GameplayRoot") as GameplayRoot
	var wave_controller := gameplay_root.get_node("WaveController") as WaveController
	var hero := gameplay_root.get_node("Hero") as Hero
	var prestige_panel := main_scene.get_node("HUD/Root/PrestigePopup") as PrestigePanel

	GameState.highest_wave_reached = 42
	wave_controller._start_wave(42)
	hero.hp = 1.0
	await get_tree().process_frame

	prestige_panel._on_dev_reset_pressed()
	await get_tree().process_frame
	await get_tree().process_frame

	if GameState.highest_wave_reached != 1:
		push_error("Dev restart smoke failed: GameState wave record was not reset.")
		get_tree().quit(1)
		return
	if wave_controller.current_wave != 1:
		push_error("Dev restart smoke failed: live wave controller stayed at %d." % wave_controller.current_wave)
		get_tree().quit(1)
		return
	if hero.hp <= 0.0 or not is_equal_approx(hero.hp, hero.max_hp):
		push_error("Dev restart smoke failed: hero was not restored.")
		get_tree().quit(1)
		return

	print("dev_restart_button_smoke ok wave=%d hp=%.1f" % [wave_controller.current_wave, hero.hp])
	get_tree().quit()
