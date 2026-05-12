extends RefCounted
class_name CombatStats

var damage: float = 0.0
var max_hp: float = 0.0
var attack_speed: float = 0.0
var crit_chance: float = 0.0
var crit_multiplier: float = 1.0
var defense: float = 0.0
var evasion: float = 0.0
var accuracy: float = 0.0

func compute_dps() -> float:
	return damage * attack_speed * (1.0 + crit_chance * (crit_multiplier - 1.0))

static func compute_hit_chance(accuracy_value: float, evasion_value: float) -> float:
	return clampf(0.6 + (accuracy_value - evasion_value) * 0.004, 0.15, 0.98)

static func apply_defense(raw_damage: float, defense_value: float) -> float:
	return raw_damage * (100.0 / (100.0 + maxf(0.0, defense_value)))
