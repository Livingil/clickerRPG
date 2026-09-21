extends Node

const ENEMY_SCENE := preload("res://scenes/enemies/enemy_base.tscn")
const SMOKE_SAVE_PATH: String = "user://school_xp_sources_smoke.json"

func _ready() -> void:
	SaveSystem._loading = true
	GameState.dev_reset_all_progress()
	GameState.active_school = SchoolRules.SCHOOL_FIRE

	GameState.add_active_school_mastery_xp(1)
	if GameState.get_school_mastery_xp(SchoolRules.SCHOOL_FIRE) != 1:
		push_error("School XP sources smoke failed: active school XP did not grow from base attack source.")
		get_tree().quit(1)
		return

	GameState.add_school_mastery_xp(SchoolRules.SCHOOL_WATER, 2)
	if GameState.get_school_mastery_xp(SchoolRules.SCHOOL_WATER) != 2:
		push_error("School XP sources smoke failed: explicit skill school XP did not grow.")
		get_tree().quit(1)
		return
	if GameState.get_school_mastery_xp(SchoolRules.SCHOOL_EARTH) != 0:
		push_error("School XP sources smoke failed: unrelated school changed.")
		get_tree().quit(1)
		return

	var xp_before_kill := GameState.get_school_mastery_xp(SchoolRules.SCHOOL_FIRE)
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	add_child(enemy)
	await get_tree().process_frame
	enemy.die()
	await get_tree().process_frame
	if GameState.get_school_mastery_xp(SchoolRules.SCHOOL_FIRE) != xp_before_kill:
		push_error("School XP sources smoke failed: enemy death granted school XP.")
		get_tree().quit(1)
		return

	var data := GameState.build_save_data()
	data["last_save_unix"] = Time.get_unix_time_from_system() - 3600
	data["highest_wave_reached"] = 10
	var file := FileAccess.open(SMOKE_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("School XP sources smoke failed: could not create save file.")
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(data))
	file.close()

	var fire_before_offline := GameState.get_school_mastery_xp(SchoolRules.SCHOOL_FIRE)
	SaveSystem.load_game(SMOKE_SAVE_PATH)
	var report := GameState.get_pending_offline_reward_report()
	_remove_smoke_file()
	if report.has("mastery_xp"):
		push_error("School XP sources smoke failed: offline report still contains school XP.")
		get_tree().quit(1)
		return
	if GameState.get_school_mastery_xp(SchoolRules.SCHOOL_FIRE) != fire_before_offline:
		push_error("School XP sources smoke failed: offline reward changed school XP.")
		get_tree().quit(1)
		return

	print("school_xp_sources_smoke ok fire=%d water=%d offline_keys=%d" % [
		GameState.get_school_mastery_xp(SchoolRules.SCHOOL_FIRE),
		GameState.get_school_mastery_xp(SchoolRules.SCHOOL_WATER),
		report.size(),
	])
	get_tree().quit()

func _remove_smoke_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(SMOKE_SAVE_PATH)
	if FileAccess.file_exists(SMOKE_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
