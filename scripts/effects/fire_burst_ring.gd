extends Node2D
class_name FireBurstRing

@onready var ring: Polygon2D = $Ring

func setup(center_position: Vector2, radius: float) -> void:
	global_position = center_position
	var scale_factor := maxf(0.8, radius / 18.0)
	scale = Vector2.ONE * scale_factor

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", scale * 2.0, 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)
