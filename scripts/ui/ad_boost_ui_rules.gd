extends RefCounted
class_name AdBoostUiRules

static func get_icon(boost_id: StringName) -> String:
	match boost_id:
		GameState.AD_BOOST_GOLD_RUSH:
			return "$"
		GameState.AD_BOOST_ESSENCE_SURGE:
			return "E"
		GameState.AD_BOOST_BATTLE_FOCUS:
			return "DMG"
		GameState.AD_BOOST_HASTE_SPARK:
			return "SPD"
		GameState.AD_BOOST_ECHO_MAGNET:
			return "EC"
		GameState.AD_BOOST_SECOND_WIND:
			return "HP"
		GameState.AD_BOOST_GAME_SPEED:
			return ">>"
		_:
			return "AD"

static func get_color(boost_id: StringName) -> Color:
	match boost_id:
		GameState.AD_BOOST_GOLD_RUSH:
			return Color(1.0, 0.78, 0.18, 1.0)
		GameState.AD_BOOST_ESSENCE_SURGE:
			return Color(0.50, 0.85, 1.0, 1.0)
		GameState.AD_BOOST_BATTLE_FOCUS:
			return Color(1.0, 0.34, 0.24, 1.0)
		GameState.AD_BOOST_HASTE_SPARK:
			return Color(0.52, 1.0, 0.44, 1.0)
		GameState.AD_BOOST_ECHO_MAGNET:
			return Color(0.74, 0.56, 1.0, 1.0)
		GameState.AD_BOOST_SECOND_WIND:
			return Color(0.62, 1.0, 0.72, 1.0)
		GameState.AD_BOOST_GAME_SPEED:
			return Color(0.78, 0.95, 1.0, 1.0)
		_:
			return Color.WHITE

static func apply_offer_button_style(button: Button, boost_id: StringName) -> void:
	if button == null:
		return
	var color: Color = get_color(boost_id)
	var normal_style: StyleBoxFlat = button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	normal_style.bg_color = color.darkened(0.45)
	normal_style.border_color = color.lightened(0.20)
	button.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = color.darkened(0.30)
	button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = color.darkened(0.62)
	button.add_theme_stylebox_override("pressed", pressed_style)
