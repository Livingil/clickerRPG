extends Node
class_name HeroMovementComponent

@export var move_speed: float = GameConstants.HERO_MOVE_SPEED
@export var flee_distance: float = GameConstants.HERO_FLEE_DISTANCE
@export var preferred_distance: float = GameConstants.HERO_PREFERRED_DISTANCE
@export var strafe_weight: float = GameConstants.HERO_STRAFE_WEIGHT
@export var flee_direction_lock_time: float = GameConstants.HERO_FLEE_DIRECTION_LOCK_TIME
@export var orbit_switch_interval_min: float = GameConstants.HERO_ORBIT_SWITCH_INTERVAL_MIN
@export var orbit_switch_interval_max: float = GameConstants.HERO_ORBIT_SWITCH_INTERVAL_MAX
@export var manual_target_reach_distance: float = 14.0
@export var crowd_awareness_radius: float = 280.0
@export var safe_direction_samples: int = 16
@export var target_switch_distance_bias: float = 36.0

@onready var hero: Node2D = owner as Node2D

var flee_direction: Vector2 = Vector2.ZERO
var flee_direction_lock_left: float = 0.0
var orbit_sign: float = 1.0
var orbit_switch_left: float = 0.0
var has_manual_target: bool = false
var manual_move_target: Vector2 = Vector2.ZERO
var sticky_target: Node2D

func tick(delta: float) -> void:
	if has_manual_target:
		if _move_to_manual_target(delta):
			has_manual_target = false
		return

	flee_direction_lock_left = maxf(0.0, flee_direction_lock_left - delta)
	orbit_switch_left = maxf(0.0, orbit_switch_left - delta)

	var enemies := _get_enemies()
	var closest_enemy := _select_stable_target(enemies)
	if closest_enemy == null:
		flee_direction = Vector2.ZERO
		orbit_switch_left = 0.0
		sticky_target = null
		_return_to_center(delta)
		return

	var offset := hero.global_position - closest_enemy.global_position
	var distance := offset.length()
	if distance < 0.001:
		offset = Vector2.RIGHT
		distance = 0.0

	if orbit_switch_left <= 0.0:
		_update_orbit_sign(offset, closest_enemy.global_position)
		orbit_switch_left = randf_range(orbit_switch_interval_min, orbit_switch_interval_max)

	if distance < flee_distance:
		if flee_direction_lock_left <= 0.0 or flee_direction == Vector2.ZERO:
			flee_direction = _build_crowd_safe_direction(offset, enemies)
			flee_direction_lock_left = flee_direction_lock_time
		_move_with_anti_corner(flee_direction, delta)
	elif distance > preferred_distance:
		flee_direction = Vector2.ZERO
		var approach_direction := -offset.normalized()
		_move_with_anti_corner(approach_direction, delta * 0.45)
	else:
		flee_direction = Vector2.ZERO
		_move_with_anti_corner(_build_strafe_direction(offset), delta * 0.32)

func set_manual_move_target(world_position: Vector2) -> void:
	has_manual_target = true
	manual_move_target = _clamp_to_arena(world_position)
	flee_direction = Vector2.ZERO
	flee_direction_lock_left = 0.0
	orbit_switch_left = 0.0

func _move_to_manual_target(delta: float) -> bool:
	var clamped_target := _clamp_to_arena(manual_move_target)
	var to_target := clamped_target - hero.global_position
	if to_target.length() <= manual_target_reach_distance:
		return true

	_move_with_anti_corner(to_target, delta)
	return false

func _build_crowd_safe_direction(offset: Vector2, enemies: Array[Node]) -> Vector2:
	var nearest_based := _build_kite_direction(offset)
	var crowd_based := _find_open_direction(enemies)
	return (nearest_based * 0.45 + crowd_based * 0.55).normalized()

func _return_to_center(delta: float) -> void:
	var to_center := GameConstants.HERO_START_POSITION - hero.global_position
	if to_center.length() < 4.0:
		return

	hero.global_position += to_center.normalized() * move_speed * 0.35 * delta
	hero.call("clamp_to_arena")

func _build_kite_direction(offset: Vector2) -> Vector2:
	var away := offset.normalized()
	var tangent := Vector2(-away.y, away.x) * orbit_sign
	var center_bias := (GameConstants.ARENA_CENTER - hero.global_position).normalized()
	return (away + tangent * strafe_weight + center_bias * 0.45).normalized()

func _build_strafe_direction(offset: Vector2) -> Vector2:
	var tangent := Vector2(-offset.normalized().y, offset.normalized().x) * orbit_sign
	var center_bias := (GameConstants.ARENA_CENTER - hero.global_position).normalized()
	return (tangent * 0.8 + center_bias * 0.35).normalized()

func _update_orbit_sign(offset: Vector2, enemy_position: Vector2) -> void:
	var away := offset.normalized()
	var counter_clockwise := Vector2(-away.y, away.x)
	var clockwise := -counter_clockwise

	var ccw_score := _score_orbit_direction(counter_clockwise, enemy_position)
	var cw_score := _score_orbit_direction(clockwise, enemy_position)

	if absf(ccw_score - cw_score) < 6.0:
		orbit_sign *= -1.0
	elif ccw_score > cw_score:
		orbit_sign = 1.0
	else:
		orbit_sign = -1.0

func _score_orbit_direction(tangent: Vector2, enemy_position: Vector2) -> float:
	var projected_position := _clamp_to_arena(hero.global_position + tangent.normalized() * move_speed * 0.45)
	var center_score := 220.0 - projected_position.distance_to(GameConstants.ARENA_CENTER)
	var distance_score := projected_position.distance_to(enemy_position) * 0.22
	return center_score + distance_score

func _move_with_anti_corner(direction: Vector2, scaled_delta: float) -> void:
	var next_position := hero.global_position + direction.normalized() * move_speed * scaled_delta
	var clamped := _clamp_to_arena(next_position)
	if clamped.distance_squared_to(hero.global_position) < 1.0:
		var rescue_direction := (GameConstants.ARENA_CENTER - hero.global_position).normalized()
		clamped = _clamp_to_arena(hero.global_position + rescue_direction * move_speed * scaled_delta)
	hero.global_position = clamped

func _get_enemies() -> Array[Node]:
	return hero.get_tree().get_nodes_in_group("enemies")

func _select_stable_target(enemies: Array[Node]) -> Node2D:
	var nearest := TargetSelector.closest_enemy(hero.global_position, enemies)
	if nearest == null:
		return null

	if not is_instance_valid(sticky_target):
		sticky_target = nearest
		return sticky_target

	var sticky_distance := hero.global_position.distance_to(sticky_target.global_position)
	var nearest_distance := hero.global_position.distance_to(nearest.global_position)

	if nearest == sticky_target:
		return sticky_target

	if nearest_distance + target_switch_distance_bias < sticky_distance:
		sticky_target = nearest

	return sticky_target

func _find_open_direction(enemies: Array[Node]) -> Vector2:
	var nearby_positions: Array[Vector2] = []
	var radius_sq := crowd_awareness_radius * crowd_awareness_radius
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy is not Node2D:
			continue
		var enemy_node := enemy as Node2D
		if hero.global_position.distance_squared_to(enemy_node.global_position) <= radius_sq:
			nearby_positions.append(enemy_node.global_position)

	if nearby_positions.is_empty():
		return (GameConstants.ARENA_CENTER - hero.global_position).normalized()

	var sample_count := maxi(8, safe_direction_samples)
	var best_dir := (GameConstants.ARENA_CENTER - hero.global_position).normalized()
	var best_score := -INF

	for i in range(sample_count):
		var angle := TAU * (float(i) / float(sample_count))
		var dir := Vector2.RIGHT.rotated(angle)
		var projected := _clamp_to_arena(hero.global_position + dir * move_speed * 0.7)

		var nearest_sq := INF
		for enemy_position in nearby_positions:
			var dist_sq := projected.distance_squared_to(enemy_position)
			if dist_sq < nearest_sq:
				nearest_sq = dist_sq

		var center_penalty := projected.distance_squared_to(GameConstants.ARENA_CENTER) * 0.0007
		var score := nearest_sq - center_penalty
		if score > best_score:
			best_score = score
			best_dir = dir

	return best_dir.normalized()

func _clamp_to_arena(position: Vector2) -> Vector2:
	var radius: float = float(hero.get("body_radius"))
	return Vector2(
		clampf(position.x, GameConstants.ARENA_MIN.x + radius, GameConstants.ARENA_MAX.x - radius),
		clampf(position.y, GameConstants.ARENA_MIN.y + radius, GameConstants.ARENA_MAX.y - radius)
	)
