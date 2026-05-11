extends Node
class_name EnemyMovementComponent

@export var stop_distance: float = 48.0

@onready var enemy: Enemy = owner as Enemy

func move_towards_target(target: Node2D, delta: float) -> void:
	if target == null:
		return

	var desired_position := enemy.get_chase_position()
	var to_target := desired_position - enemy.global_position
	if to_target.length() <= stop_distance:
		return

	enemy.global_position += to_target.normalized() * enemy.speed * delta
	enemy.clamp_to_arena()
