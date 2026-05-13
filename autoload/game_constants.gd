extends Node

const DEV_UNLOCK_ALL_SKILLS: bool = false

const HERO_BASE_DAMAGE: float = 10.0
const HERO_BASE_HP: float = 100.0
const HERO_BASE_ATTACK_SPEED: float = 1.0
const HERO_BASE_CRIT_CHANCE: float = 0.02
const HERO_BASE_CRIT_MULTIPLIER: float = 1.5
const HERO_MAX_CRIT_CHANCE: float = 0.85
const HERO_MAX_CRIT_MULTIPLIER: float = 8.0
const HERO_BASE_DEFENSE: float = 0.0
const HERO_BASE_EVASION: float = 8.0
const HERO_BASE_ACCURACY: float = 85.0
const HERO_MOVE_SPEED: float = 185.0
const HERO_FLEE_DISTANCE: float = 170.0
const HERO_PREFERRED_DISTANCE: float = 220.0
const HERO_ATTACK_RANGE: float = 460.0
const HERO_STRAFE_WEIGHT: float = 0.72
const HERO_FLEE_DIRECTION_LOCK_TIME: float = 0.28
const HERO_ORBIT_SWITCH_INTERVAL_MIN: float = 0.9
const HERO_ORBIT_SWITCH_INTERVAL_MAX: float = 1.8
const HERO_PROJECTILE_SPEED: float = 560.0

const ENEMY_BASE_HP: float = 30.0
const ENEMY_BASE_SPEED: float = 90.0
const ENEMY_BASE_DAMAGE: float = 6.0
const ENEMY_BASE_DEFENSE: float = 0.0
const ENEMY_BASE_EVASION: float = 4.0
const ENEMY_BASE_ACCURACY: float = 80.0
const ENEMY_MAX_EVASION: float = 160.0
const ENEMY_ATTACK_RANGE: float = 66.0
const ENEMY_ATTACK_COOLDOWN: float = 0.9
const ENEMY_REWARD_GOLD: int = 5
const ENEMY_REWARD_ESSENCE: int = 1
const WAVE_BOSS_HP_MULTIPLIER: float = 4.5
const WAVE_BOSS_SPEED_MULTIPLIER: float = 0.9
const WAVE_BOSS_DAMAGE_MULTIPLIER: float = 1.8
const WAVE_BOSS_REWARD_GOLD_MULTIPLIER: float = 3.5
const WAVE_BOSS_REWARD_ESSENCE_MULTIPLIER: float = 2.0
const MINI_BOSS_HP_MULTIPLIER: float = 8.0
const MINI_BOSS_SPEED_MULTIPLIER: float = 0.88
const MINI_BOSS_DAMAGE_MULTIPLIER: float = 2.6
const MINI_BOSS_REWARD_GOLD_MULTIPLIER: float = 7.0
const MINI_BOSS_REWARD_ESSENCE_MULTIPLIER: float = 4.0
const GRAND_BOSS_HP_MULTIPLIER: float = 13.0
const GRAND_BOSS_SPEED_MULTIPLIER: float = 0.92
const GRAND_BOSS_DAMAGE_MULTIPLIER: float = 3.8
const GRAND_BOSS_REWARD_GOLD_MULTIPLIER: float = 12.0
const GRAND_BOSS_REWARD_ESSENCE_MULTIPLIER: float = 7.0
const APEX_BOSS_HP_MULTIPLIER: float = 22.0
const APEX_BOSS_SPEED_MULTIPLIER: float = 1.05
const APEX_BOSS_DAMAGE_MULTIPLIER: float = 6.5
const APEX_BOSS_REWARD_GOLD_MULTIPLIER: float = 22.0
const APEX_BOSS_REWARD_ESSENCE_MULTIPLIER: float = 14.0

const SPAWN_INTERVAL: float = 0.75
const MAX_ACTIVE_ENEMIES: int = 5
const ACTIVE_ENEMY_WAVE_STEP: int = 5
const BASE_NORMAL_ENEMIES_PER_WAVE: int = 4
const WAVE_ENEMY_HP_SCALE: float = 1.24
const WAVE_ENEMY_SPEED_SCALE: float = 1.05
const WAVE_ENEMY_DAMAGE_SCALE: float = 1.16
const WAVE_ENEMY_DEFENSE_SCALE: float = 1.08
const WAVE_ENEMY_EVASION_SCALE: float = 1.03
const WAVE_ENEMY_ACCURACY_SCALE: float = 1.04
const WAVE_REWARD_SCALE: float = 1.12

# Unified infinite-mode rebalance curves.
const BALANCE_WAVE_EARLY_CAP: int = 120
const BALANCE_WAVE_MID_CAP: int = 1200

const BALANCE_WAVE_HP_EARLY: float = 1.032
const BALANCE_WAVE_HP_MID: float = 1.011
const BALANCE_WAVE_HP_LATE: float = 1.0035

const BALANCE_WAVE_SPEED_EARLY: float = 1.008
const BALANCE_WAVE_SPEED_MID: float = 1.0035
const BALANCE_WAVE_SPEED_LATE: float = 1.0012

const BALANCE_WAVE_DMG_EARLY: float = 1.026
const BALANCE_WAVE_DMG_MID: float = 1.0085
const BALANCE_WAVE_DMG_LATE: float = 1.003

const BALANCE_WAVE_DEF_EARLY: float = 1.012
const BALANCE_WAVE_DEF_MID: float = 1.005
const BALANCE_WAVE_DEF_LATE: float = 1.0018

const BALANCE_WAVE_EVA_EARLY: float = 1.009
const BALANCE_WAVE_EVA_MID: float = 1.004
const BALANCE_WAVE_EVA_LATE: float = 1.0015

const BALANCE_WAVE_ACC_EARLY: float = 1.009
const BALANCE_WAVE_ACC_MID: float = 1.004
const BALANCE_WAVE_ACC_LATE: float = 1.0015

const BALANCE_WAVE_REWARD_EARLY: float = 1.020
const BALANCE_WAVE_REWARD_MID: float = 1.010
const BALANCE_WAVE_REWARD_LATE: float = 1.004

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
		"step": 40.0,
		"bonuses": {
			"damage": 0.32,
			"max_hp": 2.0,
			"accuracy": 0.12,
		},
	},
	{
		"start": 4000,
		"step": 180.0,
		"bonuses": {
			"damage": 0.45,
			"max_hp": 1.3,
			"defense": 0.04,
			"attack_speed": 0.0005,
			"crit_chance": 0.00008,
		},
	},
	{
		"start": 40000,
		"step": 900.0,
		"bonuses": {
			"damage": 0.25,
			"max_hp": 3.2,
			"defense": 0.10,
			"evasion": 0.07,
			"crit_multiplier": 0.0004,
		},
	},
	{
		"start": 300000,
		"step": 4500.0,
		"bonuses": {
			"damage": 0.18,
			"max_hp": 2.2,
			"defense": 0.06,
			"evasion": 0.05,
			"crit_chance": 0.00003,
			"crit_multiplier": 0.0002,
		},
	},
]
const ECHO_REWARD_WAVE_EXPONENT: float = 0.55

const ARENA_CENTER: Vector2 = Vector2(360.0, 780.0)
const HERO_START_POSITION: Vector2 = Vector2(360.0, 780.0)
const ENEMY_SPAWN_RADIUS_X: float = 250.0
const ENEMY_SPAWN_RADIUS_Y: float = 320.0
const ARENA_MIN: Vector2 = Vector2(40.0, 250.0)
const ARENA_MAX: Vector2 = Vector2(680.0, 1230.0)

static func progressive_wave_multiplier(wave_offset: int, early_base: float, mid_base: float, late_base: float) -> float:
	var early_waves: int = mini(wave_offset, BALANCE_WAVE_EARLY_CAP)
	var mid_waves: int = mini(maxi(0, wave_offset - BALANCE_WAVE_EARLY_CAP), BALANCE_WAVE_MID_CAP - BALANCE_WAVE_EARLY_CAP)
	var late_waves: int = maxi(0, wave_offset - BALANCE_WAVE_MID_CAP)
	return pow(early_base, early_waves) * pow(mid_base, mid_waves) * pow(late_base, late_waves)
