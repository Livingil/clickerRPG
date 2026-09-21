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
	var clone_scale := GameState.get_clone_attack_multiplier()
	if clone_scale > 0.0:
		_perform_attack(target, clone_scale)
	if GameState.should_trigger_repeat_action():
		_perform_attack(target)
	attack_cooldown = 1.0 / maxf(0.05, stats_component.get_attack_speed() * GameState.get_runtime_attack_speed_multiplier())

func set_battlefield(value: Battlefield) -> void:
	battlefield = value

func _perform_attack(target: Enemy, extra_scale: float = 0.0) -> void:
	var result := await _resolve_hero_attack(target, extra_scale)
	var damage := float(result.get("schoolDamage", 0.0))
	var is_crit := bool(result.get("isCrit", false))
	_spawn_projectile(target, result)
	attack_performed.emit(target, damage, is_crit)

func _find_target() -> Enemy:
	var enemies := get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy_in_range(
		hero.global_position,
		enemies,
		GameConstants.HERO_ATTACK_RANGE
	) as Enemy

func _spawn_projectile(target: Enemy, attack_result: Dictionary) -> void:
	var is_crit := bool(attack_result.get("isCrit", false))
	if battlefield == null or projectile_scene == null:
		var hit := target.receive_resolved_school_hit(attack_result, GameState.active_school, stats_component.get_accuracy())
		if hit:
			GameState.add_active_school_mastery_xp(1)
		return

	var projectile := projectile_scene.instantiate() as MagicProjectile
	if projectile == null:
		var hit := target.receive_resolved_school_hit(attack_result, GameState.active_school, stats_component.get_accuracy())
		if hit:
			GameState.add_active_school_mastery_xp(1)
		return

	projectile.global_position = attack_point.global_position
	projectile.setup(target, attack_result, GameState.active_school, stats_component.get_accuracy())
	battlefield.projectile_container.add_child(projectile)

func _resolve_hero_attack(target: Enemy, extra_scale: float) -> Dictionary:
	return await CombatResolver.resolve_hero_attack(stats_component, target, GameState.active_school, extra_scale)
