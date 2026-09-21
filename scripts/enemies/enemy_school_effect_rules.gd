extends RefCounted
class_name EnemySchoolEffectRules

static func get_movement_speed_multiplier(is_frozen: bool, water_stacks: int) -> float:
	if is_frozen:
		return 0.0
	return clampf(1.0 - float(water_stacks) * SchoolRules.WATER_CHILL_MOVE_SLOW_PER_STACK, 0.35, 1.0)

static func get_attack_recovery_multiplier(is_frozen: bool, water_stacks: int) -> float:
	if is_frozen:
		return 0.0
	return clampf(1.0 - float(water_stacks) * SchoolRules.WATER_CHILL_ATTACK_SLOW_PER_STACK, 0.45, 1.0)

static func get_effective_defense(base_defense: float, earth_stacks: int, is_boss: bool) -> float:
	if earth_stacks <= 0:
		return base_defense
	var break_per_stack: float = SchoolRules.EARTH_DEFENSE_BREAK_PER_STACK
	if is_boss:
		break_per_stack *= SchoolRules.EARTH_DEFENSE_BREAK_BOSS_MULTIPLIER
	var defense_multiplier: float = clampf(1.0 - float(earth_stacks) * break_per_stack, 0.45, 1.0)
	return base_defense * defense_multiplier

static func get_effective_accuracy(base_accuracy: float, air_stacks: int, is_boss: bool) -> float:
	if air_stacks <= 0:
		return base_accuracy
	var break_per_stack: float = SchoolRules.AIR_ACCURACY_BREAK_PER_STACK
	if is_boss:
		break_per_stack *= SchoolRules.AIR_ACCURACY_BREAK_BOSS_MULTIPLIER
	var accuracy_multiplier: float = clampf(1.0 - float(air_stacks) * break_per_stack, 0.55, 1.0)
	return base_accuracy * accuracy_multiplier

static func get_vulnerability_multiplier(school_id: StringName, stacks: int) -> float:
	var stack_bonus: float = SchoolRules.VULNERABILITY_STACK_BONUS
	if school_id == SchoolRules.SCHOOL_LIGHTNING:
		stack_bonus = SchoolRules.LIGHTNING_DAMAGE_PER_STACK
	return 1.0 + stacks * stack_bonus

static func get_next_burn_tick_damage(hit_damage: float, fire_stacks: int, base_ratio: float, stack_bonus_ratio: float, max_multiplier: float) -> float:
	var multiplier: float = minf(max_multiplier, 1.0 + float(fire_stacks) * stack_bonus_ratio)
	return hit_damage * base_ratio * multiplier

static func get_effective_freeze_duration(duration: float, is_boss: bool) -> float:
	if is_boss:
		return duration * SchoolRules.WATER_BOSS_FREEZE_MULTIPLIER
	return duration
