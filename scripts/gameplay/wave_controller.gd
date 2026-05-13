extends Node
class_name WaveController

var current_wave: int = 1
var enemy_spawner: EnemySpawner
var normal_spawned_this_wave: int = 0
var boss_spawned_this_wave: bool = false
var wave_boss_defeated: bool = false
var milestone_spawned_this_wave: bool = false
var milestone_defeated_this_wave: bool = false
var skipped_milestone_waves: Dictionary = {}
var challenge_active: bool = false
var challenge_time_left: float = 0.0
var challenge_wave: int = -1
var challenge_kind: StringName = &"none"
var challenge_retry_available: bool = false
var farm_mode_active: bool = false
var farm_wave_number: int = -1
var farm_wave_boss_alive: bool = false

const MILESTONE_CHALLENGE_TIME_LIMIT: float = 30.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if not challenge_active:
		return
	challenge_time_left = maxf(0.0, challenge_time_left - delta)
	_emit_challenge_state()
	if challenge_time_left <= 0.0:
		_fail_milestone_challenge()

func bind_spawner(spawner: EnemySpawner) -> void:
	enemy_spawner = spawner
	enemy_spawner.set_wave_controller(self)
	if not SignalBus.milestone_challenge_retry_requested.is_connected(_on_milestone_retry_requested):
		SignalBus.milestone_challenge_retry_requested.connect(_on_milestone_retry_requested)
	_start_wave(1)

func advance_wave() -> void:
	_start_wave(current_wave + 1)

func reset_to_first_wave() -> void:
	_reset_challenge_and_farm_for_new_run()
	_start_wave(1)

func get_spawn_requests(active_enemy_count: int, free_slots: int) -> Array[StringName]:
	var requests: Array[StringName] = []
	if free_slots <= 0:
		return requests

	if farm_mode_active and current_wave == farm_wave_number:
		if not farm_wave_boss_alive:
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
	var wave_offset: int = maxi(0, current_wave - 1)
	var hp_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_HP_EARLY,
		GameConstants.BALANCE_WAVE_HP_MID,
		GameConstants.BALANCE_WAVE_HP_LATE
	)
	var speed_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_SPEED_EARLY,
		GameConstants.BALANCE_WAVE_SPEED_MID,
		GameConstants.BALANCE_WAVE_SPEED_LATE
	)
	var damage_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_DMG_EARLY,
		GameConstants.BALANCE_WAVE_DMG_MID,
		GameConstants.BALANCE_WAVE_DMG_LATE
	)
	var defense_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_DEF_EARLY,
		GameConstants.BALANCE_WAVE_DEF_MID,
		GameConstants.BALANCE_WAVE_DEF_LATE
	)
	var evasion_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_EVA_EARLY,
		GameConstants.BALANCE_WAVE_EVA_MID,
		GameConstants.BALANCE_WAVE_EVA_LATE
	)
	var accuracy_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_ACC_EARLY,
		GameConstants.BALANCE_WAVE_ACC_MID,
		GameConstants.BALANCE_WAVE_ACC_LATE
	)
	var reward_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_REWARD_EARLY,
		GameConstants.BALANCE_WAVE_REWARD_MID,
		GameConstants.BALANCE_WAVE_REWARD_LATE
	)

	enemy.max_hp *= hp_multiplier
	enemy.speed *= speed_multiplier
	enemy.attack_damage *= damage_multiplier
	enemy.defense *= defense_multiplier
	enemy.evasion *= evasion_multiplier
	enemy.accuracy *= accuracy_multiplier
	enemy.wave_number = current_wave
	enemy.evasion = minf(enemy.evasion, GameConstants.ENEMY_MAX_EVASION)
	# Gold is now fully wave-driven and independent from enemy scene defaults.
	enemy.reward_gold = _compute_wave_gold_reward(spawn_kind, reward_multiplier)
	enemy.reward_essence = int(round(enemy.reward_essence * reward_multiplier))

	match spawn_kind:
		&"wave_boss":
			enemy.max_hp *= GameConstants.WAVE_BOSS_HP_MULTIPLIER
			enemy.speed *= GameConstants.WAVE_BOSS_SPEED_MULTIPLIER
			enemy.attack_damage *= GameConstants.WAVE_BOSS_DAMAGE_MULTIPLIER
			enemy.reward_essence = int(round(enemy.reward_essence * GameConstants.WAVE_BOSS_REWARD_ESSENCE_MULTIPLIER))
			enemy.is_boss = true
			enemy.boss_kind = &"wave"
		&"mini_boss":
			enemy.max_hp *= GameConstants.MINI_BOSS_HP_MULTIPLIER
			enemy.speed *= GameConstants.MINI_BOSS_SPEED_MULTIPLIER
			enemy.attack_damage *= GameConstants.MINI_BOSS_DAMAGE_MULTIPLIER
			enemy.reward_essence = int(round(enemy.reward_essence * GameConstants.MINI_BOSS_REWARD_ESSENCE_MULTIPLIER))
			enemy.is_boss = true
			enemy.boss_kind = &"mini"
		&"grand_boss":
			enemy.max_hp *= GameConstants.GRAND_BOSS_HP_MULTIPLIER
			enemy.speed *= GameConstants.GRAND_BOSS_SPEED_MULTIPLIER
			enemy.attack_damage *= GameConstants.GRAND_BOSS_DAMAGE_MULTIPLIER
			enemy.reward_essence = int(round(enemy.reward_essence * GameConstants.GRAND_BOSS_REWARD_ESSENCE_MULTIPLIER))
			enemy.is_boss = true
			enemy.boss_kind = &"grand"
		&"apex_boss":
			enemy.max_hp *= GameConstants.APEX_BOSS_HP_MULTIPLIER
			enemy.speed *= GameConstants.APEX_BOSS_SPEED_MULTIPLIER
			enemy.attack_damage *= GameConstants.APEX_BOSS_DAMAGE_MULTIPLIER
			enemy.reward_essence = int(round(enemy.reward_essence * GameConstants.APEX_BOSS_REWARD_ESSENCE_MULTIPLIER))
			enemy.is_boss = true
			enemy.boss_kind = &"apex"
		_:
			enemy.boss_kind = &"none"
	if _is_timed_milestone_challenge_kind(enemy.boss_kind):
		_start_milestone_challenge(current_wave, enemy.boss_kind)

func _compute_wave_gold_reward(spawn_kind: StringName, reward_multiplier: float) -> int:
	var kind_multiplier: float = 1.0
	match spawn_kind:
		&"wave_boss":
			kind_multiplier = GameConstants.WAVE_BOSS_REWARD_GOLD_MULTIPLIER
		&"mini_boss":
			kind_multiplier = GameConstants.MINI_BOSS_REWARD_GOLD_MULTIPLIER
		&"grand_boss":
			kind_multiplier = GameConstants.GRAND_BOSS_REWARD_GOLD_MULTIPLIER
		&"apex_boss":
			kind_multiplier = GameConstants.APEX_BOSS_REWARD_GOLD_MULTIPLIER
		_:
			kind_multiplier = 1.0
	var raw: float = GameConstants.ENEMY_REWARD_GOLD * reward_multiplier * kind_multiplier
	return maxi(1, int(round(raw)))

func register_spawn(kind: StringName) -> void:
	match kind:
		&"normal":
			normal_spawned_this_wave += 1
		&"wave_boss":
			boss_spawned_this_wave = true
			if farm_mode_active and current_wave == farm_wave_number:
				farm_wave_boss_alive = true
		&"mini_boss", &"grand_boss", &"apex_boss":
			milestone_spawned_this_wave = true

func handle_enemy_killed(enemy: Enemy, active_enemy_count: int) -> void:
	match enemy.boss_kind:
		&"wave":
			wave_boss_defeated = true
			if farm_mode_active and current_wave == farm_wave_number:
				farm_wave_boss_alive = false
		&"mini", &"grand", &"apex":
			_on_milestone_boss_defeated(enemy.boss_kind)
			milestone_defeated_this_wave = true
			if enemy.boss_kind == &"apex":
				GameState.register_apex_boss_kill(current_wave)

	if milestone_defeated_this_wave:
		call_deferred("advance_wave")
		return

	if farm_mode_active and current_wave == farm_wave_number:
		return

	if _is_main_wave_cleared(active_enemy_count):
		if has_milestone_boss_for_current_wave():
			return
		call_deferred("advance_wave")

func get_normal_enemy_count() -> int:
	return GameConstants.BASE_NORMAL_ENEMIES_PER_WAVE + int(floor((current_wave - 1) / 2.0)) + (current_wave - 1)

func has_milestone_boss_for_current_wave() -> bool:
	if skipped_milestone_waves.has(current_wave):
		return false
	return current_wave % 5 == 0

func get_milestone_spawn_kind() -> StringName:
	if current_wave % 100 == 0:
		return &"apex_boss"
	if current_wave % 10 == 0:
		return &"grand_boss"
	return &"mini_boss"

func _should_spawn_milestone_boss(active_enemy_count: int) -> bool:
	return has_milestone_boss_for_current_wave() \
		and _is_main_wave_cleared(active_enemy_count) \
		and not milestone_spawned_this_wave

func _is_timed_milestone_challenge_kind(boss_kind: StringName) -> bool:
	return boss_kind == &"grand" or boss_kind == &"apex"

func _start_milestone_challenge(wave_number: int, boss_kind: StringName) -> void:
	challenge_active = true
	challenge_time_left = MILESTONE_CHALLENGE_TIME_LIMIT
	challenge_wave = wave_number
	challenge_kind = boss_kind
	challenge_retry_available = false
	_emit_challenge_state()

func _on_milestone_boss_defeated(boss_kind: StringName) -> void:
	if challenge_active and current_wave == challenge_wave and boss_kind == challenge_kind:
		challenge_active = false
		challenge_time_left = 0.0
		challenge_retry_available = false
		_emit_challenge_state()
	if farm_mode_active and current_wave == farm_wave_number and current_wave == challenge_wave and boss_kind == challenge_kind:
		farm_mode_active = false
		farm_wave_number = -1
		farm_wave_boss_alive = false
		challenge_retry_available = false
		skipped_milestone_waves.erase(current_wave)
		_emit_challenge_state()

func _fail_milestone_challenge() -> void:
	challenge_active = false
	challenge_time_left = 0.0
	challenge_retry_available = true
	skipped_milestone_waves[current_wave] = true
	farm_mode_active = true
	farm_wave_number = current_wave
	farm_wave_boss_alive = false
	_emit_challenge_state()
	_restart_current_wave_without_milestone()

func _reset_challenge_and_farm_for_new_run() -> void:
	challenge_active = false
	challenge_time_left = 0.0
	challenge_wave = -1
	challenge_kind = &"none"
	challenge_retry_available = false
	farm_mode_active = false
	farm_wave_number = -1
	farm_wave_boss_alive = false
	skipped_milestone_waves.clear()
	_emit_challenge_state()

func _restart_current_wave_without_milestone() -> void:
	if enemy_spawner != null:
		enemy_spawner.clear_active_enemies()
	_start_wave(current_wave)

func _on_milestone_retry_requested() -> void:
	if not challenge_retry_available:
		return
	if enemy_spawner == null:
		return
	if current_wave != challenge_wave:
		return
	if not _is_main_wave_cleared(enemy_spawner.active_enemies.size()):
		return
	if milestone_spawned_this_wave:
		return
	challenge_retry_available = false
	skipped_milestone_waves.erase(current_wave)
	_emit_challenge_state()
	var retry_kind: StringName = get_milestone_spawn_kind()
	enemy_spawner.spawn_enemy(retry_kind)

func _emit_challenge_state() -> void:
	SignalBus.emit_milestone_challenge_state_changed(
		challenge_active,
		challenge_time_left,
		challenge_wave,
		challenge_retry_available
	)

func _is_main_wave_cleared(active_enemy_count: int) -> bool:
	return normal_spawned_this_wave >= get_normal_enemy_count() \
		and wave_boss_defeated \
		and active_enemy_count == 0

func _start_wave(wave_number: int) -> void:
	if challenge_retry_available and challenge_wave != wave_number:
		challenge_retry_available = false
		challenge_wave = -1
		challenge_kind = &"none"
		_emit_challenge_state()
	if farm_mode_active and farm_wave_number != wave_number:
		farm_mode_active = false
		farm_wave_number = -1
		farm_wave_boss_alive = false
	current_wave = wave_number
	normal_spawned_this_wave = 0
	boss_spawned_this_wave = false
	wave_boss_defeated = false
	milestone_spawned_this_wave = false
	milestone_defeated_this_wave = false
	SignalBus.emit_wave_changed(current_wave)
