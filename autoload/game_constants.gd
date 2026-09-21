extends Node

const DEV_UNLOCK_ALL_SKILLS: bool = false

const HERO_BASE_DAMAGE: float = 10.0
const HERO_BASE_HP: float = 100.0
const HERO_BASE_ATTACK_SPEED: float = 1.0
const HERO_ATTACK_SPEED_SOFT_CAP: float = 3.0
const HERO_ATTACK_SPEED_HARD_CAP: float = 4.0
const HERO_BASE_CRIT_CHANCE: float = 0.0
const HERO_BASE_CRIT_MULTIPLIER: float = 1.5
const HERO_MAX_CRIT_CHANCE: float = 0.75
const HERO_MAX_CRIT_MULTIPLIER: float = 6.0
const HERO_BASE_DEFENSE: float = 0.0
const HERO_BASE_EVASION: float = 8.0
const HERO_BASE_ACCURACY: float = 85.0
const HERO_MOVE_SPEED: float = 120.0
const HERO_MAX_MOVE_SPEED: float = 220.0
const HERO_BOOTS_MOVE_SPEED_PER_100: float = 5.0
const HERO_FLEE_DISTANCE: float = 170.0
const HERO_PREFERRED_DISTANCE: float = 240.0
const HERO_ATTACK_RANGE: float = 420.0
const HERO_STRAFE_WEIGHT: float = 0.72
const HERO_FLEE_DIRECTION_LOCK_TIME: float = 0.28
const HERO_ORBIT_SWITCH_INTERVAL_MIN: float = 0.9
const HERO_ORBIT_SWITCH_INTERVAL_MAX: float = 1.8
const HERO_PROJECTILE_SPEED: float = 560.0

const ENEMY_BASE_HP: float = 30.0
const ENEMY_BASE_SPEED: float = 90.0
const ENEMY_BASE_DAMAGE: float = 2.6
const ENEMY_BASE_DEFENSE: float = 3.0
const ENEMY_BASE_EVASION: float = 4.0
const ENEMY_BASE_ACCURACY: float = 80.0
const ENEMY_MAX_EVASION: float = 160.0
const ENEMY_ATTACK_RANGE: float = 66.0
const ENEMY_ATTACK_COOLDOWN: float = 0.9
const ENEMY_REWARD_GOLD: int = 5
const ENEMY_REWARD_ESSENCE: int = 1
const ENEMY_TYPE_BASIC: StringName = &"basic"
const ENEMY_TYPE_TANK: StringName = &"tank"
const ENEMY_TYPE_FAST: StringName = &"fast"
const ENEMY_TYPE_RANGED: StringName = &"ranged"
const ENEMY_TANK_DEFENSE_MULTIPLIER: float = 3.0
const ENEMY_MONO_WAVE_CHANCE: float = 0.10
const ENEMY_TANK_UNLOCK_WAVE: int = 10
const ENEMY_FAST_UNLOCK_WAVE: int = 30
const ENEMY_RANGED_UNLOCK_WAVE: int = 50
const ENEMY_RANGED_PREFERRED_DISTANCE: float = 240.0
const ENEMY_PROJECTILE_SPEED: float = 390.0
const ENEMY_PROJECTILE_HIT_RADIUS: float = 18.0
const ENEMY_PROJECTILE_MAX_LIFETIME: float = 2.25
const ENEMY_PRESSURE_START_WAVE: int = 50
const ENEMY_POST_PRESTIGE_HP_PRESSURE_PER_WAVE: float = 0.006
const ENEMY_POST_PRESTIGE_DAMAGE_PRESSURE_PER_WAVE: float = 0.004
const ENEMY_POST_PRESTIGE_DEFENSE_PRESSURE_PER_WAVE: float = 0.004
const ENEMY_POST_PRESTIGE_SPEED_PRESSURE_PER_WAVE: float = 0.0015
const ENEMY_POST_PRESTIGE_EVASION_PRESSURE_PER_WAVE: float = 0.0025
const ENEMY_POST_PRESTIGE_ACCURACY_PRESSURE_PER_WAVE: float = 0.0025
const BOSS_POST_PRESTIGE_HP_PRESSURE_PER_WAVE: float = 0.060
const BOSS_POST_PRESTIGE_DAMAGE_PRESSURE_PER_WAVE: float = 0.010
const BOSS_POST_PRESTIGE_DEFENSE_PRESSURE_PER_WAVE: float = 0.020
const BOSS_POST_PRESTIGE_SPEED_PRESSURE_PER_WAVE: float = 0.003
const BOSS_POST_PRESTIGE_EVASION_PRESSURE_PER_WAVE: float = 0.005
const BOSS_POST_PRESTIGE_ACCURACY_PRESSURE_PER_WAVE: float = 0.005
const WAVE_BOSS_HP_MULTIPLIER: float = 5.6
const WAVE_BOSS_SPEED_MULTIPLIER: float = 1.04
const WAVE_BOSS_DAMAGE_MULTIPLIER: float = 1.13
const WAVE_BOSS_REWARD_GOLD_MULTIPLIER: float = 3.5
const WAVE_BOSS_REWARD_ESSENCE_MULTIPLIER: float = 2.0
const MINI_BOSS_HP_MULTIPLIER: float = 12.8
const MINI_BOSS_SPEED_MULTIPLIER: float = 1.01
const MINI_BOSS_DAMAGE_MULTIPLIER: float = 2.56
const MINI_BOSS_REWARD_GOLD_MULTIPLIER: float = 7.0
const MINI_BOSS_REWARD_ESSENCE_MULTIPLIER: float = 4.0
const GRAND_BOSS_HP_MULTIPLIER: float = 30.4
const GRAND_BOSS_SPEED_MULTIPLIER: float = 1.06
const GRAND_BOSS_DAMAGE_MULTIPLIER: float = 5.40
const GRAND_BOSS_REWARD_GOLD_MULTIPLIER: float = 12.0
const GRAND_BOSS_REWARD_ESSENCE_MULTIPLIER: float = 7.0
const APEX_BOSS_HP_MULTIPLIER: float = 35.2
const APEX_BOSS_SPEED_MULTIPLIER: float = 1.21
const APEX_BOSS_DAMAGE_MULTIPLIER: float = 6.32
const APEX_BOSS_REWARD_GOLD_MULTIPLIER: float = 22.0
const APEX_BOSS_REWARD_ESSENCE_MULTIPLIER: float = 14.0
const BOSS_DEFENSE_MULTIPLIER: float = 1.5
const BOSS_EVASION_MULTIPLIER: float = 1.1
const BOSS_ACCURACY_MULTIPLIER: float = 1.2

const SPAWN_INTERVAL: float = 0.75
const MAX_ACTIVE_ENEMIES: int = 5
const ACTIVE_ENEMY_WAVE_STEP: int = 10
const BASE_NORMAL_ENEMIES_PER_WAVE: int = 4
const NORMAL_ENEMY_WAVE_GROWTH: float = 0.58

# Unified infinite-mode rebalance curves.
const BALANCE_WAVE_EARLY_CAP: int = 120
const BALANCE_WAVE_MID_CAP: int = 1200

const BALANCE_WAVE_HP_EARLY: float = 1.010
const BALANCE_WAVE_HP_MID: float = 1.018
const BALANCE_WAVE_HP_LATE: float = 1.008

const BALANCE_WAVE_SPEED_EARLY: float = 1.003
const BALANCE_WAVE_SPEED_MID: float = 1.0035
const BALANCE_WAVE_SPEED_LATE: float = 1.0012

const BALANCE_WAVE_DMG_EARLY: float = 1.006
const BALANCE_WAVE_DMG_MID: float = 1.012
const BALANCE_WAVE_DMG_LATE: float = 1.006

const BALANCE_WAVE_DEF_EARLY: float = 1.008
const BALANCE_WAVE_DEF_MID: float = 1.005
const BALANCE_WAVE_DEF_LATE: float = 1.0018

const BALANCE_WAVE_EVA_EARLY: float = 1.004
const BALANCE_WAVE_EVA_MID: float = 1.004
const BALANCE_WAVE_EVA_LATE: float = 1.0015

const BALANCE_WAVE_ACC_EARLY: float = 1.004
const BALANCE_WAVE_ACC_MID: float = 1.004
const BALANCE_WAVE_ACC_LATE: float = 1.0015

const BALANCE_WAVE_REWARD_EARLY: float = 1.020
const BALANCE_WAVE_REWARD_MID: float = 1.008
const BALANCE_WAVE_REWARD_LATE: float = 1.002

const BALANCE_COST_PHASE1_CAP: int = 250
const BALANCE_COST_PHASE2_CAP: int = 1400
const BALANCE_COST_PHASE1_RATE: float = 1.040
const BALANCE_COST_PHASE2_RATE: float = 1.015
const BALANCE_COST_PHASE3_RATE: float = 1.0065

# Echo progression tiers (data-driven).
# Each tier applies for echo values >= start, with step cost per bonus tick.
const ECHO_TIERS: Array[Dictionary] = [
	{
		"start": 0,
		"step": 30.0,
		"bonuses": {
			"damage": 0.36,
			"max_hp": 2.4,
			"accuracy": 0.12,
		},
	},
	{
		"start": 4000,
		"step": 180.0,
		"bonuses": {
			"damage": 0.34,
			"max_hp": 1.2,
			"defense": 0.03,
			"attack_speed": 0.00025,
			"crit_chance": 0.00004,
		},
	},
	{
		"start": 40000,
		"step": 1400.0,
		"bonuses": {
			"damage": 0.14,
			"max_hp": 2.0,
			"defense": 0.05,
			"evasion": 0.035,
			"crit_multiplier": 0.00018,
		},
	},
	{
		"start": 300000,
		"step": 9000.0,
		"bonuses": {
			"damage": 0.06,
			"max_hp": 1.0,
			"defense": 0.02,
			"evasion": 0.016,
			"crit_chance": 0.00001,
			"crit_multiplier": 0.00006,
		},
	},
]
const ECHO_REWARD_WAVE_EXPONENT: float = 0.47

const UI_HEADER_HEIGHT: float = 100.0
const UI_FOOTER_HEIGHT: float = 68.0
const VIEWPORT_WIDTH: float = 720.0
const VIEWPORT_HEIGHT: float = 1280.0
const ARENA_MIN: Vector2 = Vector2(0.0, UI_HEADER_HEIGHT)
const ARENA_MAX: Vector2 = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT - UI_FOOTER_HEIGHT)
const ARENA_CENTER: Vector2 = (ARENA_MIN + ARENA_MAX) * 0.5
const HERO_START_POSITION: Vector2 = ARENA_CENTER
const ENEMY_SPAWN_RADIUS_X: float = 250.0
const ENEMY_SPAWN_RADIUS_Y: float = 320.0

func progressive_wave_multiplier(wave_offset: int, early_base: float, mid_base: float, late_base: float) -> float:
	var early_waves: int = min(wave_offset, BALANCE_WAVE_EARLY_CAP)
	var mid_waves: int = min(max(0, wave_offset - BALANCE_WAVE_EARLY_CAP), BALANCE_WAVE_MID_CAP - BALANCE_WAVE_EARLY_CAP)
	var late_waves: int = max(0, wave_offset - BALANCE_WAVE_MID_CAP)
	return pow(early_base, early_waves) * pow(mid_base, mid_waves) * pow(late_base, late_waves)

func normal_enemy_count_for_wave(wave: int) -> int:
	return BASE_NORMAL_ENEMIES_PER_WAVE + int(floor(float(maxi(0, wave - 1)) * NORMAL_ENEMY_WAVE_GROWTH))

func post_prestige_pressure_multiplier(wave: int, per_wave: float) -> float:
	return 1.0 + float(maxi(0, wave - ENEMY_PRESSURE_START_WAVE)) * per_wave

func enemy_post_prestige_hp_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, ENEMY_POST_PRESTIGE_HP_PRESSURE_PER_WAVE)

func enemy_post_prestige_damage_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, ENEMY_POST_PRESTIGE_DAMAGE_PRESSURE_PER_WAVE)

func enemy_post_prestige_defense_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, ENEMY_POST_PRESTIGE_DEFENSE_PRESSURE_PER_WAVE)

func enemy_post_prestige_speed_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, ENEMY_POST_PRESTIGE_SPEED_PRESSURE_PER_WAVE)

func enemy_post_prestige_evasion_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, ENEMY_POST_PRESTIGE_EVASION_PRESSURE_PER_WAVE)

func enemy_post_prestige_accuracy_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, ENEMY_POST_PRESTIGE_ACCURACY_PRESSURE_PER_WAVE)

func boss_post_prestige_hp_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, BOSS_POST_PRESTIGE_HP_PRESSURE_PER_WAVE)

func boss_post_prestige_damage_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, BOSS_POST_PRESTIGE_DAMAGE_PRESSURE_PER_WAVE)

func boss_post_prestige_defense_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, BOSS_POST_PRESTIGE_DEFENSE_PRESSURE_PER_WAVE)

func boss_post_prestige_speed_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, BOSS_POST_PRESTIGE_SPEED_PRESSURE_PER_WAVE)

func boss_post_prestige_evasion_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, BOSS_POST_PRESTIGE_EVASION_PRESSURE_PER_WAVE)

func boss_post_prestige_accuracy_pressure_multiplier(wave: int) -> float:
	return post_prestige_pressure_multiplier(wave, BOSS_POST_PRESTIGE_ACCURACY_PRESSURE_PER_WAVE)
