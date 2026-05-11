extends Node
class_name AbilityController

const AbilityBase = preload("res://scripts/abilities/ability_base.gd")

var active_abilities: Array[AbilityBase] = []

func handle_hero_attack(target: Enemy, damage: float, is_crit: bool) -> void:
	for ability in active_abilities:
		ability.on_hero_attack(target, damage, is_crit)
