extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

@export var max_hp: float = GameConstants.ENEMY_BASE_HP
@export var speed: float = GameConstants.ENEMY_BASE_SPEED
@export var reward_gold: int = GameConstants.ENEMY_REWARD_GOLD
@export var reward_essence: int = GameConstants.ENEMY_REWARD_ESSENCE
@export var body_radius: float = 18.0
@export var is_boss: bool = false

@onready var movement_component: EnemyMovementComponent = $MovementComponent
@onready var health_bar: ProgressBar = $HealthBar

var hp: float = 0.0

var hero_target: Hero

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	_refresh_health_bar()
	SignalBus.enemy_spawned.emit(self)

func _physics_process(delta: float) -> void:
	movement_component.move_towards_target(hero_target, delta)

func set_target(hero: Hero) -> void:
	hero_target = hero

func take_damage(amount: float) -> void:
	hp -= amount
	_refresh_health_bar()
	if hp <= 0.0:
		die()

func die() -> void:
	GameState.add_gold(reward_gold)
	GameState.add_essence(reward_essence)
	SignalBus.enemy_killed.emit(self)
	died.emit(self)
	queue_free()

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
