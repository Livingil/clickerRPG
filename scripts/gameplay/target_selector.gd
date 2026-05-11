extends RefCounted
class_name TargetSelector

static func closest_enemy(origin: Vector2, enemies: Array[Node]) -> Node2D:
	return closest_enemy_in_range(origin, enemies, INF)

static func closest_enemy_in_range(origin: Vector2, enemies: Array[Node], max_range: float) -> Node2D:
	var best_enemy: Node2D = null
	var best_distance := INF
	var max_distance_squared := max_range * max_range

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy is not Node2D:
			continue

		var enemy_node := enemy as Node2D
		var distance := origin.distance_squared_to(enemy_node.global_position)
		if distance > max_distance_squared:
			continue
		if distance < best_distance:
			best_distance = distance
			best_enemy = enemy_node

	return best_enemy
