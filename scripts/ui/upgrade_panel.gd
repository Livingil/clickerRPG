extends PanelContainer
class_name UpgradePanel

@onready var tabs: TabContainer = $Margin/Content/Tabs
@onready var title_label: Label = $Margin/Content/Title
@onready var equipment_rows: VBoxContainer = $Margin/Content/Tabs/EquipmentTab/EquipmentScroll/EquipmentRows
@onready var artifacts_rows: VBoxContainer = $Margin/Content/Tabs/ArtifactsTab/ArtifactsScroll/ArtifactsRows

var expanded_equipment_id: StringName = &""
var refresh_timer: Timer
var refresh_pending: bool = false

func _ready() -> void:
	refresh_timer = Timer.new()
	refresh_timer.one_shot = true
	refresh_timer.wait_time = 0.15
	refresh_timer.timeout.connect(_refresh_all_now)
	add_child(refresh_timer)
	visibility_changed.connect(_on_visibility_changed)
	_remove_stats_tab()
	_apply_localized_labels()
	GameState.resources_changed.connect(_request_refresh)
	GameState.upgrades_changed.connect(_request_refresh)
	GameState.hero_stats_changed.connect(_request_refresh)
	GameState.language_changed.connect(_request_refresh)
	_refresh_all()

func _refresh_all(_arg0: Variant = null, _arg1: Variant = null) -> void:
	_refresh_all_now()

func _request_refresh(_arg0: Variant = null, _arg1: Variant = null) -> void:
	refresh_pending = true
	if not is_visible_in_tree():
		return
	if refresh_timer == null:
		_refresh_all_now()
		return
	if refresh_timer.is_stopped():
		refresh_timer.start()

func _refresh_all_now() -> void:
	refresh_pending = false
	_apply_localized_labels()
	_build_equipment_tab()
	_build_artifacts_tab()

func _on_visibility_changed() -> void:
	if is_visible_in_tree() and refresh_pending:
		_refresh_all_now()

func _remove_stats_tab() -> void:
	var stats_tab: Node = tabs.get_node_or_null("StatsTab")
	if stats_tab == null:
		return
	tabs.remove_child(stats_tab)
	stats_tab.queue_free()
	tabs.current_tab = 0

func _build_equipment_tab() -> void:
	_clear_container(equipment_rows)
	_build_weapon_skill_offers()

	var next_locked_shown: bool = false
	for row_data in GameState.get_equipment_ui_rows():
		var unlocked: bool = bool(row_data.get("unlocked", false))
		if not unlocked:
			if next_locked_shown:
				continue
			next_locked_shown = true
		equipment_rows.add_child(_build_equipment_row(row_data))

func _build_weapon_skill_offers() -> void:
	var offers: Array = GameState.get_pending_weapon_skill_offers()
	if not offers.is_empty():
		var offer_title: Label = Label.new()
		offer_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		offer_title.text = "Веха оружия: выбери 1 школу" if GameState.current_language == &"ru" else "Weapon Milestone: choose 1 school"
		equipment_rows.add_child(offer_title)
		for i in range(offers.size()):
			var offer: Dictionary = offers[i]
			var offer_button: Button = Button.new()
			offer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			offer_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			offer_button.text = String(offer.get("text", "Upgrade"))
			offer_button.pressed.connect(_on_pick_weapon_offer.bind(i))
			equipment_rows.add_child(offer_button)

func _build_equipment_row(row_data: Dictionary) -> VBoxContainer:
	var unlocked: bool = bool(row_data.get("unlocked", false))
	var row: VBoxContainer = VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)

	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.72, 0.72, 0.76, 1.0)
	var card_margin: MarginContainer = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 8)
	card_margin.add_theme_constant_override("margin_right", 8)
	card_margin.add_theme_constant_override("margin_top", 6)
	card_margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(card_margin)

	var card_body: VBoxContainer = VBoxContainer.new()
	card_body.add_theme_constant_override("separation", 4)
	card_margin.add_child(card_body)
	card_body.add_child(_build_equipment_top_row(row_data))
	card_body.add_child(_build_equipment_summary_row(row_data))
	card_body.add_child(_build_equipment_details(row_data))
	row.add_child(card)
	return row

func _build_equipment_top_row(row_data: Dictionary) -> HBoxContainer:
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 8)
	top_row.add_child(_build_equipment_info_button(row_data))
	top_row.add_child(_build_equipment_buy_button(row_data))
	return top_row

func _build_equipment_info_button(row_data: Dictionary) -> Button:
	var equipment_id: StringName = row_data.get("id", &"") as StringName
	var unlocked: bool = bool(row_data.get("unlocked", false))
	var info_button: Button = Button.new()
	info_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_button.flat = true
	var level: int = int(row_data.get("level", 0))
	var display_name: String = String(row_data.get("name", equipment_id))
	info_button.text = "%s  %s%d" % [
		("%s %s" % ["[LOCK]", display_name]) if not unlocked else display_name,
		("Ур." if GameState.current_language == &"ru" else "Lv."),
		level
	]
	info_button.disabled = not unlocked
	if unlocked:
		info_button.pressed.connect(_on_toggle_equipment_details.bind(equipment_id))
	else:
		info_button.modulate = Color(0.55, 0.55, 0.58, 1.0)
	return info_button

func _build_equipment_buy_button(row_data: Dictionary) -> Button:
	var equipment_id: StringName = row_data.get("id", &"") as StringName
	var unlocked: bool = bool(row_data.get("unlocked", false))
	var buy_button: Button = Button.new()
	buy_button.custom_minimum_size = Vector2(96.0, 0.0)
	if unlocked:
		var upgrade_cost: int = int(row_data.get("upgrade_cost", 0))
		buy_button.text = ("%d зол." % upgrade_cost) if GameState.current_language == &"ru" else ("%d g" % upgrade_cost)
		buy_button.disabled = GameState.gold < upgrade_cost
		buy_button.pressed.connect(_on_buy_equipment.bind(equipment_id))
	else:
		var unlock_cost: int = int(row_data.get("unlock_cost", 0))
		buy_button.text = ("Открыть %d" % unlock_cost) if GameState.current_language == &"ru" else ("Unlock %d" % unlock_cost)
		buy_button.disabled = not bool(row_data.get("can_unlock", false))
		buy_button.pressed.connect(_on_unlock_equipment.bind(equipment_id))
	return buy_button

func _build_equipment_summary_row(row_data: Dictionary) -> HBoxContainer:
	var unlocked: bool = bool(row_data.get("unlocked", false))
	var summary_row: HBoxContainer = HBoxContainer.new()
	summary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_theme_constant_override("separation", 10)

	var base_boost_label: Label = Label.new()
	base_boost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base_boost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	base_boost_label.text = String(row_data.get("base_boost_short", ""))
	base_boost_label.modulate = Color(0.55, 0.95, 0.55, 1.0) if unlocked else Color(0.62, 0.62, 0.66, 1.0)

	var milestone_label: Label = Label.new()
	milestone_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	milestone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	milestone_label.text = String(row_data.get("next_milestone_short", "")) if unlocked else ""
	milestone_label.modulate = Color(0.72, 0.82, 0.92, 1.0) if unlocked else Color(0.62, 0.62, 0.66, 1.0)

	summary_row.add_child(base_boost_label)
	summary_row.add_child(milestone_label)
	return summary_row

func _build_equipment_details(row_data: Dictionary) -> VBoxContainer:
	var equipment_id: StringName = row_data.get("id", &"") as StringName
	var unlocked: bool = bool(row_data.get("unlocked", false))
	var details: VBoxContainer = VBoxContainer.new()
	details.visible = unlocked and equipment_id == expanded_equipment_id
	details.add_theme_constant_override("separation", 4)
	details.add_child(_make_equipment_detail_label(("Следующий уровень: %s" if GameState.current_language == &"ru" else "Next level: %s") % String(row_data.get("next_level_boost", "")), Color(0.72, 0.96, 0.72, 1.0)))
	details.add_child(_make_equipment_detail_label(("Ближайшая веха: %s" if GameState.current_language == &"ru" else "Nearest milestone: %s") % String(row_data.get("next_milestone", "")), Color(0.78, 0.88, 1.0, 1.0)))
	details.add_child(_make_equipment_detail_label(("Периодические вехи:\n%s" if GameState.current_language == &"ru" else "Periodic milestones:\n%s") % String(row_data.get("periodic_milestones", "")), Color(0.82, 0.82, 0.86, 1.0)))
	details.add_child(_make_equipment_detail_label(("Текущий эффект:\n%s" if GameState.current_language == &"ru" else "Current effect:\n%s") % String(row_data.get("current_effect", "")), Color(0.68, 0.70, 0.76, 1.0)))
	return details

func _build_artifacts_tab() -> void:
	_clear_container(artifacts_rows)
	for row_data in GameState.get_artifact_ui_rows():
		artifacts_rows.add_child(_build_artifact_row(row_data))

func _build_artifact_row(row_data: Dictionary) -> VBoxContainer:
	var row: VBoxContainer = VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 8)

	var owned: bool = bool(row_data["owned"])
	var level: int = int(row_data["level"])
	var name_label: Label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = "%s  %s  %s%d" % [
		row_data["name"],
		("[Есть]" if owned else "[Закрыт]") if GameState.current_language == &"ru" else ("[Owned]" if owned else "[Locked]"),
		("Ур." if GameState.current_language == &"ru" else "Lv."),
		level,
	]

	var artifact_id: StringName = row_data["id"] as StringName
	var buy_button: Button = Button.new()
	buy_button.custom_minimum_size = Vector2(96.0, 0.0)
	buy_button.text = ("%d эсс." % int(row_data["cost"])) if GameState.current_language == &"ru" else ("%d e" % int(row_data["cost"]))
	buy_button.disabled = not bool(row_data["affordable"])
	buy_button.pressed.connect(_on_buy_artifact.bind(artifact_id))

	var effect_label: Label = Label.new()
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.modulate = Color(0.8, 0.82, 0.86, 1.0)
	effect_label.text = String(row_data.get("effect", ""))

	top_row.add_child(name_label)
	top_row.add_child(buy_button)
	row.add_child(top_row)
	row.add_child(effect_label)
	return row

func _on_buy_equipment(equipment_id: StringName) -> void:
	var result: Dictionary = await _request_backend_command("equipment.upgrade", {"equipmentId": String(equipment_id)})
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		GameState.buy_equipment_upgrade(equipment_id)
	_build_equipment_tab()

func _on_unlock_equipment(equipment_id: StringName) -> void:
	var result: Dictionary = await _request_backend_command("equipment.unlock", {"equipmentId": String(equipment_id)})
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		GameState.unlock_equipment(equipment_id)
	_build_equipment_tab()

func _on_buy_artifact(artifact_id: StringName) -> void:
	var result: Dictionary = await _request_backend_command("artifact.upgrade", {"artifactId": String(artifact_id)})
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		GameState.buy_artifact_upgrade(artifact_id)
	_build_artifacts_tab()

func _on_pick_weapon_offer(offer_index: int) -> void:
	var result: Dictionary = await _request_backend_command("weapon.applySchoolOffer", {"offerIndex": offer_index})
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		GameState.apply_weapon_skill_offer(offer_index)
	_build_equipment_tab()

func _request_backend_command(command_name: String, payload: Dictionary) -> Dictionary:
	return await BackendClient.request_command(command_name, payload)

func _on_toggle_equipment_details(equipment_id: StringName) -> void:
	expanded_equipment_id = &"" if expanded_equipment_id == equipment_id else equipment_id
	_build_equipment_tab()

func _make_equipment_detail_label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.modulate = color
	return label

func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func _apply_localized_labels() -> void:
	var is_ru: bool = GameState.current_language == &"ru"
	title_label.text = "Улучшения" if is_ru else "Upgrades"
	tabs.set_tab_title(0, "Экипировка" if is_ru else "Equipment")
	tabs.set_tab_title(1, "Артефакты" if is_ru else "Artifacts")
