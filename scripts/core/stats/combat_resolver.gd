extends RefCounted
class_name CombatResolver

static func resolve_hero_attack(
	hero_stats: HeroStatsComponent,
	target: Enemy,
	school_id: StringName,
	extra_scale: float = 0.0,
	crit_chance_override: float = -1.0,
	crit_multiplier_override: float = -1.0,
	damage_override: float = -1.0
) -> Dictionary:
	var damage: float = hero_stats.get_damage() if damage_override < 0.0 else damage_override
	var crit_chance: float = hero_stats.get_crit_chance() if crit_chance_override < 0.0 else crit_chance_override
	var crit_multiplier: float = hero_stats.get_crit_multiplier() if crit_multiplier_override < 0.0 else crit_multiplier_override
	var accuracy: float = hero_stats.get_accuracy()
	var local_result := _resolve_hero_attack_local(
		damage,
		crit_chance,
		crit_multiplier,
		accuracy,
		target,
		school_id,
		extra_scale
	)
	if BackendClient.enabled and BackendClient.logged_in:
		var result: Dictionary = await BackendClient.request_command(
			"combat.heroAttack",
			_build_hero_attack_payload(hero_stats, target, school_id, damage, extra_scale, crit_chance, crit_multiplier)
		)
		if bool(result.get("success", false)):
			return result
	return local_result

static func apply_school_hit(
	hero_stats: HeroStatsComponent,
	target: Enemy,
	school_id: StringName,
	damage: float,
	mastery_xp: int = 0
) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var result := await resolve_hero_attack(hero_stats, target, school_id, 0.0, 0.0, 1.0, damage)
	if not is_instance_valid(target):
		return false
	var hit := target.receive_resolved_school_hit(result, school_id, hero_stats.get_accuracy())
	if hit and mastery_xp > 0:
		GameState.add_school_mastery_xp(school_id, mastery_xp)
	return hit

static func apply_school_hit_batch(
	hero_stats: HeroStatsComponent,
	targets: Array[Enemy],
	school_id: StringName,
	damage: float
) -> Array[Enemy]:
	var alive_targets: Array[Enemy] = []
	for target in targets:
		if target != null and is_instance_valid(target):
			alive_targets.append(target)
	if alive_targets.is_empty():
		return []

	var results: Array = []
	if BackendClient.enabled and BackendClient.logged_in:
		var hits: Array[Dictionary] = []
		for target in alive_targets:
			hits.append(_build_hero_attack_payload(hero_stats, target, school_id, damage, 0.0, 0.0, 1.0))
		var batch_result: Dictionary = await BackendClient.request_command("combat.heroAttackBatch", {"hits": hits})
		if bool(batch_result.get("success", false)):
			results = batch_result.get("hits", []) as Array

	if results.is_empty():
		for target in alive_targets:
			results.append(_resolve_hero_attack_local(
				damage,
				0.0,
				1.0,
				hero_stats.get_accuracy(),
				target,
				school_id,
				0.0
			))

	var hit_targets: Array[Enemy] = []
	for i in range(mini(alive_targets.size(), results.size())):
		var target := alive_targets[i]
		if not is_instance_valid(target):
			continue
		var result: Dictionary = results[i] as Dictionary
		if target.receive_resolved_school_hit(result, school_id, hero_stats.get_accuracy()):
			hit_targets.append(target)
	return hit_targets

static func resolve_enemy_attack(
	attacker: Enemy,
	target: Hero,
	damage: float,
	accuracy: float
) -> Dictionary:
	var local_result := _resolve_enemy_attack_local(attacker, target, damage, accuracy)
	if BackendClient.enabled and BackendClient.logged_in:
		var result: Dictionary = await BackendClient.request_command("combat.enemyAttack", {
			"damage": damage,
			"accuracy": accuracy,
			"targetEvasion": target.stats_component.get_evasion(),
			"targetDefense": target.get_effective_defense(),
			"isBoss": false if attacker == null else attacker.is_boss,
		})
		if bool(result.get("success", false)):
			return result
	return local_result

static func _build_hero_attack_payload(
	hero_stats: HeroStatsComponent,
	target: Enemy,
	school_id: StringName,
	damage: float,
	extra_scale: float,
	crit_chance: float,
	crit_multiplier: float
) -> Dictionary:
	return {
		"damage": damage,
		"critChance": crit_chance,
		"critMultiplier": crit_multiplier,
		"accuracy": hero_stats.get_accuracy(),
		"targetEvasion": target.evasion,
		"targetDefense": target.get_effective_defense(),
		"vulnerabilityMultiplier": target.get_vulnerability_multiplier(school_id),
		"extraScale": extra_scale,
		"isBoss": target.is_boss,
	}

static func _resolve_hero_attack_local(
	damage: float,
	crit_chance: float,
	crit_multiplier: float,
	accuracy: float,
	target: Enemy,
	school_id: StringName,
	extra_scale: float
) -> Dictionary:
	var hit_chance := CombatStats.compute_hit_chance(accuracy, target.evasion)
	var hit := randf() <= hit_chance
	var is_crit := hit and randf() < crit_chance
	var raw_damage := damage
	if is_crit:
		raw_damage *= crit_multiplier
	if extra_scale > 0.0:
		raw_damage *= (1.0 + extra_scale)
	if target.is_boss:
		raw_damage *= GameState.get_boss_damage_multiplier()
	var school_damage := raw_damage * target.get_vulnerability_multiplier(school_id)
	return {
		"success": true,
		"hit": hit,
		"isCrit": is_crit,
		"hitChance": hit_chance,
		"rawDamage": raw_damage,
		"schoolDamage": school_damage,
		"damageTaken": CombatStats.apply_defense(school_damage, target.get_effective_defense()) if hit else 0.0,
		"masteryXp": 1 if hit else 0,
	}

static func _resolve_enemy_attack_local(attacker: Enemy, target: Hero, damage: float, accuracy: float) -> Dictionary:
	var blocked := GameState.should_block_incoming_hit()
	var raw_damage := damage
	if attacker != null and attacker.is_boss:
		raw_damage *= GameState.get_boss_incoming_damage_multiplier()
	var hit_chance := 0.0 if blocked else CombatStats.compute_hit_chance(accuracy, target.stats_component.get_evasion())
	var hit := not blocked and randf() <= hit_chance
	return {
		"success": true,
		"blocked": blocked,
		"hit": hit,
		"hitChance": hit_chance,
		"rawDamage": raw_damage,
		"damageTaken": CombatStats.apply_defense(raw_damage, target.get_effective_defense()) if hit else 0.0,
	}
