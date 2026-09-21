extends Node

const SMOKE_SAVE_PATH: String = "user://save_smoke.json"

func _ready() -> void:
	SaveSystem.save_game(SMOKE_SAVE_PATH)
	if not FileAccess.file_exists(SMOKE_SAVE_PATH):
		push_error("Save smoke did not create a save file.")
		get_tree().quit(1)
		return

	var file := FileAccess.open(SMOKE_SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Save smoke could not read the save file.")
		get_tree().quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is not Dictionary:
		push_error("Save smoke produced invalid JSON.")
		get_tree().quit(1)
		return

	var data := parsed as Dictionary
	var version := int(data.get("version", 0))
	var has_core_keys := data.has("gold") and data.has("active_school") and data.has("equipment_levels")
	_remove_smoke_file()
	if version != GameState.SAVE_VERSION or not has_core_keys:
		push_error("Save smoke produced incomplete save data.")
		get_tree().quit(1)
		return

	print("save_smoke version=%d keys=%d" % [version, data.size()])
	get_tree().quit()

func _remove_smoke_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(SMOKE_SAVE_PATH)
	if FileAccess.file_exists(SMOKE_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
