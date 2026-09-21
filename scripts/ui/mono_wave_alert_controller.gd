extends RefCounted
class_name MonoWaveAlertController

const MONO_WAVE_ALERT_SEC: float = 4.0

var root: Control
var alert_label: Label
var time_left: float = 0.0

func configure(root_control: Control) -> void:
	root = root_control
	alert_label = Label.new()
	alert_label.name = "MonoWaveAlert"
	alert_label.visible = false
	alert_label.z_index = 240
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_label.size = Vector2(GameConstants.VIEWPORT_WIDTH - 48.0, 56.0)
	alert_label.position = Vector2(
		24.0,
		GameConstants.UI_HEADER_HEIGHT + ((GameConstants.VIEWPORT_HEIGHT - GameConstants.UI_HEADER_HEIGHT - GameConstants.UI_FOOTER_HEIGHT) - alert_label.size.y) * 0.5
	)
	alert_label.add_theme_font_size_override("font_size", 24)
	alert_label.add_theme_color_override("font_color", Color(1.0, 0.18, 0.12, 1.0))
	alert_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	alert_label.add_theme_constant_override("shadow_offset_x", 2)
	alert_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(alert_label)

func show_alert(wave: int, enemy_type: StringName) -> void:
	if alert_label == null:
		return
	alert_label.text = (
		"ВНИМАНИЕ: Волна %d - только %s!"
		if GameState.current_language == &"ru"
		else
		"WARNING: Wave %d - only %s!"
	) % [wave, _get_enemy_type_display_name(enemy_type)]
	time_left = MONO_WAVE_ALERT_SEC
	alert_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	alert_label.visible = true

func process(delta: float) -> void:
	if alert_label == null or not alert_label.visible:
		return
	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		alert_label.visible = false
		return
	if time_left < 0.6:
		alert_label.modulate.a = time_left / 0.6

func _get_enemy_type_display_name(enemy_type: StringName) -> String:
	var is_ru: bool = GameState.current_language == &"ru"
	match enemy_type:
		GameConstants.ENEMY_TYPE_BASIC:
			return "бойцы" if is_ru else "fighters"
		GameConstants.ENEMY_TYPE_TANK:
			return "танки" if is_ru else "tanks"
		GameConstants.ENEMY_TYPE_FAST:
			return "быстрые враги" if is_ru else "fast enemies"
		GameConstants.ENEMY_TYPE_RANGED:
			return "стрелки" if is_ru else "shooters"
	return "враги" if is_ru else "enemies"
