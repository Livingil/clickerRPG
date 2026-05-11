extends RefCounted
class_name CombatStats

var damage: float = 0.0
var attack_speed: float = 0.0
var crit_chance: float = 0.0
var crit_multiplier: float = 1.0

func compute_dps() -> float:
	return damage * attack_speed * (1.0 + crit_chance * (crit_multiplier - 1.0))
