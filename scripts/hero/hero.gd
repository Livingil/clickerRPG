extends Node2D
class_name Hero

signal attack_performed(target: Enemy, damage: float, is_crit: bool)

@onready var stats_component: HeroStatsComponent = $StatsComponent
@onready var attack_component: HeroAttackComponent = $AttackComponent
@onready var movement_component: Node = $MovementComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $HealthBar

var max_hp: float = GameConstants.HERO_BASE_HP
var hp: float = GameConstants.HERO_BASE_HP
var body_radius: float = 24.0

func _ready() -> void:
	global_position = GameConstants.HERO_START_POSITION
	stats_component.rebuild_from_game_state()
	attack_component.attack_performed.connect(_on_attack_performed)
	GameState.hero_stats_changed.connect(_on_hero_stats_changed)
	_refresh_health_bar()

func _physics_process(delta: float) -> void:
	movement_component.tick(delta)
	attack_component.tick(delta)

func set_battlefield(battlefield: Battlefield) -> void:
	attack_component.set_battlefield(battlefield)

func _on_attack_performed(target: Enemy, damage: float, is_crit: bool) -> void:
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
	attack_performed.emit(target, damage, is_crit)
	SignalBus.hero_attack_performed.emit(target, damage, is_crit)

func _on_hero_stats_changed() -> void:
	stats_component.rebuild_from_game_state()

func _refresh_health_bar() -> void:
	health_bar.max_value = max_hp
	health_bar.value = hp

func clamp_to_arena() -> void:
	global_position = Vector2(
		clampf(global_position.x, GameConstants.ARENA_MIN.x + body_radius, GameConstants.ARENA_MAX.x - body_radius),
		clampf(global_position.y, GameConstants.ARENA_MIN.y + body_radius, GameConstants.ARENA_MAX.y - body_radius)
	)
