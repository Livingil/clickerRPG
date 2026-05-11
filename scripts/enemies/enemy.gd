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

var hp: float = 0.0
var attack_cooldown_left: float = 0.0

var hero_target: Hero

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	attack_cooldown_left = randf_range(0.05, attack_cooldown)
	_setup_boss_tag()
	_refresh_health_bar()
	SignalBus.enemy_spawned.emit(self)

func _physics_process(delta: float) -> void:
	movement_component.move_towards_target(hero_target, delta)
	_tick_attack(delta)

func set_target(hero: Hero) -> void:
	hero_target = hero

func take_damage(amount: float) -> void:
	hp -= amount
	_play_hit_feedback()
	_refresh_health_bar()
	if hp <= 0.0:
		die()

func die() -> void:
	_spawn_death_burst()
	GameState.add_gold(reward_gold)
	GameState.add_essence(reward_essence)
	GameState.add_echo(GameState.get_echo_gain_for_enemy(boss_kind))
	SignalBus.enemy_killed.emit(self)
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
