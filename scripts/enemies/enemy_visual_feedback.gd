extends RefCounted
class_name EnemyVisualFeedback

static func play_hit_feedback(owner: Node, body: Polygon2D, hit_color: Color, base_modulate: Color) -> void:
	if owner == null or body == null:
		return

	body.modulate = hit_color
	body.scale = Vector2(1.08, 1.08)

	var tween: Tween = owner.create_tween()
	tween.tween_property(body, "modulate", base_modulate, 0.08)
	tween.parallel().tween_property(body, "scale", Vector2.ONE, 0.08)

static func spawn_death_burst(parent: Node, burst_scene: PackedScene, spawn_position: Vector2, color: Color, radius: float) -> void:
	if parent == null or burst_scene == null:
		return

	var burst: Node2D = burst_scene.instantiate() as Node2D
	if burst == null:
		return

	burst.global_position = spawn_position
	if burst.has_method("setup"):
		burst.call("setup", color, radius)
	parent.add_child(burst)

static func spawn_combat_text(owner: Node, text: String, color: Color, scale_value: float) -> void:
	if owner == null:
		return

	var label: Label = Label.new()
	label.text = text
	label.modulate = color
	label.z_index = 100
	label.scale = Vector2.ONE * scale_value
	label.position = Vector2(-20.0, -40.0)
	owner.add_child(label)

	var jitter: Vector2 = Vector2(randf_range(-14.0, 14.0), randf_range(-4.0, 4.0))
	var tween: Tween = owner.create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0.0, -28.0) + jitter, 0.34)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.34)
	tween.finished.connect(label.queue_free)
