extends PanelContainer
class_name InfoPopup

signal action_requested(action: StringName)

var title_label: Label
var body_label: RichTextLabel
var action_button: Button
var close_button: Button
var current_action: StringName = &""

func _ready() -> void:
	_build()

func show_message(title: String, body: String, action_text: String = "", action: StringName = &"") -> void:
	if title_label == null:
		_build()
	title_label.text = title
	body_label.text = body
	current_action = action
	action_button.visible = not action_text.is_empty() and action != &""
	action_button.text = action_text
	visible = true

func close() -> void:
	visible = false
	current_action = &""

func _build() -> void:
	if title_label != null:
		return
	name = "InfoPopup"
	visible = false
	z_index = 304
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(500.0, 240.0)
	position = Vector2(
		(GameConstants.VIEWPORT_WIDTH - size.x) * 0.5,
		(GameConstants.VIEWPORT_HEIGHT - size.y) * 0.5
	)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.09, 0.11, 0.97)
	panel_style.border_color = Color(0.72, 0.94, 1.0, 0.46)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	content.add_child(title_label)

	body_label = RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.fit_content = true
	body_label.scroll_active = false
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.92, 1.0))
	content.add_child(body_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 10)
	content.add_child(button_row)

	close_button = Button.new()
	close_button.custom_minimum_size = Vector2(120.0, 40.0)
	close_button.text = "Close"
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(close)
	button_row.add_child(close_button)

	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(150.0, 40.0)
	action_button.visible = false
	action_button.mouse_filter = Control.MOUSE_FILTER_STOP
	action_button.pressed.connect(_on_action_pressed)
	button_row.add_child(action_button)

func _on_action_pressed() -> void:
	var action := current_action
	close()
	if action != &"":
		action_requested.emit(action)
