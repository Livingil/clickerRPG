extends Node

const SAVE_PATH: String = "user://save_game.json"
const AUTOSAVE_DELAY_SEC: float = 1.0

var _save_timer: Timer
var _loading: bool = false

func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = AUTOSAVE_DELAY_SEC
	_save_timer.timeout.connect(save_game)
	add_child(_save_timer)

	load_game()
	_connect_backend_client()
	BackendClient.start()
	_connect_game_state_signals()

func save_game(save_path: String = SAVE_PATH) -> void:
	if _loading:
		return
	var save_abs: String = ProjectSettings.globalize_path(save_path)
	var temp_abs: String = "%s.tmp" % save_abs
	var save_dir: String = save_abs.get_base_dir()
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(save_dir)
	if dir_error != OK:
		push_warning("SaveSystem: failed to prepare save directory: %s" % save_dir)
		return

	var file: FileAccess = FileAccess.open(temp_abs, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: failed to open temp save file for writing: %s" % temp_abs)
		_write_save_direct(save_abs)
		return
	var save_data: Dictionary = GameState.build_save_data()
	if BackendClient.server_save_loaded:
		save_data["server_authoritative"] = true
	var json: String = JSON.stringify(save_data)
	file.store_string(json)
	file.flush()
	file.close()
	if FileAccess.file_exists(save_abs):
		var remove_error: Error = DirAccess.remove_absolute(save_abs)
		if remove_error != OK:
			push_warning("SaveSystem: failed to replace old save file: %s" % save_abs)
			_write_save_direct(save_abs)
			return
	var rename_error: Error = DirAccess.rename_absolute(temp_abs, save_abs)
	if rename_error != OK:
		push_warning("SaveSystem: failed to promote temp save file: %s" % temp_abs)
		_write_save_direct(save_abs)
	BackendClient.push_save_data(GameState.build_save_data())

func load_game(save_path: String = SAVE_PATH) -> void:
	var save_abs: String = ProjectSettings.globalize_path(save_path)
	if not FileAccess.file_exists(save_abs):
		return
	var file: FileAccess = FileAccess.open(save_abs, FileAccess.READ)
	if file == null:
		push_warning("SaveSystem: failed to open save file for reading: %s" % save_abs)
		return
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is not Dictionary:
		push_warning("SaveSystem: save file is not valid JSON data: %s" % save_abs)
		return
	_loading = true
	GameState.apply_save_data(parsed as Dictionary)
	_loading = false
	save_game(save_path)

func request_save() -> void:
	if _loading or _save_timer == null:
		return
	_save_timer.start()

func _write_save_direct(save_abs: String) -> void:
	var file: FileAccess = FileAccess.open(save_abs, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: failed to write save file directly: %s" % save_abs)
		return
	var save_data: Dictionary = GameState.build_save_data()
	if BackendClient.server_save_loaded:
		save_data["server_authoritative"] = true
	file.store_string(JSON.stringify(save_data))
	file.flush()
	file.close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		save_game()

func _connect_game_state_signals() -> void:
	GameState.resources_changed.connect(_on_game_state_changed)
	GameState.echo_changed.connect(_on_game_state_changed)
	GameState.hero_stats_changed.connect(_on_game_state_changed)
	GameState.upgrades_changed.connect(_on_game_state_changed)
	GameState.school_state_changed.connect(_on_game_state_changed)
	GameState.school_mastery_changed.connect(_on_game_state_changed)
	GameState.prestige_performed.connect(_on_game_state_changed)
	GameState.ad_boosts_changed.connect(_on_game_state_changed)
	GameState.combat_text_settings_changed.connect(_on_game_state_changed)
	GameState.language_changed.connect(_on_game_state_changed)

func _connect_backend_client() -> void:
	BackendClient.remote_save_loaded.connect(_on_remote_save_loaded)
	BackendClient.server_save_received.connect(_on_server_save_received)
	BackendClient.run_rewards_rejected.connect(_on_run_rewards_rejected)
	BackendClient.school_xp_rejected.connect(_on_school_xp_rejected)

func _on_remote_save_loaded(save_data: Dictionary) -> void:
	_apply_backend_save_data(save_data)
	_write_raw_save_direct(ProjectSettings.globalize_path(SAVE_PATH), save_data)

func _on_server_save_received(save_data: Dictionary) -> void:
	_apply_backend_save_data(save_data)
	_write_raw_save_direct(ProjectSettings.globalize_path(SAVE_PATH), save_data)

func _apply_backend_save_data(save_data: Dictionary) -> void:
	var previous_school_xp: Dictionary = GameState.school_mastery_xp.duplicate(true)
	_loading = true
	GameState.apply_save_data(save_data)
	_loading = false
	_emit_backend_school_level_reports(previous_school_xp)

func _on_run_rewards_rejected(gold: int, essence: int, echo: int) -> void:
	GameState.add_gold(gold)
	GameState.add_essence(essence)
	GameState.add_echo(echo)

func _on_school_xp_rejected(school_id: StringName, amount: int) -> void:
	SchoolStateService.add_mastery_xp_to_game_state(GameState, school_id, amount)

func _write_raw_save_direct(save_abs: String, save_data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(save_abs, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: failed to write backend save file directly: %s" % save_abs)
		return
	file.store_string(JSON.stringify(save_data))
	file.flush()
	file.close()

func _emit_backend_school_level_reports(previous_school_xp: Dictionary) -> void:
	for school_id in SchoolRules.SCHOOL_ORDER:
		var old_core_level: int = SchoolProgressRules.get_school_core_mastery_level(school_id, previous_school_xp)
		var old_total_level: int = SchoolProgressRules.get_school_mastery_level(school_id, previous_school_xp)
		var new_core_level: int = GameState.get_school_core_mastery_level(school_id)
		var new_total_level: int = GameState.get_school_mastery_level(school_id)
		if new_total_level <= old_total_level:
			continue
		var report: Dictionary = SchoolProgressRules.build_level_report(
			school_id,
			old_core_level,
			new_core_level,
			old_total_level,
			new_total_level,
			GameState.current_language
		)
		if not report.is_empty():
			GameState.school_mastery_level_reached.emit(report)

func _on_game_state_changed(_arg0: Variant = null, _arg1: Variant = null) -> void:
	request_save()
