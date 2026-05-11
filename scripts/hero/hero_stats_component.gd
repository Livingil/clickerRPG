extends Node
class_name HeroStatsComponent

var current_stats: CombatStats = CombatStats.new()

func rebuild_from_game_state() -> void:
	current_stats = GameState.build_hero_stats()

func get_damage() -> float:
	return current_stats.damage

func get_attack_speed() -> float:
	return current_stats.attack_speed

func get_crit_chance() -> float:
	return current_stats.crit_chance

func get_crit_multiplier() -> float:
	return current_stats.crit_multiplier
