extends Line2D
class_name FireChainArc

func setup_points(points: Array[Vector2]) -> void:
	clear_points()
	for point in points:
		add_point(point)
	gradient = _build_fire_gradient()
	default_color = Color(1.0, 0.55, 0.18, 1.0)
	width = 8.0

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.parallel().tween_property(self, "width", 2.0, 0.16)
	tween.finished.connect(queue_free)

func _build_fire_gradient() -> Gradient:
	var fire_gradient := Gradient.new()
	fire_gradient.colors = PackedColorArray([
		Color(1.0, 0.95, 0.72, 0.95),
		Color(1.0, 0.66, 0.22, 0.98),
		Color(0.98, 0.22, 0.05, 0.9),
	])
	fire_gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	return fire_gradient
