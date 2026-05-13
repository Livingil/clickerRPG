extends Node2D
class_name FireBurstRing

var ring: Polygon2D

func setup(center_position: Vector2, radius: float) -> void:
	_ensure_ring()
	global_position = center_position
	var scale_factor := maxf(0.8, radius / 18.0)
	scale = Vector2.ONE * scale_factor

func _ready() -> void:
	_ensure_ring()
	var tween := create_tween()
	tween.tween_property(self, "scale", scale * 2.0, 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)

func _ensure_ring() -> void:
	if ring != null and is_instance_valid(ring):
		return
	ring = get_node_or_null("Ring") as Polygon2D
	if ring != null:
		return
	ring = Polygon2D.new()
	ring.name = "Ring"
	ring.color = Color(1.0, 0.52, 0.16, 0.85)
	ring.polygon = PackedVector2Array([
		Vector2(-6, -22), Vector2(6, -22), Vector2(22, -6), Vector2(22, 6),
		Vector2(6, 22), Vector2(-6, 22), Vector2(-22, 6), Vector2(-22, -6),
	])
	add_child(ring)
