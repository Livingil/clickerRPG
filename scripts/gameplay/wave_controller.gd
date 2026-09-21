extends Node
class_name WaveController

var current_wave: int = 1
var enemy_spawner: EnemySpawner
var normal_spawned_this_wave: int = 0
var boss_spawned_this_wave: bool = false
var wave_boss_defeated: bool = false
var milestone_spawned_this_wave: bool = false
var milestone_defeated_this_wave: bool = false
var mono_normal_enemy_type: StringName = &""
var server_normal_enemy_count: int = 0
var server_normal_enemy_configs: Array[Dictionary] = []
var server_boss_configs: Dictionary = {}
var server_wave_session_id: String = ""
var wave_complete_in_progress: bool = false
var milestone_challenge: MilestoneChallengeController = MilestoneChallengeController.new()

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if milestone_challenge.process(delta):
		_restart_current_wave_without_milestone()

func bind_spawner(spawner: EnemySpawner) -> void:
	enemy_spawner = spawner
	enemy_spawner.set_wave_controller(self)
	if not SignalBus.milestone_challenge_retry_requested.is_connected(_on_milestone_retry_requested):
		SignalBus.milestone_challenge_retry_requested.connect(_on_milestone_retry_requested)
	_start_wave(maxi(1, GameState.current_run_wave))

func advance_wave() -> void:
	if wave_complete_in_progress:
		return
	wave_complete_in_progress = true
	var completed: bool = await _complete_current_wave_on_server()
	wave_complete_in_progress = false
	if completed or BackendClient.should_apply_local_progress_fallback():
		_start_wave(current_wave + 1)

func reset_to_first_wave() -> void:
	milestone_challenge.reset_for_new_run()
	_start_wave(1)

func get_spawn_requests(active_enemy_count: int, free_slots: int) -> Array[StringName]:
	var requests: Array[StringName] = []
	if free_slots <= 0:
		return requests

	if milestone_challenge.is_farm_wave(current_wave):
		if milestone_challenge.should_spawn_farm_boss(current_wave):
			requests.append(&"wave_boss")
		if requests.size() < free_slots:
			requests.append(&"normal")
		return requests

	if normal_spawned_this_wave == 0 and not boss_spawned_this_wave:
		requests.append(&"normal")
		if free_slots > 1:
			requests.append(&"wave_boss")
		return requests

	if normal_spawned_this_wave < get_normal_enemy_count():
		requests.append(&"normal")
		return requests

	if _should_spawn_milestone_boss(active_enemy_count):
		requests.append(get_milestone_spawn_kind())

	return requests

func configure_enemy(enemy: Enemy, spawn_kind: StringName) -> void:
	var server_config: Dictionary = _get_server_enemy_config(spawn_kind)
	var configured_boss_kind: StringName = &"none"
	if server_config.is_empty():
		var normal_enemy_type: StringName = GameConstants.ENEMY_TYPE_BASIC
		if spawn_kind == &"normal":
			normal_enemy_type = WaveEnemyTypeRules.roll_normal_enemy_type(current_wave, mono_normal_enemy_type)
		configured_boss_kind = EnemyWaveScaler.configure_enemy(enemy, spawn_kind, current_wave, normal_enemy_type)
	else:
		configured_boss_kind = _apply_server_enemy_config(enemy, server_config)
	milestone_challenge.start_if_timed(current_wave, configured_boss_kind)

func register_spawn(kind: StringName) -> void:
	match kind:
		&"normal":
			normal_spawned_this_wave += 1
		&"wave_boss":
			boss_spawned_this_wave = true
			milestone_challenge.on_wave_boss_spawned(current_wave)
		&"mini_boss", &"grand_boss", &"apex_boss":
			milestone_spawned_this_wave = true

func handle_enemy_killed(enemy: Enemy, active_enemy_count: int) -> void:
	match enemy.boss_kind:
		&"wave":
			wave_boss_defeated = true
			milestone_challenge.on_wave_boss_killed(current_wave)
		&"mini", &"grand", &"apex":
			milestone_challenge.on_milestone_boss_defeated(current_wave, enemy.boss_kind)
			milestone_defeated_this_wave = true

	if milestone_defeated_this_wave:
		call_deferred("advance_wave")
		return

	if milestone_challenge.is_farm_wave(current_wave):
		return

	if _is_main_wave_cleared(active_enemy_count):
		if has_milestone_boss_for_current_wave():
			return
		call_deferred("advance_wave")

func get_normal_enemy_count() -> int:
	if server_normal_enemy_count > 0:
		return server_normal_enemy_count
	return GameConstants.normal_enemy_count_for_wave(current_wave)

func has_milestone_boss_for_current_wave() -> bool:
	return milestone_challenge.has_milestone_boss_for_wave(current_wave)

func get_milestone_spawn_kind() -> StringName:
	return milestone_challenge.get_milestone_spawn_kind(current_wave)

func _should_spawn_milestone_boss(active_enemy_count: int) -> bool:
	return has_milestone_boss_for_current_wave() \
		and _is_main_wave_cleared(active_enemy_count) \
		and not milestone_spawned_this_wave

func _restart_current_wave_without_milestone() -> void:
	if enemy_spawner != null:
		enemy_spawner.clear_active_enemies()
	_start_wave(current_wave)

func _on_milestone_retry_requested() -> void:
	if enemy_spawner == null:
		return
	var retry_kind: StringName = milestone_challenge.consume_retry_request(
		current_wave,
		_is_main_wave_cleared(enemy_spawner.active_enemies.size()) and not milestone_spawned_this_wave
	)
	if retry_kind == &"":
		return
	enemy_spawner.spawn_enemy(retry_kind)

func _is_main_wave_cleared(active_enemy_count: int) -> bool:
	return normal_spawned_this_wave >= get_normal_enemy_count() \
		and wave_boss_defeated \
		and active_enemy_count == 0

func _start_wave(wave_number: int) -> void:
	milestone_challenge.on_wave_started(wave_number)
	if BackendClient.logged_in:
		await BackendClient.flush_run_rewards()
	var wave_plan: Dictionary = await _request_wave_plan(wave_number)
	if wave_plan.is_empty() and BackendClient.enabled and not BackendClient.should_apply_local_progress_fallback():
		return
	current_wave = wave_number
	normal_spawned_this_wave = 0
	boss_spawned_this_wave = false
	wave_boss_defeated = false
	milestone_spawned_this_wave = false
	milestone_defeated_this_wave = false
	server_normal_enemy_count = int(wave_plan.get("normalCount", 0))
	server_wave_session_id = String(wave_plan.get("waveSessionId", ""))
	mono_normal_enemy_type = StringName(String(wave_plan.get("monoType", "")))
	server_normal_enemy_configs = _parse_server_enemy_configs(wave_plan.get("normalEnemies", []))
	server_boss_configs = wave_plan.get("bosses", {}) as Dictionary
	if mono_normal_enemy_type == &"" and server_normal_enemy_configs.is_empty():
		mono_normal_enemy_type = WaveEnemyTypeRules.roll_mono_normal_enemy_type(current_wave)
	SignalBus.emit_wave_changed(current_wave)
	if mono_normal_enemy_type != &"":
		SignalBus.emit_mono_wave_started(current_wave, mono_normal_enemy_type)

func _request_wave_plan(wave_number: int) -> Dictionary:
	if not BackendClient.enabled:
		return {}
	var result: Dictionary = await BackendClient.request_command("wave.start", {
		"wave": wave_number,
		"includeMilestone": not milestone_challenge.is_farm_wave(wave_number),
	})
	if bool(result.get("offline", false)) or not bool(result.get("success", false)):
		return {}
	var command_result: Dictionary = result.get("result", {}) as Dictionary
	var plan: Dictionary = command_result.get("plan", {}) as Dictionary
	plan["waveSessionId"] = String(command_result.get("waveSessionId", ""))
	return plan

func _complete_current_wave_on_server() -> bool:
	if BackendClient.logged_in:
		await BackendClient.flush_run_rewards()
		var result: Dictionary = await BackendClient.request_command("wave.complete", {
			"wave": current_wave,
			"waveSessionId": server_wave_session_id,
		}, false)
		if bool(result.get("success", false)):
			return true
		return false
	return false

func _get_server_enemy_config(spawn_kind: StringName) -> Dictionary:
	if spawn_kind == &"normal":
		if normal_spawned_this_wave < server_normal_enemy_configs.size():
			return server_normal_enemy_configs[normal_spawned_this_wave]
		return {}
	return server_boss_configs.get(String(spawn_kind), {}) as Dictionary

func _parse_server_enemy_configs(source: Variant) -> Array[Dictionary]:
	var parsed: Array[Dictionary] = []
	if source is not Array:
		return parsed
	for config_variant in source:
		if config_variant is Dictionary:
			parsed.append(config_variant as Dictionary)
	return parsed

func _apply_server_enemy_config(enemy: Enemy, config: Dictionary) -> StringName:
	enemy.max_hp = float(config.get("maxHp", enemy.max_hp))
	enemy.speed = float(config.get("speed", enemy.speed))
	enemy.attack_damage = float(config.get("attackDamage", enemy.attack_damage))
	enemy.defense = float(config.get("defense", enemy.defense))
	enemy.evasion = minf(GameConstants.ENEMY_MAX_EVASION, float(config.get("evasion", enemy.evasion)))
	enemy.accuracy = float(config.get("accuracy", enemy.accuracy))
	enemy.attack_range = float(config.get("attackRange", enemy.attack_range))
	enemy.attack_cooldown = float(config.get("attackCooldown", enemy.attack_cooldown))
	enemy.reward_gold = maxi(1, int(config.get("rewardGold", enemy.reward_gold)))
	enemy.reward_essence = maxi(1, int(config.get("rewardEssence", enemy.reward_essence)))
	enemy.server_instance_id = String(config.get("instanceId", ""))
	enemy.wave_number = maxi(1, int(config.get("waveNumber", current_wave)))
	enemy.body_radius = float(config.get("bodyRadius", enemy.body_radius))
	enemy.normal_enemy_type = StringName(String(config.get("normalEnemyType", GameConstants.ENEMY_TYPE_BASIC)))
	enemy.boss_kind = StringName(String(config.get("bossKind", &"none")))
	enemy.is_boss = bool(config.get("isBoss", false))
	return enemy.boss_kind
