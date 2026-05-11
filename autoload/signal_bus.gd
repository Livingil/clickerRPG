extends Node

signal enemy_spawned(enemy: Node)
signal enemy_killed(enemy: Node)
signal hero_attack_performed(target: Node, damage: float, is_crit: bool)
signal hero_died
signal wave_changed(current_wave: int)
