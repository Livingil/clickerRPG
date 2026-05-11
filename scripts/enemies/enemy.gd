extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

const DEFAULT_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const HIT_FLASH_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DeathBurstScene = preload("res://scenes/effects/death_burst.tscn")

@export var max_hp: float = GameConstants.ENEMY_BASE_HP
@export var speed: float = GameConstants.ENEMY_BASE_SPEED
@export var attack_damage: float = GameConstants.ENEMY_BASE_DAMAGE
@export var attack_range: float = GameConstants.ENEMY_ATTACK_RANGE
@export var attack_cooldown: float = GameConstants.ENEMY_ATTACK_COOLDOWN
@export var reward_gold: int = GameConstants.ENEMY_REWARD_GOLD
@export var reward_essence: int = GameConstants.ENEMY_REWARD_ESSENCE
@export var body_radius: float = 18.0
@export var is_boss: bool = false
@export var boss_kind: StringName = &"none"

@onready var movement_component: EnemyMovementComponent = $MovementComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var body: Polygon2D = $Body
@onready var boss_tag: Label = $BossTag
@onready var vulnerability_label: Label = $VulnerabilityLabel

var hp: float = 0.0
var attack_cooldown_left: float = 0.0
var vulnerability_stacks: Dictionary = {}
var vulnerability_timers: Dictionary = {}

var hero_target: Hero

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	attack_cooldown_left = randf_range(0.05, attack_cooldown)
	_setup_boss_tag()
	_refresh_health_bar()
	SignalBus.emit_enemy_spawned(self)

func _physics_process(delta: float) -> void:
	movement_component.move_towards_target(hero_target, delta)
	_tick_attack(delta)
	_tick_vulnerabilities(delta)

func set_target(hero: Hero) -> void:
	hero_target = hero

func take_damage(amount: float) -> void:
	hp -= amount
	_play_hit_feedback()
	_refresh_health_bar()
	if hp <= 0.0:
		die()

func take_school_damage(amount: float, school_id: StringName) -> void:
	var school_damage := amount * get_vulnerability_multiplier(school_id)
	take_damage(school_damage)
	apply_vulnerability_stack(school_id)

func die() -> void:
	_spawn_death_burst()
	GameState.add_gold(reward_gold)
	GameState.add_essence(reward_essence)
	GameState.add_echo(GameState.get_echo_gain_for_enemy(boss_kind))
	GameState.add_active_school_mastery_xp(GameState.get_mastery_xp_for_enemy(boss_kind))
	SignalBus.emit_enemy_killed(self)
	died.emit(self)
	queue_free()

func _tick_attack(delta: float) -> void:
	if hero_target == null:
		return
	if hero_target.hp <= 0.0:
		return

	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	var distance := global_position.distance_to(hero_target.global_position)
	if distance > attack_range:
		return
	if attack_cooldown_left > 0.0:
		return

	hero_target.take_damage(attack_damage)
	attack_cooldown_left = attack_cooldown

func clamp_to_arena() -> void:
	global_position = Vector2(
		clampf(global_position.x, GameConstants.ARENA_MIN.x + body_radius, GameConstants.ARENA_MAX.x - body_radius),
		clampf(global_position.y, GameConstants.ARENA_MIN.y + body_radius, GameConstants.ARENA_MAX.y - body_radius)
	)

func get_chase_position() -> Vector2:
	if hero_target == null:
		return global_position
	return Vector2(
		clampf(hero_target.global_position.x, GameConstants.ARENA_MIN.x + body_radius, GameConstants.ARENA_MAX.x - body_radius),
		clampf(hero_target.global_position.y, GameConstants.ARENA_MIN.y + body_radius, GameConstants.ARENA_MAX.y - body_radius)
	)

func _refresh_health_bar() -> void:
	health_bar.max_value = max_hp
	health_bar.value = maxf(0.0, hp)
	_refresh_vulnerability_label()

func apply_vulnerability_stack(school_id: StringName) -> void:
	var current := int(vulnerability_stacks.get(school_id, 0))
	vulnerability_stacks[school_id] = min(current + 1, SchoolRules.VULNERABILITY_MAX_STACKS)
	vulnerability_timers[school_id] = SchoolRules.VULNERABILITY_DURATION
	_refresh_vulnerability_label()

func get_vulnerability_multiplier(school_id: StringName) -> float:
	var stacks := int(vulnerability_stacks.get(school_id, 0))
	return 1.0 + stacks * SchoolRules.VULNERABILITY_STACK_BONUS

func _tick_vulnerabilities(delta: float) -> void:
	if vulnerability_timers.is_empty():
		return

	var expired: Array[StringName] = []
	for school_id_variant in vulnerability_timers.keys():
		var school_id := school_id_variant as StringName
		var time_left := float(vulnerability_timers[school_id]) - delta
		if time_left <= 0.0:
			expired.append(school_id)
		else:
			vulnerability_timers[school_id] = time_left

	for school_id in expired:
		vulnerability_timers.erase(school_id)
		vulnerability_stacks.erase(school_id)

	if expired.size() > 0:
		_refresh_vulnerability_label()

func _refresh_vulnerability_label() -> void:
	var best_school := _get_strongest_vulnerability_school()
	if best_school == &"":
		vulnerability_label.visible = false
		return

	var stacks := int(vulnerability_stacks.get(best_school, 0))
	var element_name := String(SchoolRules.SCHOOL_DEFINITIONS.get(best_school, {}).get("name", ""))
	vulnerability_label.visible = true
	vulnerability_label.text = "%s x%d" % [element_name, stacks]

func _get_strongest_vulnerability_school() -> StringName:
	var best_school: StringName = &""
	var best_stacks := 0
	for school_id_variant in vulnerability_stacks.keys():
		var school_id := school_id_variant as StringName
		var stacks := int(vulnerability_stacks[school_id])
		if stacks > best_stacks:
			best_stacks = stacks
			best_school = school_id
	return best_school

func _setup_boss_tag() -> void:
	match boss_kind:
		&"wave":
			boss_tag.visible = true
			boss_tag.text = "BOSS"
			boss_tag.modulate = Color(0.64, 1.0, 0.72, 1.0)
		&"mini":
			boss_tag.visible = true
			boss_tag.text = "MINI"
			boss_tag.modulate = Color(1.0, 0.92, 0.42, 1.0)
		&"grand":
			boss_tag.visible = true
			boss_tag.text = "GRAND"
			boss_tag.modulate = Color(1.0, 0.45, 0.45, 1.0)
		_:
			boss_tag.visible = false

func _play_hit_feedback() -> void:
	body.modulate = HIT_FLASH_COLOR
	body.scale = Vector2(1.08, 1.08)

	var tween := create_tween()
	tween.tween_property(body, "modulate", DEFAULT_MODULATE, 0.08)
	tween.parallel().tween_property(body, "scale", Vector2.ONE, 0.08)

func _spawn_death_burst() -> void:
	if DeathBurstScene == null or get_parent() == null:
		return

	var burst := DeathBurstScene.instantiate() as Node2D
	if burst == null:
		return

	burst.global_position = global_position
	if burst.has_method("setup"):
		burst.call("setup", body.color, body_radius)
	get_parent().add_child(burst)
