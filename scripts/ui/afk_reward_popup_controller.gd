extends RefCounted
class_name AfkRewardPopupController

var popup: PanelContainer
var title_label: Label
var body_label: Label
var close_button: Button

func configure(root: Control) -> void:
	popup = PanelContainer.new()
	popup.name = "AfkRewardPopup"
	popup.visible = false
	popup.z_index = 300
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.size = Vector2(460.0, 230.0)
	popup.position = Vector2(
		(GameConstants.VIEWPORT_WIDTH - popup.size.x) * 0.5,
		(GameConstants.VIEWPORT_HEIGHT - popup.size.y) * 0.5
	)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.10, 0.12, 0.96)
	panel_style.border_color = Color(0.8, 0.9, 1.0, 0.42)
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
	body_label.add_theme_font_size_override("font_size", 16)
	body_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.92, 1.0))
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body_label)

	close_button = Button.new()
	close_button.custom_minimum_size = Vector2(150.0, 40.0)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(close)
	content.add_child(close_button)
	root.add_child(popup)

func show_report(report: Dictionary) -> void:
	if report.is_empty() or popup == null:
		return
	var text_data: Dictionary = HudReportTextBuilder.build_afk_reward_text(report, GameState.current_language)
	title_label.text = String(text_data.get("title", ""))
	body_label.text = String(text_data.get("body", ""))
	close_button.text = String(text_data.get("close", ""))
	popup.visible = true

func close() -> void:
	if popup != null:
		popup.visible = false
	GameState.clear_pending_offline_reward_report()
