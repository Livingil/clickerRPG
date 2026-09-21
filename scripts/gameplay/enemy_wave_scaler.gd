extends RefCounted
class_name EnemyWaveScaler

static func configure_enemy(enemy: Enemy, spawn_kind: StringName, wave: int, normal_enemy_type: StringName) -> StringName:
	var wave_offset: int = maxi(0, wave - 1)
	var hp_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_HP_EARLY,
		GameConstants.BALANCE_WAVE_HP_MID,
		GameConstants.BALANCE_WAVE_HP_LATE
	)
	var speed_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_SPEED_EARLY,
		GameConstants.BALANCE_WAVE_SPEED_MID,
		GameConstants.BALANCE_WAVE_SPEED_LATE
	)
	var damage_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_DMG_EARLY,
		GameConstants.BALANCE_WAVE_DMG_MID,
		GameConstants.BALANCE_WAVE_DMG_LATE
	)
	var defense_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_DEF_EARLY,
		GameConstants.BALANCE_WAVE_DEF_MID,
		GameConstants.BALANCE_WAVE_DEF_LATE
	)
	var evasion_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_EVA_EARLY,
		GameConstants.BALANCE_WAVE_EVA_MID,
		GameConstants.BALANCE_WAVE_EVA_LATE
	)
	var accuracy_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_ACC_EARLY,
		GameConstants.BALANCE_WAVE_ACC_MID,
		GameConstants.BALANCE_WAVE_ACC_LATE
	)
	var reward_multiplier: float = GameConstants.progressive_wave_multiplier(
		wave_offset,
		GameConstants.BALANCE_WAVE_REWARD_EARLY,
		GameConstants.BALANCE_WAVE_REWARD_MID,
		GameConstants.BALANCE_WAVE_REWARD_LATE
	)
	var enemy_hp_pressure: float = GameConstants.enemy_post_prestige_hp_pressure_multiplier(wave)
	var enemy_damage_pressure: float = GameConstants.enemy_post_prestige_damage_pressure_multiplier(wave)
	var enemy_defense_pressure: float = GameConstants.enemy_post_prestige_defense_pressure_multiplier(wave)
	var enemy_speed_pressure: float = GameConstants.enemy_post_prestige_speed_pressure_multiplier(wave)
	var enemy_evasion_pressure: float = GameConstants.enemy_post_prestige_evasion_pressure_multiplier(wave)
	var enemy_accuracy_pressure: float = GameConstants.enemy_post_prestige_accuracy_pressure_multiplier(wave)
	var boss_hp_pressure: float = GameConstants.boss_post_prestige_hp_pressure_multiplier(wave)
	var boss_damage_pressure: float = GameConstants.boss_post_prestige_damage_pressure_multiplier(wave)
	var boss_defense_pressure: float = GameConstants.boss_post_prestige_defense_pressure_multiplier(wave)
	var boss_speed_pressure: float = GameConstants.boss_post_prestige_speed_pressure_multiplier(wave)
	var boss_evasion_pressure: float = GameConstants.boss_post_prestige_evasion_pressure_multiplier(wave)
	var boss_accuracy_pressure: float = GameConstants.boss_post_prestige_accuracy_pressure_multiplier(wave)

	enemy.max_hp *= hp_multiplier * enemy_hp_pressure
	enemy.speed *= speed_multiplier * enemy_speed_pressure
	enemy.attack_damage *= damage_multiplier * enemy_damage_pressure
	enemy.defense *= defense_multiplier * enemy_defense_pressure
	enemy.evasion *= evasion_multiplier * enemy_evasion_pressure
	enemy.accuracy *= accuracy_multiplier * enemy_accuracy_pressure
	enemy.wave_number = wave
	enemy.evasion = minf(enemy.evasion, GameConstants.ENEMY_MAX_EVASION)
	enemy.reward_gold = _compute_wave_gold_reward(spawn_kind, reward_multiplier)
	enemy.reward_essence = int(round(enemy.reward_essence * reward_multiplier))

	match spawn_kind:
		&"wave_boss":
			_apply_boss_scaling(
				enemy,
				GameConstants.WAVE_BOSS_HP_MULTIPLIER,
				GameConstants.WAVE_BOSS_SPEED_MULTIPLIER,
				GameConstants.WAVE_BOSS_DAMAGE_MULTIPLIER,
				GameConstants.WAVE_BOSS_REWARD_ESSENCE_MULTIPLIER,
				boss_hp_pressure,
				boss_speed_pressure,
				boss_damage_pressure,
				boss_defense_pressure,
				boss_evasion_pressure,
				boss_accuracy_pressure
			)
			enemy.boss_kind = &"wave"
		&"mini_boss":
			_apply_boss_scaling(
				enemy,
				GameConstants.MINI_BOSS_HP_MULTIPLIER,
				GameConstants.MINI_BOSS_SPEED_MULTIPLIER,
				GameConstants.MINI_BOSS_DAMAGE_MULTIPLIER,
				GameConstants.MINI_BOSS_REWARD_ESSENCE_MULTIPLIER,
				boss_hp_pressure,
				boss_speed_pressure,
				boss_damage_pressure,
				boss_defense_pressure,
				boss_evasion_pressure,
				boss_accuracy_pressure
			)
			enemy.boss_kind = &"mini"
		&"grand_boss":
			_apply_boss_scaling(
				enemy,
				GameConstants.GRAND_BOSS_HP_MULTIPLIER,
				GameConstants.GRAND_BOSS_SPEED_MULTIPLIER,
				GameConstants.GRAND_BOSS_DAMAGE_MULTIPLIER,
				GameConstants.GRAND_BOSS_REWARD_ESSENCE_MULTIPLIER,
				boss_hp_pressure,
				boss_speed_pressure,
				boss_damage_pressure,
				boss_defense_pressure,
				boss_evasion_pressure,
				boss_accuracy_pressure
			)
			enemy.boss_kind = &"grand"
		&"apex_boss":
			_apply_boss_scaling(
				enemy,
				GameConstants.APEX_BOSS_HP_MULTIPLIER,
				GameConstants.APEX_BOSS_SPEED_MULTIPLIER,
				GameConstants.APEX_BOSS_DAMAGE_MULTIPLIER,
				GameConstants.APEX_BOSS_REWARD_ESSENCE_MULTIPLIER,
				boss_hp_pressure,
				boss_speed_pressure,
				boss_damage_pressure,
				boss_defense_pressure,
				boss_evasion_pressure,
				boss_accuracy_pressure
			)
			enemy.boss_kind = &"apex"
		_:
			enemy.set_normal_enemy_type(normal_enemy_type)
			enemy.boss_kind = &"none"

	return enemy.boss_kind

static func _apply_boss_scaling(
	enemy: Enemy,
	hp_multiplier: float,
	speed_multiplier: float,
	damage_multiplier: float,
	essence_multiplier: float,
	boss_hp_pressure: float,
	boss_speed_pressure: float,
	boss_damage_pressure: float,
	boss_defense_pressure: float,
	boss_evasion_pressure: float,
	boss_accuracy_pressure: float
) -> void:
	enemy.max_hp *= hp_multiplier * boss_hp_pressure
	enemy.speed *= speed_multiplier * boss_speed_pressure
	enemy.attack_damage *= damage_multiplier * boss_damage_pressure
	enemy.defense *= GameConstants.BOSS_DEFENSE_MULTIPLIER * boss_defense_pressure
	enemy.evasion = minf(GameConstants.ENEMY_MAX_EVASION, enemy.evasion * GameConstants.BOSS_EVASION_MULTIPLIER * boss_evasion_pressure)
	enemy.accuracy *= GameConstants.BOSS_ACCURACY_MULTIPLIER * boss_accuracy_pressure
	enemy.reward_essence = int(round(enemy.reward_essence * essence_multiplier))
	enemy.is_boss = true

static func _compute_wave_gold_reward(spawn_kind: StringName, reward_multiplier: float) -> int:
	var kind_multiplier: float = 1.0
	match spawn_kind:
		&"wave_boss":
			kind_multiplier = GameConstants.WAVE_BOSS_REWARD_GOLD_MULTIPLIER
		&"mini_boss":
			kind_multiplier = GameConstants.MINI_BOSS_REWARD_GOLD_MULTIPLIER
		&"grand_boss":
			kind_multiplier = GameConstants.GRAND_BOSS_REWARD_GOLD_MULTIPLIER
		&"apex_boss":
			kind_multiplier = GameConstants.APEX_BOSS_REWARD_GOLD_MULTIPLIER
		_:
			kind_multiplier = 1.0
	var raw: float = GameConstants.ENEMY_REWARD_GOLD * reward_multiplier * kind_multiplier
	return maxi(1, int(round(raw)))
