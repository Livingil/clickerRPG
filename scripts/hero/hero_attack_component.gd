extends Node
class_name HeroAttackComponent

signal attack_performed(target: Enemy, damage: float, is_crit: bool)

@onready var hero: Hero = owner as Hero
@onready var stats_component: HeroStatsComponent = $"../StatsComponent"
@onready var attack_point: Marker2D = $"../AttackPoint"

var battlefield: Battlefield
var projectile_scene: PackedScene = preload("res://scenes/effects/projectile_magic.tscn")
var attack_cooldown: float = 0.0

func _ready() -> void:
	attack_cooldown = 0.0

func tick(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if attack_cooldown > 0.0:
		return

	var target := _find_target()
	if target == null:
		return

	_perform_attack(target)
	attack_cooldown = 1.0 / maxf(0.05, stats_component.get_attack_speed())

func set_battlefield(value: Battlefield) -> void:
	battlefield = value

func _perform_attack(target: Enemy) -> void:
	var is_crit := randf() < stats_component.get_crit_chance()
	var damage := stats_component.get_damage()
	if is_crit:
		damage *= stats_component.get_crit_multiplier()

	_spawn_projectile(target, damage, is_crit)
	attack_performed.emit(target, damage, is_crit)

func _find_target() -> Enemy:
	var enemies := get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(
		hero.global_position,
		enemies,
		GameConstants.HERO_ATTACK_RANGE
	) as Enemy

func _spawn_projectile(target: Enemy, damage: float, is_crit: bool) -> void:
	if battlefield == null or projectile_scene == null:
		target.take_damage(damage)
		return

	var projectile := projectile_scene.instantiate() as MagicProjectile
	if projectile == null:
		target.take_school_damage(damage, GameState.active_school)
		return

	projectile.global_position = attack_point.global_position
	projectile.setup(target, damage, is_crit, GameState.active_school)
	battlefield.projectile_container.add_child(projectile)
