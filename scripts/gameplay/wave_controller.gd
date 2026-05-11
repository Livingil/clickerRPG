extends Node
class_name WaveController

signal wave_changed(current_wave: int)

var current_wave: int = 1
var enemy_spawner: EnemySpawner
var normal_spawned_this_wave: int = 0
var boss_spawned_this_wave: bool = false
var wave_boss_defeated: bool = false
var milestone_spawned_this_wave: bool = false
var milestone_defeated_this_wave: bool = false

func bind_spawner(spawner: EnemySpawner) -> void:
	enemy_spawner = spawner
	enemy_spawner.set_wave_controller(self)
	_start_wave(1)

func advance_wave() -> void:
	_start_wave(current_wave + 1)

func reset_to_first_wave() -> void:
	_start_wave(1)

func get_spawn_requests(active_enemy_count: int, free_slots: int) -> Array[StringName]:
	var requests: Array[StringName] = []
	if free_slots <= 0:
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
	var hp_multiplier := pow(GameConstants.WAVE_ENEMY_HP_SCALE, current_wave - 1)
	var speed_multiplier := pow(GameConstants.WAVE_ENEMY_SPEED_SCALE, current_wave - 1)
	var damage_multiplier := pow(GameConstants.WAVE_ENEMY_DAMAGE_SCALE, current_wave - 1)
	var reward_multiplier := pow(GameConstants.WAVE_REWARD_SCALE, current_wave - 1)

	enemy.max_hp *= hp_multiplier
	enemy.speed *= speed_multiplier
	enemy.attack_damage *= damage_multiplier
	enemy.reward_gold = int(round(enemy.reward_gold * reward_multiplier))
	enemy.reward_essence = int(round(enemy.reward_essence * reward_multiplier))

	match spawn_kind:
		&"wave_boss":
			enemy.max_hp *= GameConstants.WAVE_BOSS_HP_MULTIPLIER
			enemy.speed *= GameConstants.WAVE_BOSS_SPEED_MULTIPLIER
			enemy.attack_damage *= GameConstants.WAVE_BOSS_DAMAGE_MULTIPLIER
			enemy.reward_gold = int(round(enemy.reward_gold * GameConstants.WAVE_BOSS_REWARD_GOLD_MULTIPLIER))
			enemy.reward_essence = int(round(enemy.reward_essence * GameConstants.WAVE_BOSS_REWARD_ESSENCE_MULTIPLIER))
			enemy.is_boss = true
			enemy.boss_kind = &"wave"
		&"mini_boss":
			enemy.max_hp *= GameConstants.MINI_BOSS_HP_MULTIPLIER
			enemy.speed *= GameConstants.MINI_BOSS_SPEED_MULTIPLIER
			enemy.attack_damage *= GameConstants.MINI_BOSS_DAMAGE_MULTIPLIER
			enemy.reward_gold = int(round(enemy.reward_gold * GameConstants.MINI_BOSS_REWARD_GOLD_MULTIPLIER))
			enemy.reward_essence = int(round(enemy.reward_essence * GameConstants.MINI_BOSS_REWARD_ESSENCE_MULTIPLIER))
			enemy.is_boss = true
			enemy.boss_kind = &"mini"
		&"grand_boss":
			enemy.max_hp *= GameConstants.GRAND_BOSS_HP_MULTIPLIER
			enemy.speed *= GameConstants.GRAND_BOSS_SPEED_MULTIPLIER
			enemy.attack_damage *= GameConstants.GRAND_BOSS_DAMAGE_MULTIPLIER
			enemy.reward_gold = int(round(enemy.reward_gold * GameConstants.GRAND_BOSS_REWARD_GOLD_MULTIPLIER))
			enemy.reward_essence = int(round(enemy.reward_essence * GameConstants.GRAND_BOSS_REWARD_ESSENCE_MULTIPLIER))
			enemy.is_boss = true
			enemy.boss_kind = &"grand"
		_:
			enemy.boss_kind = &"none"

func register_spawn(kind: StringName) -> void:
	match kind:
		&"normal":
			normal_spawned_this_wave += 1
		&"wave_boss":
			boss_spawned_this_wave = true
		&"mini_boss", &"grand_boss":
			milestone_spawned_this_wave = true

func handle_enemy_killed(enemy: Enemy, active_enemy_count: int) -> void:
	match enemy.boss_kind:
		&"wave":
			wave_boss_defeated = true
		&"mini", &"grand":
			milestone_defeated_this_wave = true

	if milestone_defeated_this_wave:
		call_deferred("advance_wave")
		return

	if _is_main_wave_cleared(active_enemy_count):
		if has_milestone_boss_for_current_wave():
			return
		call_deferred("advance_wave")

func get_normal_enemy_count() -> int:
	return GameConstants.BASE_NORMAL_ENEMIES_PER_WAVE + int(floor((current_wave - 1) / 2.0)) + (current_wave - 1)

func has_milestone_boss_for_current_wave() -> bool:
	return current_wave % 5 == 0

func get_milestone_spawn_kind() -> StringName:
	if current_wave % 10 == 0:
		return &"grand_boss"
	return &"mini_boss"

func _should_spawn_milestone_boss(active_enemy_count: int) -> bool:
	return has_milestone_boss_for_current_wave() \
		and _is_main_wave_cleared(active_enemy_count) \
		and not milestone_spawned_this_wave

func _is_main_wave_cleared(active_enemy_count: int) -> bool:
	return normal_spawned_this_wave >= get_normal_enemy_count() \
		and wave_boss_defeated \
		and active_enemy_count == 0

func _start_wave(wave_number: int) -> void:
	current_wave = wave_number
	normal_spawned_this_wave = 0
	boss_spawned_this_wave = false
	wave_boss_defeated = false
	milestone_spawned_this_wave = false
	milestone_defeated_this_wave = false
	wave_changed.emit(current_wave)
	SignalBus.wave_changed.emit(current_wave)
