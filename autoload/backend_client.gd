extends Node

signal login_completed(success: bool)
signal remote_save_loaded(save_data: Dictionary)
signal server_save_received(save_data: Dictionary)
signal sync_completed(success: bool)
signal run_rewards_rejected(gold: int, essence: int, echo: int)
signal run_rewards_flushed
signal school_xp_rejected(school_id: StringName, amount: int)

const BASE_URL: String = "http://127.0.0.1:3000"
const DEVICE_ID_PATH: String = "user://backend_device_id.txt"
const REQUEST_TIMEOUT_SEC: float = 4.0
const REWARD_SYNC_INTERVAL_SEC: float = 1.0
const SCHOOL_XP_SYNC_INTERVAL_SEC: float = 2.0

var enabled: bool = true
var production_mode: bool = false
var allow_offline_progress_fallback: bool = false
var use_remote_combat_resolver: bool = false
var player_id: String = ""
var session_token: String = ""
var server_revision: int = 0
var device_id: String = ""
var logged_in: bool = false
var login_in_progress: bool = false
var server_save_loaded: bool = false
var sync_in_progress: bool = false
var pending_save_data: Dictionary = {}
var reward_sync_in_progress: bool = false
var reward_sync_time_left: float = REWARD_SYNC_INTERVAL_SEC
var pending_enemy_kills: Array[Dictionary] = []
var school_xp_sync_in_progress: bool = false
var school_xp_sync_time_left: float = SCHOOL_XP_SYNC_INTERVAL_SEC
var pending_school_xp: Dictionary = {}

func _ready() -> void:
	production_mode = not OS.is_debug_build()
	allow_offline_progress_fallback = OS.is_debug_build() and OS.get_environment("CLICKERRPG_ALLOW_OFFLINE_PROGRESS") == "1"
	use_remote_combat_resolver = OS.is_debug_build() and OS.get_environment("CLICKERRPG_USE_REMOTE_COMBAT") == "1"
	device_id = _load_or_create_device_id()
	set_process(true)

func _process(delta: float) -> void:
	if _has_pending_run_rewards():
		reward_sync_time_left = maxf(0.0, reward_sync_time_left - delta)
		if reward_sync_time_left <= 0.0:
			flush_run_rewards()
	if not pending_school_xp.is_empty():
		school_xp_sync_time_left = maxf(0.0, school_xp_sync_time_left - delta)
		if school_xp_sync_time_left <= 0.0:
			flush_school_xp()

func start() -> void:
	if not enabled or logged_in or login_in_progress:
		return
	_login()

func push_save_data(save_data: Dictionary) -> void:
	if not enabled:
		return
	if logged_in and server_save_loaded:
		return
	pending_save_data = save_data.duplicate(true)
	if not logged_in:
		start()
		return
	if sync_in_progress:
		return
	_push_pending_save_data()

func request_command(command_name: String, payload: Dictionary = {}, include_save_data: bool = true) -> Dictionary:
	if not enabled:
		return {"success": false, "offline": true}
	if not logged_in:
		start()
		if login_in_progress:
			await login_completed
	if not logged_in:
		return {"success": false, "offline": true}
	var body: Dictionary = {
		"command": command_name,
		"payload": payload,
		"includeSaveData": include_save_data,
	}
	if server_revision > 0:
		body["expectedServerRevision"] = server_revision
	var response: Dictionary = await _request_json("POST", "/api/godot/command", body)
	if not bool(response.get("ok", false)):
		return {"success": false, "offline": true}
	var data: Dictionary = response.get("data", {})
	server_revision = maxi(server_revision, int(data.get("serverRevision", server_revision)))
	var save_data: Variant = data.get("saveData", null)
	if save_data is Dictionary and not (save_data as Dictionary).is_empty():
		server_revision = maxi(server_revision, int((save_data as Dictionary).get("server_revision", server_revision)))
		server_save_received.emit((save_data as Dictionary).duplicate(true))
	return data

func queue_enemy_reward(enemy_instance_id: String, reward_gold: int, reward_essence: int, echo_gain: int) -> bool:
	if not enabled or not logged_in or enemy_instance_id.is_empty():
		return false
	pending_enemy_kills.append({
		"enemyInstanceId": enemy_instance_id,
		"rewardGold": maxi(0, reward_gold),
		"rewardEssence": maxi(0, reward_essence),
		"echoGain": maxi(0, echo_gain),
	})
	return true

func flush_run_rewards() -> void:
	if reward_sync_in_progress:
		await run_rewards_flushed
		if _has_pending_run_rewards():
			await flush_run_rewards()
		return
	if not _has_pending_run_rewards():
		return
	reward_sync_in_progress = true
	var batch: Array[Dictionary] = pending_enemy_kills.duplicate(true)
	pending_enemy_kills.clear()
	reward_sync_time_left = REWARD_SYNC_INTERVAL_SEC
	var enemy_ids: Array[String] = []
	for entry in batch:
		var enemy_id: String = String(entry.get("enemyInstanceId", ""))
		if not enemy_id.is_empty():
			enemy_ids.append(enemy_id)
	var result: Dictionary = await request_command("run.enemyKilledBatch", {"enemyInstanceIds": enemy_ids}, false)
	var stopped_for_offline: bool = bool(result.get("offline", false))
	if stopped_for_offline:
		pending_enemy_kills.append_array(batch)
	reward_sync_in_progress = false
	run_rewards_flushed.emit()
	if _has_pending_run_rewards() and not stopped_for_offline:
		await flush_run_rewards()

func queue_school_xp(school_id: StringName, amount: int) -> bool:
	if not enabled or not logged_in or amount <= 0:
		return false
	var school_key: String = String(school_id)
	var event_type: String = _school_xp_event_type_for_amount(amount)
	var key: String = "%s:%s" % [school_key, event_type]
	var entry: Dictionary = pending_school_xp.get(key, {
		"schoolId": school_key,
		"eventType": event_type,
		"count": 0,
	})
	entry["count"] = int(entry.get("count", 0)) + 1
	pending_school_xp[key] = entry
	return true

func flush_school_xp() -> void:
	if school_xp_sync_in_progress or pending_school_xp.is_empty():
		return
	school_xp_sync_in_progress = true
	var batch: Dictionary = pending_school_xp.duplicate(true)
	pending_school_xp.clear()
	school_xp_sync_time_left = SCHOOL_XP_SYNC_INTERVAL_SEC
	var events: Array[Dictionary] = []
	for event_key in batch.keys():
		var event: Dictionary = batch[event_key] as Dictionary
		event["eventId"] = "%s-%s-%d" % [device_id, String(event_key), Time.get_ticks_msec()]
		events.append(event)
	var result: Dictionary = await request_command("school.addXpEvents", {"events": events}, false)
	if bool(result.get("offline", false)):
		for event_key in batch.keys():
			var key: String = String(event_key)
			var old_entry: Dictionary = batch[event_key] as Dictionary
			var current: Dictionary = pending_school_xp.get(key, old_entry.duplicate(true))
			current["count"] = int(current.get("count", 0)) + int(old_entry.get("count", 0))
			pending_school_xp[key] = current
	school_xp_sync_in_progress = false
	if not pending_school_xp.is_empty():
		school_xp_sync_time_left = SCHOOL_XP_SYNC_INTERVAL_SEC

func _login() -> void:
	login_in_progress = true
	var body: Dictionary = {"deviceId": device_id, "name": OS.get_environment("USERNAME")}
	var response: Dictionary = await _request_json("POST", "/api/auth/dev-login", body)
	var success: bool = bool(response.get("ok", false))
	if success:
		var data: Dictionary = response.get("data", {})
		player_id = String(data.get("playerId", ""))
		session_token = String(data.get("sessionToken", ""))
		server_revision = int(data.get("serverRevision", server_revision))
		logged_in = not player_id.is_empty() and not session_token.is_empty()
		var save_data: Variant = data.get("saveData", null)
		if save_data is Dictionary and not (save_data as Dictionary).is_empty():
			server_revision = maxi(server_revision, int((save_data as Dictionary).get("server_revision", server_revision)))
			server_save_loaded = true
			pending_save_data.clear()
			remote_save_loaded.emit((save_data as Dictionary).duplicate(true))
	login_in_progress = false
	login_completed.emit(logged_in)
	if logged_in and not server_save_loaded and not pending_save_data.is_empty():
		_push_pending_save_data()

func _push_pending_save_data() -> void:
	if pending_save_data.is_empty() or player_id.is_empty():
		return
	sync_in_progress = true
	var save_data: Dictionary = pending_save_data.duplicate(true)
	pending_save_data.clear()
	var response: Dictionary = await _request_json("PUT", "/api/player/save-data", {"saveData": save_data})
	sync_in_progress = false
	var success: bool = bool(response.get("ok", false))
	if success:
		server_save_loaded = true
	sync_completed.emit(success)
	if not pending_save_data.is_empty():
		_push_pending_save_data()

func _has_pending_run_rewards() -> bool:
	return not pending_enemy_kills.is_empty()

func should_apply_local_progress_fallback() -> bool:
	return not enabled or allow_offline_progress_fallback

func should_use_remote_combat_resolver() -> bool:
	return enabled and logged_in and use_remote_combat_resolver

func _school_xp_event_type_for_amount(amount: int) -> String:
	if amount >= 5:
		return "skill_major"
	if amount >= 2:
		return "skill_minor"
	return "hit"

func _request_json(method: String, path: String, body: Dictionary = {}) -> Dictionary:
	var request: HTTPRequest = HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SEC
	add_child(request)
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
	if not session_token.is_empty():
		headers.append("Authorization: Bearer %s" % session_token)
	var payload: String = JSON.stringify(body) if not body.is_empty() else ""
	var http_method: HTTPClient.Method = HTTPClient.METHOD_GET
	match method:
		"POST":
			http_method = HTTPClient.METHOD_POST
		"PUT":
			http_method = HTTPClient.METHOD_PUT
	var error: Error = request.request(BASE_URL + path, headers, http_method, payload)
	if error != OK:
		request.queue_free()
		return {"ok": false, "error": error}
	var result: Array = await request.request_completed
	request.queue_free()
	var code: int = int(result[1])
	var raw: PackedByteArray = result[3]
	var parsed: Variant = JSON.parse_string(raw.get_string_from_utf8())
	if code < 200 or code >= 300 or parsed is not Dictionary:
		return {"ok": false, "status": code}
	return {"ok": true, "status": code, "data": parsed as Dictionary}

func _load_or_create_device_id() -> String:
	if FileAccess.file_exists(DEVICE_ID_PATH):
		var file: FileAccess = FileAccess.open(DEVICE_ID_PATH, FileAccess.READ)
		if file != null:
			var existing: String = file.get_as_text().strip_edges()
			file.close()
			if not existing.is_empty():
				return existing
	var created: String = "%s-%d" % [OS.get_unique_id(), Time.get_unix_time_from_system()]
	var file: FileAccess = FileAccess.open(DEVICE_ID_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(created)
		file.close()
	return created
