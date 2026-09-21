extends Node

const SMOKE_SAVE_PATH: String = "user://offline_reward_smoke.json"

func _ready() -> void:
	var now_unix := Time.get_unix_time_from_system()
	var data := GameState.build_save_data()
	data["last_save_unix"] = now_unix - 3600
	data["highest_wave_reached"] = 10
	data["gold"] = 0
	data["essence"] = 0
	data["echo_collected"] = 0
	data["school_mastery_xp"] = {}

	var file := FileAccess.open(SMOKE_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Offline reward smoke could not create save file.")
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(data))
	file.close()

	SaveSystem.load_game(SMOKE_SAVE_PATH)
	var report := GameState.get_pending_offline_reward_report()
	_remove_smoke_file()
	if report.is_empty():
		push_error("Offline reward smoke did not produce a reward report.")
		get_tree().quit(1)
		return
	if GameState.gold <= 0 or GameState.essence <= 0 or GameState.echo_collected <= 0:
		push_error("Offline reward smoke did not grant expected resources.")
		get_tree().quit(1)
		return

	print("offline_reward_smoke wave=%d elapsed=%d gold=%d essence=%d echo=%d" % [
		int(report.get("wave", 0)),
		int(report.get("capped_sec", 0)),
		int(report.get("gold", 0)),
		int(report.get("essence", 0)),
		int(report.get("echo", 0)),
	])
	get_tree().quit()

func _remove_smoke_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(SMOKE_SAVE_PATH)
	if FileAccess.file_exists(SMOKE_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
