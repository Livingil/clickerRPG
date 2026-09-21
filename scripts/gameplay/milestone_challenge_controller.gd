extends RefCounted
class_name MilestoneChallengeController

const CHALLENGE_STATE_EMIT_INTERVAL: float = 0.10

var skipped_milestone_waves: Dictionary = {}
var challenge_active: bool = false
var challenge_time_left: float = 0.0
var challenge_wave: int = -1
var challenge_kind: StringName = &"none"
var challenge_retry_available: bool = false
var farm_mode_active: bool = false
var farm_wave_number: int = -1
var farm_wave_boss_alive: bool = false
var challenge_state_emit_cooldown: float = 0.0

func process(delta: float) -> bool:
	if not challenge_active:
		return false
	challenge_time_left = maxf(0.0, challenge_time_left - delta)
	challenge_state_emit_cooldown = maxf(0.0, challenge_state_emit_cooldown - delta)
	if challenge_state_emit_cooldown <= 0.0:
		emit_challenge_state()
	if challenge_time_left <= 0.0:
		fail_current_challenge()
		return true
	return false

func reset_for_new_run() -> void:
	challenge_active = false
	challenge_time_left = 0.0
	challenge_wave = -1
	challenge_kind = &"none"
	challenge_retry_available = false
	farm_mode_active = false
	farm_wave_number = -1
	farm_wave_boss_alive = false
	skipped_milestone_waves.clear()
	emit_challenge_state()

func on_wave_started(wave: int) -> void:
	if challenge_retry_available and challenge_wave != wave:
		challenge_retry_available = false
		challenge_wave = -1
		challenge_kind = &"none"
		emit_challenge_state()
	if farm_mode_active and farm_wave_number != wave:
		farm_mode_active = false
		farm_wave_number = -1
		farm_wave_boss_alive = false

func is_farm_wave(wave: int) -> bool:
	return farm_mode_active and wave == farm_wave_number

func should_spawn_farm_boss(wave: int) -> bool:
	return is_farm_wave(wave) and not farm_wave_boss_alive

func on_wave_boss_spawned(wave: int) -> void:
	if is_farm_wave(wave):
		farm_wave_boss_alive = true

func on_wave_boss_killed(wave: int) -> void:
	if is_farm_wave(wave):
		farm_wave_boss_alive = false

func has_milestone_boss_for_wave(wave: int) -> bool:
	if skipped_milestone_waves.has(wave):
		return false
	return wave % 5 == 0

func get_milestone_spawn_kind(wave: int) -> StringName:
	if wave % 100 == 0:
		return &"apex_boss"
	if wave % 10 == 0:
		return &"grand_boss"
	return &"mini_boss"

func should_spawn_milestone_boss(wave: int, is_main_wave_cleared: bool, milestone_spawned_this_wave: bool) -> bool:
	return has_milestone_boss_for_wave(wave) and is_main_wave_cleared and not milestone_spawned_this_wave

func start_if_timed(wave: int, boss_kind: StringName) -> void:
	if not is_timed_challenge_kind(boss_kind):
		return
	challenge_active = true
	challenge_time_left = GameState.get_milestone_challenge_time_limit()
	challenge_wave = wave
	challenge_kind = boss_kind
	challenge_retry_available = false
	emit_challenge_state()

func on_milestone_boss_defeated(wave: int, boss_kind: StringName) -> void:
	if challenge_active and wave == challenge_wave and boss_kind == challenge_kind:
		challenge_active = false
		challenge_time_left = 0.0
		challenge_retry_available = false
		emit_challenge_state()
	if farm_mode_active and wave == farm_wave_number and wave == challenge_wave and boss_kind == challenge_kind:
		farm_mode_active = false
		farm_wave_number = -1
		farm_wave_boss_alive = false
		challenge_retry_available = false
		skipped_milestone_waves.erase(wave)
		emit_challenge_state()

func consume_retry_request(wave: int, can_spawn_retry: bool) -> StringName:
	if not challenge_retry_available:
		return &""
	if wave != challenge_wave:
		return &""
	if not can_spawn_retry:
		return &""
	challenge_retry_available = false
	skipped_milestone_waves.erase(wave)
	emit_challenge_state()
	return get_milestone_spawn_kind(wave)

func fail_current_challenge() -> void:
	challenge_active = false
	challenge_time_left = 0.0
	challenge_retry_available = true
	skipped_milestone_waves[challenge_wave] = true
	farm_mode_active = true
	farm_wave_number = challenge_wave
	farm_wave_boss_alive = false
	emit_challenge_state()

func emit_challenge_state() -> void:
	challenge_state_emit_cooldown = CHALLENGE_STATE_EMIT_INTERVAL
	SignalBus.emit_milestone_challenge_state_changed(
		challenge_active,
		challenge_time_left,
		challenge_wave,
		challenge_retry_available
	)

func is_timed_challenge_kind(boss_kind: StringName) -> bool:
	return boss_kind == &"grand" or boss_kind == &"apex"
