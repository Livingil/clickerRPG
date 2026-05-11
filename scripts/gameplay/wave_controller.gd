extends Node
class_name WaveController

signal wave_changed(current_wave: int)

var current_wave: int = 1
var enemy_spawner: EnemySpawner
var normal_spawned_this_wave: int = 0
var boss_spawned_this_wave: bool = false

func bind_spawner(spawner: EnemySpawner) -> void:
	enemy_spawner = spawner
	enemy_spawner.set_wave_controller(self)
	_start_wave(1)

func advance_wave() -> void:
	_start_wave(current_wave + 1)

func get_next_spawn_kind(active_enemy_count: int) -> StringName:
	if normal_spawned_this_wave < get_normal_enemy_count():
		return &"normal"

	if not boss_spawned_this_wave and active_enemy_count == 0:
		boss_spawned_this_wave = true
		return &"boss"

	return &"none"

func configure_enemy(enemy: Enemy, is_boss: bool) -> void:
	var hp_multiplier := pow(GameConstants.WAVE_ENEMY_HP_SCALE, current_wave - 1)
	var speed_multiplier := pow(GameConstants.WAVE_ENEMY_SPEED_SCALE, current_wave - 1)
	var reward_multiplier := pow(GameConstants.WAVE_REWARD_SCALE, current_wave - 1)

	if is_boss:
		enemy.max_hp *= hp_multiplier * GameConstants.BOSS_BASE_HP_MULTIPLIER
		enemy.speed *= speed_multiplier * GameConstants.BOSS_BASE_SPEED_MULTIPLIER
		enemy.reward_gold = int(round(enemy.reward_gold * reward_multiplier * GameConstants.BOSS_REWARD_GOLD_MULTIPLIER))
		enemy.reward_essence = int(round(enemy.reward_essence * reward_multiplier * GameConstants.BOSS_REWARD_ESSENCE_MULTIPLIER))
		enemy.is_boss = true
	else:
		enemy.max_hp *= hp_multiplier
		enemy.speed *= speed_multiplier
		enemy.reward_gold = int(round(enemy.reward_gold * reward_multiplier))
		enemy.reward_essence = int(round(enemy.reward_essence * reward_multiplier))

func register_spawn(kind: StringName) -> void:
	if kind == &"normal":
		normal_spawned_this_wave += 1

func handle_enemy_killed(enemy: Enemy) -> void:
	if enemy.is_boss:
		call_deferred("advance_wave")

func get_normal_enemy_count() -> int:
	return GameConstants.BASE_NORMAL_ENEMIES_PER_WAVE + current_wave - 1

func _start_wave(wave_number: int) -> void:
	current_wave = wave_number
	normal_spawned_this_wave = 0
	boss_spawned_this_wave = false
	wave_changed.emit(current_wave)
	SignalBus.wave_changed.emit(current_wave)
