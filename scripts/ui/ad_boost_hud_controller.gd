extends RefCounted
class_name AdBoostHudController

signal random_ad_boost_accepted(boost_id: StringName)

const AD_BOOST_BUTTON_SIZE: Vector2 = Vector2(188.0, 74.0)
const AD_BOOST_ENTRY_SEC: float = 0.8
const AD_BOOST_FIELD_SEC: float = 15.0
const AD_BOOST_EXIT_SEC: float = 0.8
const SPEED_AD_BUTTON_SIZE: Vector2 = Vector2(116.0, 44.0)

var root: Control
var ad_boost_button: Button
var speed_ad_button: Button
var ad_boost_indicator_panel: PanelContainer
var ad_boost_indicator_list: VBoxContainer
var ad_boost_flight_time: float = 0.0
var ad_boost_flight_start: Vector2 = Vector2.ZERO
var ad_boost_flight_entry: Vector2 = Vector2.ZERO
var ad_boost_flight_orbit_a: Vector2 = Vector2.ZERO
var ad_boost_flight_orbit_b: Vector2 = Vector2.ZERO
var ad_boost_flight_orbit_c: Vector2 = Vector2.ZERO
var ad_boost_flight_end: Vector2 = Vector2.ZERO
var indicator_refresh_left: float = 0.0

func configure(root_control: Control) -> void:
	root = root_control
	_setup_ad_boost_button()
	_setup_speed_ad_button()
	_setup_ad_boost_indicator()

func process(delta: float) -> void:
	_update_ad_boost_flight(delta)
	indicator_refresh_left = maxf(0.0, indicator_refresh_left - delta)
	if indicator_refresh_left <= 0.0:
		indicator_refresh_left = 0.25
		refresh_ad_boost_indicator()
		refresh_speed_ad_button()

func on_ad_boost_offer_changed(offer: Dictionary) -> void:
	if ad_boost_button == null:
		return
	if offer.is_empty():
		ad_boost_button.visible = false
		return
	var boost_id: StringName = offer.get("id", &"") as StringName
	ad_boost_button.text = "%s  РЕКЛАМА  %s\n%s: %s" % [
		AdBoostUiRules.get_icon(boost_id),
		AdBoostUiRules.get_icon(boost_id),
		GameState.get_ad_boost_display_name(boost_id),
		GameState.get_ad_boost_short_text(boost_id),
	]
	AdBoostUiRules.apply_offer_button_style(ad_boost_button, boost_id)
	_start_ad_boost_flight()

func refresh_speed_ad_button() -> void:
	if speed_ad_button == null:
		return
	if GameState.has_active_ad_boost(GameState.AD_BOOST_GAME_SPEED):
		var time_left: float = GameState.get_active_ad_boost_time_left(GameState.AD_BOOST_GAME_SPEED)
		speed_ad_button.text = ">> x2\n%s" % GameState.format_duration_short(time_left)
		speed_ad_button.disabled = false
		speed_ad_button.modulate = Color(1.0, 1.0, 1.0, 0.78)
		return
	speed_ad_button.text = ">> x2\nAD"
	speed_ad_button.disabled = false
	speed_ad_button.modulate = Color(1.0, 1.0, 1.0, 0.72)

func refresh_ad_boost_indicator() -> void:
	if ad_boost_indicator_list == null:
		return
	for child in ad_boost_indicator_list.get_children():
		child.queue_free()
	var boosts: Array[Dictionary] = GameState.get_active_ad_boosts_snapshot()
	ad_boost_indicator_panel.visible = not boosts.is_empty()
	if boosts.is_empty():
		return
	for boost in boosts:
		ad_boost_indicator_list.add_child(_create_ad_boost_indicator_row(boost))

func _setup_ad_boost_button() -> void:
	ad_boost_button = Button.new()
	ad_boost_button.name = "AdBoostButton"
	ad_boost_button.custom_minimum_size = AD_BOOST_BUTTON_SIZE
	ad_boost_button.size = AD_BOOST_BUTTON_SIZE
	ad_boost_button.visible = false
	ad_boost_button.z_index = 250
	ad_boost_button.mouse_filter = Control.MOUSE_FILTER_STOP
	ad_boost_button.focus_mode = Control.FOCUS_NONE
	ad_boost_button.text = "<< PLAY >>\nBOOST"
	ad_boost_button.add_theme_color_override("font_color", Color.WHITE)
	ad_boost_button.add_theme_color_override("font_hover_color", Color.WHITE)
	ad_boost_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	ad_boost_button.add_theme_font_size_override("font_size", 15)
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.9, 0.05, 0.05, 0.96)
	normal_style.border_color = Color(1.0, 1.0, 1.0, 0.65)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	ad_boost_button.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(1.0, 0.09, 0.08, 1.0)
	ad_boost_button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.65, 0.02, 0.02, 1.0)
	ad_boost_button.add_theme_stylebox_override("pressed", pressed_style)
	ad_boost_button.pressed.connect(_on_ad_boost_pressed)
	root.add_child(ad_boost_button)

func _setup_speed_ad_button() -> void:
	speed_ad_button = Button.new()
	speed_ad_button.name = "SpeedAdButton"
	speed_ad_button.custom_minimum_size = SPEED_AD_BUTTON_SIZE
	speed_ad_button.size = SPEED_AD_BUTTON_SIZE
	speed_ad_button.position = Vector2(
		GameConstants.VIEWPORT_WIDTH - SPEED_AD_BUTTON_SIZE.x - 12.0,
		GameConstants.UI_HEADER_HEIGHT + 10.0
	)
	speed_ad_button.z_index = 230
	speed_ad_button.mouse_filter = Control.MOUSE_FILTER_STOP
	speed_ad_button.focus_mode = Control.FOCUS_NONE
	speed_ad_button.add_theme_font_size_override("font_size", 15)
	speed_ad_button.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.92))
	speed_ad_button.add_theme_color_override("font_hover_color", Color.WHITE)
	speed_ad_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.04, 0.07, 0.09, 0.46)
	normal_style.border_color = Color(0.82, 0.94, 1.0, 0.24)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	speed_ad_button.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.06, 0.11, 0.14, 0.68)
	hover_style.border_color = Color(0.82, 0.94, 1.0, 0.46)
	speed_ad_button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.02, 0.04, 0.06, 0.78)
	speed_ad_button.add_theme_stylebox_override("pressed", pressed_style)
	speed_ad_button.pressed.connect(_on_speed_ad_pressed)
	root.add_child(speed_ad_button)
	refresh_speed_ad_button()

func _setup_ad_boost_indicator() -> void:
	ad_boost_indicator_panel = PanelContainer.new()
	ad_boost_indicator_panel.name = "AdBoostIndicator"
	ad_boost_indicator_panel.visible = false
	ad_boost_indicator_panel.z_index = 220
	ad_boost_indicator_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ad_boost_indicator_panel.position = Vector2(10.0, GameConstants.UI_HEADER_HEIGHT + 8.0)
	ad_boost_indicator_panel.custom_minimum_size = Vector2(190.0, 38.0)
	ad_boost_indicator_panel.modulate = Color(1.0, 1.0, 1.0, 0.74)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.07, 0.09, 0.46)
	panel_style.border_color = Color(0.82, 0.94, 1.0, 0.24)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	ad_boost_indicator_panel.add_theme_stylebox_override("panel", panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 6)
	ad_boost_indicator_panel.add_child(margin)

	ad_boost_indicator_list = VBoxContainer.new()
	ad_boost_indicator_list.add_theme_constant_override("separation", 3)
	margin.add_child(ad_boost_indicator_list)
	root.add_child(ad_boost_indicator_panel)

func _create_ad_boost_indicator_row(boost: Dictionary) -> Control:
	var boost_id: StringName = boost.get("id", &"") as StringName
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(176.0, 30.0)
	row.add_theme_constant_override("separation", 6)

	var icon: Label = Label.new()
	icon.text = AdBoostUiRules.get_icon(boost_id)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.custom_minimum_size = Vector2(30.0, 28.0)
	icon.add_theme_font_size_override("font_size", 15)
	icon.add_theme_color_override("font_color", AdBoostUiRules.get_color(boost_id))
	row.add_child(icon)

	var text: Label = Label.new()
	text.text = "%s  %s" % [
		GameState.get_ad_boost_short_text(boost_id),
		GameState.format_duration_short(float(boost.get("time_left", 0.0))),
	]
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.clip_text = true
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.92))
	row.add_child(text)
	return row

func _on_speed_ad_pressed() -> void:
	var result: Dictionary = await BackendClient.request_command("ad.activateSpeed", {})
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		GameState.accept_game_speed_ad_boost()
	refresh_speed_ad_button()
	refresh_ad_boost_indicator()

func _on_ad_boost_pressed() -> void:
	var boost_id: StringName = GameState.get_current_ad_boost_offer().get("id", &"") as StringName
	var offer_id: String = ""
	if BackendClient.logged_in:
		var offer_result: Dictionary = await BackendClient.request_command("ad.requestOffer", {})
		if bool(offer_result.get("success", false)):
			var offer: Dictionary = (offer_result.get("result", {}) as Dictionary).get("offer", {}) as Dictionary
			offer_id = String(offer.get("offerId", ""))
			boost_id = StringName(String(offer.get("id", boost_id)))
	var result: Dictionary = await BackendClient.request_command("ad.activateBoost", {"offerId": offer_id})
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		boost_id = GameState.accept_ad_boost_offer()
	elif bool(result.get("success", false)):
		GameState.dismiss_ad_boost_offer()
	else:
		return
	if ad_boost_button != null:
		ad_boost_button.visible = false
	refresh_ad_boost_indicator()
	random_ad_boost_accepted.emit(boost_id)

func _start_ad_boost_flight() -> void:
	ad_boost_flight_time = 0.0
	var from_left: bool = randf() < 0.5
	var min_y: float = GameConstants.UI_HEADER_HEIGHT + 24.0
	var max_y: float = GameConstants.VIEWPORT_HEIGHT - GameConstants.UI_FOOTER_HEIGHT - AD_BOOST_BUTTON_SIZE.y - 24.0
	var start_x: float = -AD_BOOST_BUTTON_SIZE.x if from_left else GameConstants.VIEWPORT_WIDTH + 8.0
	var end_x: float = GameConstants.VIEWPORT_WIDTH + 8.0 if from_left else -AD_BOOST_BUTTON_SIZE.x
	ad_boost_flight_start = Vector2(start_x, randf_range(min_y, max_y))
	ad_boost_flight_entry = _random_ad_boost_field_point()
	ad_boost_flight_orbit_a = _random_ad_boost_field_point()
	ad_boost_flight_orbit_b = _random_ad_boost_field_point()
	ad_boost_flight_orbit_c = _random_ad_boost_field_point()
	ad_boost_flight_end = Vector2(end_x, randf_range(min_y, max_y))
	ad_boost_button.position = ad_boost_flight_start
	ad_boost_button.visible = true

func _update_ad_boost_flight(delta: float) -> void:
	if ad_boost_button == null or not ad_boost_button.visible:
		return
	ad_boost_flight_time += delta
	var total_time: float = AD_BOOST_ENTRY_SEC + AD_BOOST_FIELD_SEC + AD_BOOST_EXIT_SEC
	if ad_boost_flight_time < AD_BOOST_ENTRY_SEC:
		var entry_t: float = _smooth_step(ad_boost_flight_time / AD_BOOST_ENTRY_SEC)
		ad_boost_button.position = ad_boost_flight_start.lerp(ad_boost_flight_entry, entry_t)
		return
	if ad_boost_flight_time < AD_BOOST_ENTRY_SEC + AD_BOOST_FIELD_SEC:
		var field_t: float = (ad_boost_flight_time - AD_BOOST_ENTRY_SEC) / AD_BOOST_FIELD_SEC
		ad_boost_button.position = _cubic_bezier(
			ad_boost_flight_entry,
			ad_boost_flight_orbit_a,
			ad_boost_flight_orbit_b,
			ad_boost_flight_orbit_c,
			field_t
		) + Vector2(0.0, sin(field_t * TAU * 4.0) * 22.0)
		return
	if ad_boost_flight_time < total_time:
		var exit_t: float = _smooth_step((ad_boost_flight_time - AD_BOOST_ENTRY_SEC - AD_BOOST_FIELD_SEC) / AD_BOOST_EXIT_SEC)
		ad_boost_button.position = ad_boost_flight_orbit_c.lerp(ad_boost_flight_end, exit_t)
		return
	ad_boost_button.visible = false

func _random_ad_boost_field_point() -> Vector2:
	var min_x: float = 28.0
	var max_x: float = GameConstants.VIEWPORT_WIDTH - AD_BOOST_BUTTON_SIZE.x - 28.0
	var min_y: float = GameConstants.UI_HEADER_HEIGHT + 24.0
	var max_y: float = GameConstants.VIEWPORT_HEIGHT - GameConstants.UI_FOOTER_HEIGHT - AD_BOOST_BUTTON_SIZE.y - 24.0
	return Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var clamped_t: float = clampf(t, 0.0, 1.0)
	var inv_t: float = 1.0 - clamped_t
	return (
		p0 * inv_t * inv_t * inv_t
		+ p1 * 3.0 * inv_t * inv_t * clamped_t
		+ p2 * 3.0 * inv_t * clamped_t * clamped_t
		+ p3 * clamped_t * clamped_t * clamped_t
	)

func _smooth_step(t: float) -> float:
	var clamped_t: float = clampf(t, 0.0, 1.0)
	return clamped_t * clamped_t * (3.0 - 2.0 * clamped_t)
