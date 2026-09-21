extends PanelContainer
class_name PrestigePanel

@onready var content: VBoxContainer = $Margin/Content

var tree_rows: VBoxContainer

func _ready() -> void:
	GameState.echo_changed.connect(_on_state_changed)
	GameState.hero_stats_changed.connect(_on_state_changed)
	GameState.school_state_changed.connect(_on_state_changed)
	GameState.upgrades_changed.connect(_on_state_changed)
	GameState.prestige_performed.connect(_on_state_changed)
	GameState.language_changed.connect(_on_state_changed)
	_refresh()

func _refresh(_arg0: Variant = null, _arg1: Variant = null) -> void:
	_clear_container(content)
	var is_ru: bool = GameState.current_language == &"ru"
	var panel_data: Dictionary = GameState.get_prestige_panel_data()
	var preview: Dictionary = panel_data.get("preview", {})

	var title: Label = Label.new()
	title.text = "Престиж" if is_ru else "Prestige"
	title.add_theme_font_size_override("font_size", 18)
	content.add_child(title)

	var info: Label = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = (
		"Доступно shard: %d | Всего заработано: %d | Престижей: %d\nНаграда сейчас: +%d shard\nXP школ: x%.2f -> x%.2f"
		if is_ru
		else
		"Available shards: %d | Total earned: %d | Prestiges: %d\nReward now: +%d shards\nSchool XP: x%.2f -> x%.2f"
	) % [
		int(panel_data.get("available_shards", 0)),
		int(panel_data.get("earned_total", 0)),
		int(panel_data.get("prestige_count", 0)),
		int(preview.get("gained_shards", 0)),
		float(preview.get("school_xp_multiplier_before", 1.0)),
		float(preview.get("school_xp_multiplier_after", 1.0)),
	]
	content.add_child(info)

	var prestige_button: Button = Button.new()
	prestige_button.text = "Сделать престиж" if is_ru else "Prestige Reset"
	prestige_button.disabled = not bool(panel_data.get("can_prestige", false))
	if prestige_button.disabled:
		prestige_button.text = String(panel_data.get("unlock_text", ""))
	prestige_button.pressed.connect(_on_prestige_pressed)
	content.add_child(prestige_button)

	var tree_title: Label = Label.new()
	tree_title.text = "Дерево престижа" if is_ru else "Prestige Tree"
	tree_title.add_theme_font_size_override("font_size", 16)
	content.add_child(tree_title)

	tree_rows = VBoxContainer.new()
	tree_rows.add_theme_constant_override("separation", 5)
	content.add_child(tree_rows)
	for row_data in panel_data.get("upgrade_rows", []):
		tree_rows.add_child(_create_upgrade_row(row_data))

	var dev_reset_button: Button = Button.new()
	dev_reset_button.text = "Начать сначала (dev)" if is_ru else "Start Over (dev)"
	dev_reset_button.pressed.connect(_on_dev_reset_pressed)
	content.add_child(dev_reset_button)

func _create_upgrade_row(row_data: Dictionary) -> Control:
	var is_ru: bool = GameState.current_language == &"ru"
	var upgrade_id: StringName = row_data.get("id", &"") as StringName
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var label: Label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "%s  Lv.%d\n%s" % [
		String(row_data.get("name", upgrade_id)),
		int(row_data.get("level", 0)),
		String(row_data.get("description", "")),
	]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)

	var cost: int = int(row_data.get("cost", 0))
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(86.0, 44.0)
	button.text = ("Купить\n%d" % cost) if is_ru else ("Buy\n%d" % cost)
	button.disabled = not bool(row_data.get("can_buy", false))
	if bool(row_data.get("maxed", false)):
		button.text = "MAX"
		button.disabled = true
	button.pressed.connect(_on_buy_upgrade.bind(upgrade_id))
	row.add_child(button)
	return row

func _on_state_changed(_arg0: Variant = null, _arg1: Variant = null) -> void:
	_refresh()

func _on_prestige_pressed() -> void:
	var result: Dictionary = await _request_backend_command("prestige.perform", {})
	var performed: bool = bool(result.get("success", false))
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		performed = GameState.perform_prestige()
	if performed:
		SaveSystem.save_game()
		SignalBus.emit_runtime_reset_requested()
	_refresh()

func _on_buy_upgrade(upgrade_id: StringName) -> void:
	var result: Dictionary = await _request_backend_command("prestige.upgrade", {"upgradeId": String(upgrade_id)})
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		GameState.buy_prestige_upgrade(upgrade_id)
	_refresh()

func _on_dev_reset_pressed() -> void:
	var result: Dictionary = await _request_backend_command("dev.resetAll", {})
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		GameState.dev_reset_all_progress()
	SaveSystem.save_game()
	SignalBus.emit_runtime_reset_requested()
	_refresh()

func _request_backend_command(command_name: String, payload: Dictionary) -> Dictionary:
	return await BackendClient.request_command(command_name, payload)

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
