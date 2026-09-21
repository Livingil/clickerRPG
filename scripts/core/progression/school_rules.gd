extends RefCounted
class_name SchoolRules

const SLOT_WAVE_UNLOCKS: Array[int] = [0, 5, 10, 40]
const MASTERY_UNLOCK_LEVELS: Array[int] = [1, 3, 5]
const CORE_MASTERY_XP_THRESHOLDS: Array[int] = [20, 200, 1000, 3000, 7000, 15000, 30000, 60000, 120000, 240000]
const POST_10_XP_PER_LEVEL: int = 120000
const VULNERABILITY_STACK_BONUS: float = 0.04
const VULNERABILITY_MAX_STACKS: int = 5
const VULNERABILITY_DURATION: float = 4.0
const WATER_CHILL_MOVE_SLOW_PER_STACK: float = 0.045
const WATER_CHILL_ATTACK_SLOW_PER_STACK: float = 0.025
const WATER_FREEZE_DURATION: float = 0.55
const WATER_BOSS_FREEZE_MULTIPLIER: float = 0.45
const WATER_FREEZE_INTERNAL_COOLDOWN: float = 5.5
const EARTH_DEFENSE_BREAK_PER_STACK: float = 0.04
const EARTH_DEFENSE_BREAK_BOSS_MULTIPLIER: float = 0.60
const EARTH_QUAKE_KNOCKBACK: float = 72.0
const EARTH_BASTION_DEFENSE_BONUS: float = 0.25
const EARTH_BASTION_DURATION: float = 4.0
const AIR_ACCURACY_BREAK_PER_STACK: float = 0.055
const AIR_ACCURACY_BREAK_BOSS_MULTIPLIER: float = 0.60
const AIR_GUST_KNOCKBACK: float = 82.0
const AIR_CYCLONE_PULL: float = 58.0
const AIR_FLURRY_KNOCKBACK: float = 46.0
const AIR_ATTACK_DELAY_ON_CONTROL: float = 0.22
const AIR_ATTACK_DELAY_BOSS_MULTIPLIER: float = 0.40
const LIGHTNING_DAMAGE_PER_STACK: float = 0.03
const LIGHTNING_DISCHARGE_STACKS: int = 5
const LIGHTNING_DISCHARGE_DAMAGE_RATIO: float = 0.80
const LIGHTNING_DISCHARGE_CHAIN_RATIO: float = 0.45
const LIGHTNING_DISCHARGE_CHAIN_RANGE: float = 260.0
const LIGHTNING_DISCHARGE_INTERNAL_COOLDOWN: float = 0.35

const SCHOOL_FIRE: StringName = &"fire"
const SCHOOL_WATER: StringName = &"water"
const SCHOOL_EARTH: StringName = &"earth"
const SCHOOL_AIR: StringName = &"air"
const SCHOOL_LIGHTNING: StringName = &"lightning"

const SCHOOL_ORDER: Array[StringName] = [
	SCHOOL_FIRE,
	SCHOOL_WATER,
	SCHOOL_EARTH,
	SCHOOL_AIR,
	SCHOOL_LIGHTNING,
]

const SCHOOL_DEFINITIONS := {
	SCHOOL_FIRE: {
		"name": "Fire",
		"core_label": "Burning Staff",
		"element": "fire",
		"skills": [&"ember_chain", &"cinder_burst", &"ash_storm"],
		"mastery_bonus_text": "Post-10: burn potency",
	},
	SCHOOL_WATER: {
		"name": "Water",
		"core_label": "Tide Staff",
		"element": "water",
		"skills": [&"frost_orb", &"tidal_pulse", &"glacial_field"],
		"mastery_bonus_text": "Post-10: chill potency",
	},
	SCHOOL_EARTH: {
		"name": "Earth",
		"core_label": "Stone Staff",
		"element": "earth",
		"skills": [&"stone_spike", &"quake_ring", &"bastion_crash"],
		"mastery_bonus_text": "Post-10: armor break",
	},
	SCHOOL_AIR: {
		"name": "Air",
		"core_label": "Gale Staff",
		"element": "air",
		"skills": [&"razor_gust", &"cyclone_arc", &"sky_flurry"],
		"mastery_bonus_text": "Post-10: air tempo",
	},
	SCHOOL_LIGHTNING: {
		"name": "Lightning",
		"core_label": "Volt Staff",
		"element": "lightning",
		"skills": [&"spark_jump", &"volt_lance", &"thunder_crown"],
		"mastery_bonus_text": "Post-10: chain burst",
	},
}

const SKILL_DEFINITIONS := {
	&"ember_chain": {"name": "Ember Mark", "school": SCHOOL_FIRE, "unlock_level": 1, "icon": "res://assets/ui/skill_icons/ember_chain.svg"},
	&"cinder_burst": {"name": "Cinder Burst", "school": SCHOOL_FIRE, "unlock_level": 3, "icon": "res://assets/ui/skill_icons/cinder_burst.svg"},
	&"ash_storm": {"name": "Ash Storm", "school": SCHOOL_FIRE, "unlock_level": 5, "icon": "res://assets/ui/skill_icons/ash_storm.svg"},
	&"frost_orb": {"name": "Frost Orb", "school": SCHOOL_WATER, "unlock_level": 1, "icon": "res://assets/ui/skill_icons/frost_orb.svg"},
	&"tidal_pulse": {"name": "Tidal Pulse", "school": SCHOOL_WATER, "unlock_level": 3, "icon": "res://assets/ui/skill_icons/tidal_pulse.svg"},
	&"glacial_field": {"name": "Blizzard", "school": SCHOOL_WATER, "unlock_level": 5, "icon": "res://assets/ui/skill_icons/glacial_field.svg"},
	&"stone_spike": {"name": "Stone Spike", "school": SCHOOL_EARTH, "unlock_level": 1, "icon": "res://assets/ui/skill_icons/stone_spike.svg"},
	&"quake_ring": {"name": "Quake Ring", "school": SCHOOL_EARTH, "unlock_level": 3, "icon": "res://assets/ui/skill_icons/quake_ring.svg"},
	&"bastion_crash": {"name": "Bastion Crash", "school": SCHOOL_EARTH, "unlock_level": 5, "icon": "res://assets/ui/skill_icons/bastion_crash.svg"},
	&"razor_gust": {"name": "Razor Gust", "school": SCHOOL_AIR, "unlock_level": 1, "icon": "res://assets/ui/skill_icons/razor_gust.svg"},
	&"cyclone_arc": {"name": "Cyclone Arc", "school": SCHOOL_AIR, "unlock_level": 3, "icon": "res://assets/ui/skill_icons/cyclone_arc.svg"},
	&"sky_flurry": {"name": "Sky Flurry", "school": SCHOOL_AIR, "unlock_level": 5, "icon": "res://assets/ui/skill_icons/sky_flurry.svg"},
	&"spark_jump": {"name": "Spark Jump", "school": SCHOOL_LIGHTNING, "unlock_level": 1, "icon": "res://assets/ui/skill_icons/spark_jump.svg"},
	&"volt_lance": {"name": "Volt Lance", "school": SCHOOL_LIGHTNING, "unlock_level": 3, "icon": "res://assets/ui/skill_icons/volt_lance.svg"},
	&"thunder_crown": {"name": "Thunder Crown", "school": SCHOOL_LIGHTNING, "unlock_level": 5, "icon": "res://assets/ui/skill_icons/thunder_crown.svg"},
}

static func get_core_mastery_level_from_xp(xp: int) -> int:
	var level := 0
	for threshold in CORE_MASTERY_XP_THRESHOLDS:
		if xp >= threshold:
			level += 1
	return min(level, 10)

static func get_total_mastery_level_from_xp(xp: int) -> int:
	var core_level := get_core_mastery_level_from_xp(xp)
	if core_level < 10:
		return core_level

	var post_cap_xp := xp - CORE_MASTERY_XP_THRESHOLDS[CORE_MASTERY_XP_THRESHOLDS.size() - 1]
	return 10 + int(floor(post_cap_xp / float(POST_10_XP_PER_LEVEL)))

static func get_next_level_xp(level: int) -> int:
	if level < 0:
		return CORE_MASTERY_XP_THRESHOLDS[0]
	if level < CORE_MASTERY_XP_THRESHOLDS.size():
		return CORE_MASTERY_XP_THRESHOLDS[level]
	return CORE_MASTERY_XP_THRESHOLDS[CORE_MASTERY_XP_THRESHOLDS.size() - 1] + ((level - 9) * POST_10_XP_PER_LEVEL)

static func get_current_level_floor_xp(level: int) -> int:
	if level <= 0:
		return 0
	if level - 1 < CORE_MASTERY_XP_THRESHOLDS.size():
		return CORE_MASTERY_XP_THRESHOLDS[level - 1]
	return CORE_MASTERY_XP_THRESHOLDS[CORE_MASTERY_XP_THRESHOLDS.size() - 1] + ((level - 10) * POST_10_XP_PER_LEVEL)

static func get_skill_slot_count_for_highest_wave(highest_wave: int) -> int:
	var unlocked := 0
	for wave_requirement in SLOT_WAVE_UNLOCKS:
		if highest_wave >= wave_requirement:
			unlocked += 1
	return unlocked
