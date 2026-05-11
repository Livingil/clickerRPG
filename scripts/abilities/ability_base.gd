extends RefCounted
class_name AbilityBase

func tick(_delta: float) -> void:
	pass

func on_hero_attack(_target: Enemy, _damage: float, _is_crit: bool, _school_id: StringName) -> void:
	pass

func get_display_name() -> String:
	return "Ability"
