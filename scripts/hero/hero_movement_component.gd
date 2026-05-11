extends Node
class_name HeroMovementComponent

const TargetSelector = preload("res://scripts/gameplay/target_selector.gd")

@export var move_speed: float = GameConstants.HERO_MOVE_SPEED
@export var flee_distance: float = GameConstants.HERO_FLEE_DISTANCE
@export var preferred_distance: float = GameConstants.HERO_PREFERRED_DISTANCE
@export var strafe_weight: float = GameConstants.HERO_STRAFE_WEIGHT

@onready var hero: Node2D = owner as Node2D

func tick(delta: float) -> void:
	var closest_enemy := _find_closest_enemy()
	if closest_enemy == null:
		_return_to_center(delta)
		return

	var offset := hero.global_position - closest_enemy.global_position
	var distance := offset.length()
	if distance < 0.001:
		offset = Vector2.RIGHT
		distance = 0.0

	if distance < flee_distance:
		_move_with_anti_corner(_build_kite_direction(offset), delta)
	elif distance > preferred_distance:
		var approach_direction := -offset.normalized()
		_move_with_anti_corner(approach_direction, delta * 0.45)
	else:
		_move_with_anti_corner(_build_strafe_direction(offset), delta * 0.32)

func _return_to_center(delta: float) -> void:
	var to_center := GameConstants.HERO_START_POSITION - hero.global_position
	if to_center.length() < 4.0:
		return

	hero.global_position += to_center.normalized() * move_speed * 0.35 * delta
	hero.call("clamp_to_arena")

func _build_kite_direction(offset: Vector2) -> Vector2:
	var away := offset.normalized()
	var tangent := Vector2(-away.y, away.x)
	var center_bias := (GameConstants.ARENA_CENTER - hero.global_position).normalized()
	return (away + tangent * strafe_weight + center_bias * 0.45).normalized()

func _build_strafe_direction(offset: Vector2) -> Vector2:
	var tangent := Vector2(-offset.normalized().y, offset.normalized().x)
	var center_bias := (GameConstants.ARENA_CENTER - hero.global_position).normalized()
	return (tangent * 0.8 + center_bias * 0.35).normalized()

func _move_with_anti_corner(direction: Vector2, scaled_delta: float) -> void:
	var next_position := hero.global_position + direction.normalized() * move_speed * scaled_delta
	var clamped := _clamp_to_arena(next_position)
	if clamped.distance_squared_to(hero.global_position) < 1.0:
		var rescue_direction := (GameConstants.ARENA_CENTER - hero.global_position).normalized()
		clamped = _clamp_to_arena(hero.global_position + rescue_direction * move_speed * scaled_delta)
	hero.global_position = clamped

func _find_closest_enemy() -> Node2D:
	var enemies := hero.get_tree().get_nodes_in_group("enemies")
	return TargetSelector.closest_enemy(hero.global_position, enemies)

func _clamp_to_arena(position: Vector2) -> Vector2:
	var radius: float = float(hero.get("body_radius"))
	return Vector2(
		clampf(position.x, GameConstants.ARENA_MIN.x + radius, GameConstants.ARENA_MAX.x - radius),
		clampf(position.y, GameConstants.ARENA_MIN.y + radius, GameConstants.ARENA_MAX.y - radius)
	)
