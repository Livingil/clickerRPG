extends RefCounted
class_name EnemyTypeRules

static func get_normal_type_modifiers(enemy_type: StringName) -> Dictionary:
	match enemy_type:
		GameConstants.ENEMY_TYPE_TANK:
			return {
				"max_hp": 1.8,
				"speed": 0.65,
				"attack_damage": 1.15,
				"defense": GameConstants.ENEMY_TANK_DEFENSE_MULTIPLIER,
				"evasion": 0.55,
				"reward_gold": 1.5,
				"reward_essence": 1.2,
				"body_radius": 22.0,
			}
		GameConstants.ENEMY_TYPE_FAST:
			return {
				"max_hp": 0.65,
				"speed": 1.65,
				"attack_damage": 0.75,
				"evasion": 1.6,
				"reward_gold": 0.9,
				"body_radius": 15.0,
			}
		GameConstants.ENEMY_TYPE_RANGED:
			return {
				"max_hp": 0.75,
				"speed": 0.9,
				"attack_damage": 0.8,
				"attack_range": 420.0,
				"attack_cooldown": 1.35,
				"reward_gold": 1.2,
				"body_radius": 16.0,
			}
		_:
			return {
				"body_radius": 18.0,
			}

static func get_body_color(enemy_type: StringName) -> Color:
	match enemy_type:
		GameConstants.ENEMY_TYPE_TANK:
			return Color(0.43, 0.46, 0.50, 1.0)
		GameConstants.ENEMY_TYPE_FAST:
			return Color(1.0, 0.72, 0.20, 1.0)
		GameConstants.ENEMY_TYPE_RANGED:
			return Color(0.42, 0.72, 1.0, 1.0)
		_:
			return Color(0.86, 0.27, 0.31, 1.0)

static func get_body_polygon(enemy_type: StringName, body_radius: float) -> PackedVector2Array:
	match enemy_type:
		GameConstants.ENEMY_TYPE_TANK:
			return _regular_polygon_points(6, body_radius)
		GameConstants.ENEMY_TYPE_FAST:
			return _oval_polygon_points(body_radius * 0.72, body_radius * 1.18, 16)
		GameConstants.ENEMY_TYPE_RANGED:
			return PackedVector2Array([
				Vector2(-8.0, -24.0),
				Vector2(8.0, -24.0),
				Vector2(8.0, 24.0),
				Vector2(-8.0, 24.0),
			])
		_:
			return PackedVector2Array([
				Vector2(-18.0, -18.0),
				Vector2(18.0, -18.0),
				Vector2(18.0, 18.0),
				Vector2(-18.0, 18.0),
			])

static func _regular_polygon_points(sides: int, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(sides):
		var angle: float = -PI * 0.5 + TAU * float(i) / float(sides)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

static func _oval_polygon_points(radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
