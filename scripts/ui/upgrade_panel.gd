extends PanelContainer
class_name UpgradePanel

@onready var rows_container: VBoxContainer = $Margin/Content/Rows

var row_map: Dictionary = {}

func _ready() -> void:
	_build_rows()
	GameState.resources_changed.connect(_refresh_all_rows)
	GameState.upgrades_changed.connect(_refresh_all_rows)
	_refresh_all_rows()

func _build_rows() -> void:
	for upgrade_id: StringName in GameState.get_upgrade_ids():
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)

		var text_label := Label.new()
		text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var buy_button := Button.new()
		buy_button.custom_minimum_size = Vector2(88.0, 0.0)
		buy_button.pressed.connect(_on_buy_button_pressed.bind(upgrade_id))

		row.add_child(text_label)
		row.add_child(buy_button)
		rows_container.add_child(row)

		row_map[upgrade_id] = {
			"label": text_label,
			"button": buy_button,
		}

func _refresh_all_rows(_gold: int = 0, _essence: int = 0) -> void:
	for upgrade_id: StringName in GameState.get_upgrade_ids():
		_refresh_row(upgrade_id)

func _refresh_row(upgrade_id: StringName) -> void:
	if not row_map.has(upgrade_id):
		return

	var ui_data: Dictionary = GameState.get_upgrade_ui_data(upgrade_id)
	var label: Label = row_map[upgrade_id]["label"]
	var button: Button = row_map[upgrade_id]["button"]

	label.text = "%s  Lv.%d  %s" % [
		ui_data["name"],
		ui_data["level"],
		ui_data["next_bonus_text"],
	]
	button.text = str(ui_data["cost"])
	button.disabled = not bool(ui_data["affordable"])

func _on_buy_button_pressed(upgrade_id: StringName) -> void:
	GameState.buy_upgrade(upgrade_id)
