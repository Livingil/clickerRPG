extends Node2D
class_name DeathBurst

@onready var ring: Polygon2D = $Ring

var burst_color: Color = Color(1, 0.5, 0.5, 0.9)
var burst_scale: Vector2 = Vector2.ONE

func setup(color: Color, radius: float) -> void:
	burst_color = color
	var scale_factor := maxf(0.7, radius / 18.0)
	burst_scale = Vector2.ONE * scale_factor
	if is_node_ready():
		_apply_visuals()

func _ready() -> void:
	_apply_visuals()
	var tween := create_tween()
	tween.tween_property(self, "scale", scale * 1.9, 0.18)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	tween.finished.connect(queue_free)

func _apply_visuals() -> void:
	ring.color = burst_color
	scale = burst_scale
