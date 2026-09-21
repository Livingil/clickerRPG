extends Node2D
class_name Battlefield

@onready var enemy_container: Node2D = $EnemyContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var effects_container: Node2D = $EffectsContainer

func clear_transient_nodes() -> void:
	_clear_container(projectile_container)
	_clear_container(effects_container)

func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
