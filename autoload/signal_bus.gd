extends Node

signal enemy_spawned(enemy: Node)
signal enemy_killed(enemy: Node)
signal hero_attack_performed(target: Node, damage: float, is_crit: bool)
signal hero_died
signal wave_changed(current_wave: int)

func emit_enemy_spawned(enemy: Node) -> void:
	enemy_spawned.emit(enemy)

func emit_enemy_killed(enemy: Node) -> void:
	enemy_killed.emit(enemy)

func emit_hero_attack_performed(target: Node, damage: float, is_crit: bool) -> void:
	hero_attack_performed.emit(target, damage, is_crit)

func emit_hero_died() -> void:
	hero_died.emit()

func emit_wave_changed(current_wave: int) -> void:
	wave_changed.emit(current_wave)
