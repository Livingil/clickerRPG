extends RefCounted
class_name AbilityTileUiRules

static func get_skill_icon(skill_data: Dictionary) -> Texture2D:
	var icon_path: String = String(skill_data.get("icon", ""))
	if icon_path.is_empty():
		return null
	return load(icon_path) as Texture2D

static func apply_skill_tile_style(button: Button, selected: bool, equipped: bool) -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.10, 0.12, 0.14, 0.98)
	normal_style.border_color = Color(0.28, 0.33, 0.38, 1.0)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	if selected:
		normal_style.border_color = Color(0.48, 0.82, 1.0, 1.0)
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.15, 0.18, 0.21, 1.0)

	var disabled_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.09, 0.10, 0.11, 0.84)
	disabled_style.border_color = Color(0.22, 0.24, 0.26, 1.0)

	button.modulate = Color(0.72, 0.72, 0.72, 1.0) if equipped else Color.WHITE
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", disabled_style)

static func apply_slot_tile_style(slot_button: Button) -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.13, 0.16, 0.98)
	normal_style.border_color = Color(0.28, 0.31, 0.36, 1.0)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.16, 0.17, 0.22, 1.0)

	var disabled_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.10, 0.11, 0.14, 0.98)
	disabled_style.border_color = Color(0.24, 0.26, 0.31, 1.0)

	slot_button.add_theme_stylebox_override("normal", normal_style)
	slot_button.add_theme_stylebox_override("pressed", hover_style)
	slot_button.add_theme_stylebox_override("hover", hover_style)
	slot_button.add_theme_stylebox_override("focus", hover_style)
	slot_button.add_theme_stylebox_override("disabled", disabled_style)
