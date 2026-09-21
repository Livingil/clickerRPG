extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

func _ready() -> void:
	SaveSystem._loading = true
	GameState.current_language = &"ru"
	GameState.active_school = SchoolRules.SCHOOL_FIRE
	GameState.school_mastery_xp[SchoolRules.SCHOOL_FIRE] = 0
	GameState.highest_wave_reached = 10
	GameState._rebuild_school_state()

	var main_scene := MAIN_SCENE.instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var hud := main_scene.get_node("HUD") as HUD
	GameState.add_active_school_mastery_xp(20)
	await get_tree().process_frame

	if hud.school_level_popup == null or not hud.school_level_popup.visible:
		push_error("School level smoke failed: popup was not shown.")
		get_tree().quit(1)
		return
	if not hud.school_level_body_label.text.contains("Ember Mark"):
		push_error("School level smoke failed: unlocked skill was not listed.")
		get_tree().quit(1)
		return

	print("school_level_popup_smoke ok text=%s" % hud.school_level_body_label.text.replace("\n", " | "))
	get_tree().quit()
