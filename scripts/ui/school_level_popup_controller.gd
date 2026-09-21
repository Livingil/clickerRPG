extends RefCounted
class_name SchoolLevelPopupController

signal open_skills_requested

var popup: PanelContainer
var title_label: Label
var body_label: Label
var open_button: Button
var close_button: Button

func configure(root: Control) -> void:
	popup = PanelContainer.new()
	popup.name = "SchoolLevelPopup"
	popup.visible = false
	popup.z_index = 305
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.size = Vector2(500.0, 270.0)
	popup.position = Vector2(
		(GameConstants.VIEWPORT_WIDTH - popup.size.x) * 0.5,
		(GameConstants.VIEWPORT_HEIGHT - popup.size.y) * 0.5
	)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.10, 0.12, 0.97)
	panel_style.border_color = Color(0.65, 0.86, 1.0, 0.52)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	popup.add_theme_stylebox_override("panel", panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	popup.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	content.add_child(title_label)

	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.92, 1.0))
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 10)
	content.add_child(button_row)

	close_button = Button.new()
	close_button.custom_minimum_size = Vector2(120.0, 40.0)
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(close)
	button_row.add_child(close_button)

	open_button = Button.new()
	open_button.custom_minimum_size = Vector2(160.0, 40.0)
	open_button.mouse_filter = Control.MOUSE_FILTER_STOP
	open_button.pressed.connect(_on_open_pressed)
	button_row.add_child(open_button)
	root.add_child(popup)

func show_report(report: Dictionary) -> void:
	if report.is_empty() or popup == null:
		return
	var text_data: Dictionary = HudReportTextBuilder.build_school_level_text(report, GameState.current_language)
	title_label.text = String(text_data.get("title", ""))
	body_label.text = String(text_data.get("body", ""))
	close_button.text = String(text_data.get("close", ""))
	open_button.text = String(text_data.get("action", ""))
	popup.visible = true

func close() -> void:
	if popup != null:
		popup.visible = false

func _on_open_pressed() -> void:
	close()
	open_skills_requested.emit()
