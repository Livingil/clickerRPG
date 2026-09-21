extends PanelContainer
class_name AbilityPanel

@onready var title_label: Label = $Margin/Content/Title
@onready var school_tabs: HBoxContainer = $Margin/Content/SchoolTabs
@onready var school_value_label: Label = $Margin/Content/ProgressCard/ProgressMargin/ProgressRows/SchoolValue
@onready var mastery_value_label: Label = $Margin/Content/ProgressCard/ProgressMargin/ProgressRows/MasteryValue
@onready var current_bonus_value_label: Label = $Margin/Content/ProgressCard/ProgressMargin/ProgressRows/CurrentBonusValue
@onready var next_unlock_value_label: Label = $Margin/Content/ProgressCard/ProgressMargin/ProgressRows/NextUnlockValue
@onready var available_header_label: Label = $Margin/Content/Scroll/Body/Columns/AvailableSection/AvailableMargin/AvailableRows/AvailableHeader
@onready var available_buttons: GridContainer = $Margin/Content/Scroll/Body/Columns/AvailableSection/AvailableMargin/AvailableRows/AvailableButtons
@onready var slots_header_label: Label = $Margin/Content/Scroll/Body/Columns/SlotsSection/SlotsMargin/SlotsRows/SlotsHeader
@onready var skill_rows: GridContainer = $Margin/Content/Scroll/Body/Columns/SlotsSection/SlotsMargin/SlotsRows/SkillRowsCenter/SkillRows
@onready var skill_info_overlay: ColorRect = $SkillInfoOverlay
@onready var skill_info_modal: PanelContainer = $SkillInfoOverlay/SkillInfoModal
@onready var skill_info_header_label: Label = $SkillInfoOverlay/SkillInfoModal/ModalMargin/ModalRows/TopRow/SkillInfoHeader
@onready var skill_info_close_button: Button = $SkillInfoOverlay/SkillInfoModal/ModalMargin/ModalRows/TopRow/SkillInfoCloseButton
@onready var skill_info_text: RichTextLabel = $SkillInfoOverlay/SkillInfoModal/ModalMargin/ModalRows/SkillInfoText

var pending_skill_id: StringName = &""
var cached_core_level: int = -1
var cached_school_id: StringName = &""
var selected_skill_info_id: StringName = &""

func _ready() -> void:
	GameState.school_state_changed.connect(_refresh)
	GameState.school_mastery_changed.connect(_on_mastery_changed)
	GameState.language_changed.connect(_refresh)
	skill_info_close_button.pressed.connect(_close_skill_info_modal)
	skill_info_overlay.visible = false
	_apply_skill_info_modal_style()
	_refresh()

func _refresh() -> void:
	_rebuild_school_tabs()
	_refresh_header()
	_refresh_available_skills()
	_refresh_slots()
	_refresh_skill_info()
	cached_school_id = GameState.active_school
	cached_core_level = GameState.get_school_core_mastery_level(cached_school_id)

func _on_mastery_changed() -> void:
	var current_school: StringName = GameState.active_school
	var current_core_level: int = GameState.get_school_core_mastery_level(current_school)
	_refresh_header()
	if current_school != cached_school_id or current_core_level != cached_core_level:
		_refresh_available_skills()
		cached_school_id = current_school
		cached_core_level = current_core_level

func _rebuild_school_tabs() -> void:
	for child in school_tabs.get_children():
		child.queue_free()
	for school_id in GameState.get_school_ids():
		var def: Dictionary = GameState.get_school_definition(school_id)
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(72, 34)
		button.toggle_mode = true
		button.text = String(def.get("name", school_id))
		button.button_pressed = school_id == GameState.active_school
		button.disabled = school_id == GameState.active_school
		button.pressed.connect(_on_school_tab_pressed.bind(school_id))
		school_tabs.add_child(button)

func _refresh_header() -> void:
	var is_ru: bool = GameState.current_language == &"ru"
	title_label.text = GameState.loc("ui.skills")
	available_header_label.text = "Открытые навыки школы" if is_ru else "Opened School Skills"
	slots_header_label.text = "Слоты навыков" if is_ru else "Skill Slots"
	skill_info_header_label.text = "Информация о навыке" if is_ru else "Skill Info"
	skill_info_close_button.text = "Закрыть" if is_ru else "Close"

	var school_summary: Dictionary = GameState.get_active_school_summary()
	var current_school: StringName = GameState.active_school
	var core_level: int = GameState.get_school_core_mastery_level(current_school)
	var level_floor_xp: int = int(school_summary["current_level_floor_xp"])
	var xp_now: int = int(school_summary["mastery_xp"]) - level_floor_xp
	var next_xp: int = int(school_summary["next_level_xp"]) - level_floor_xp

	school_value_label.text = "%s / %s" % [school_summary["name"], school_summary["core_label"]]
	mastery_value_label.text = ("Ур.%d  XP %d / %d" % [core_level, xp_now, next_xp]) if is_ru else ("Lv.%d  XP %d / %d" % [core_level, xp_now, next_xp])
	current_bonus_value_label.text = AbilityPanelTextBuilder.build_current_bonus_text(current_school, is_ru)
	next_unlock_value_label.text = AbilityPanelTextBuilder.build_next_unlock_text(core_level, is_ru)

func _refresh_available_skills() -> void:
	for child in available_buttons.get_children():
		child.queue_free()

	var school_def: Dictionary = GameState.get_school_definition(GameState.active_school)
	var school_skills: Array = school_def.get("skills", [])
	var core_level: int = GameState.get_school_core_mastery_level(GameState.active_school)
	var equipped_ids: Array[StringName] = GameState.get_equipped_skill_ids()

	for skill_id_any in school_skills:
		var skill_id: StringName = skill_id_any as StringName
		var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
		var unlock_level: int = int(skill_data.get("unlock_level", 999))
		if core_level < unlock_level:
			continue
		var button: SkillTileButton = SkillTileButton.new()
		var equipped: bool = equipped_ids.has(skill_id)
		button.text = ""
		button.skill_id = skill_id
		button.source_type = &"available"
		button.source_slot_index = -1
		button.drop_enabled = false
		button.custom_minimum_size = Vector2(96, 96)
		button.icon = AbilityTileUiRules.get_skill_icon(skill_data)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.tooltip_text = AbilityPanelTextBuilder.build_skill_tooltip(skill_id, skill_data, pending_skill_id, equipped)
		button.disabled = equipped
		AbilityTileUiRules.apply_skill_tile_style(button, pending_skill_id == skill_id, equipped)
		button.pressed.connect(_on_skill_pressed.bind(skill_id))
		available_buttons.add_child(button)

func _refresh_slots() -> void:
	for child in skill_rows.get_children():
		child.queue_free()
	var equipped_skill_ids: Array[StringName] = GameState.get_equipped_skill_ids()
	for slot_index in range(4):
		var slot_button: SkillTileButton = SkillTileButton.new()
		slot_button.custom_minimum_size = Vector2(98, 98)
		slot_button.size_flags_horizontal = Control.SIZE_FILL
		slot_button.size_flags_vertical = Control.SIZE_FILL
		slot_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		AbilityTileUiRules.apply_slot_tile_style(slot_button)
		slot_button.text = AbilityPanelTextBuilder.build_slot_text(slot_index, equipped_skill_ids, GameState.current_language)
		slot_button.source_type = &"slot"
		slot_button.source_slot_index = slot_index
		slot_button.drop_slot_index = slot_index
		slot_button.drop_enabled = slot_index < GameState.get_permanent_skill_slot_count()
		if slot_index < equipped_skill_ids.size():
			slot_button.skill_id = equipped_skill_ids[slot_index]
		else:
			slot_button.skill_id = &""
		if slot_button.skill_id != &"":
			var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(slot_button.skill_id, {})
			slot_button.text = ""
			slot_button.icon = AbilityTileUiRules.get_skill_icon(skill_data)
			slot_button.expand_icon = true
			slot_button.tooltip_text = AbilityPanelTextBuilder.build_skill_tooltip(slot_button.skill_id, skill_data, pending_skill_id, false)
		else:
			slot_button.icon = null
			slot_button.expand_icon = false
			slot_button.tooltip_text = slot_button.text.replace("\n", " ")
		slot_button.disabled = slot_index >= GameState.get_permanent_skill_slot_count()
		slot_button.pressed.connect(_on_slot_pressed.bind(slot_index))
		skill_rows.add_child(slot_button)

func _on_school_tab_pressed(school_id: StringName) -> void:
	var result: Dictionary = await _request_backend_command("school.setActive", {"schoolId": String(school_id)})
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		GameState.set_active_school(school_id)
	pending_skill_id = &""
	selected_skill_info_id = &""
	_refresh()

func _on_skill_pressed(skill_id: StringName) -> void:
	pending_skill_id = skill_id
	selected_skill_info_id = skill_id
	_refresh_slots()
	_open_skill_info_modal(skill_id)

func _on_slot_pressed(slot_index: int) -> void:
	if pending_skill_id != &"":
		var result: Dictionary = await _request_backend_command("school.equipSkill", {
			"slotIndex": slot_index,
			"skillId": String(pending_skill_id),
		})
		var changed: bool = bool(result.get("success", false))
		if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
			changed = GameState.replace_skill(slot_index, pending_skill_id)
		if changed:
			pending_skill_id = &""
		_refresh()
		return
	var result: Dictionary = await _request_backend_command("school.clearSkill", {"slotIndex": slot_index})
	var cleared: bool = bool(result.get("success", false))
	if bool(result.get("offline", false)) and BackendClient.should_apply_local_progress_fallback():
		cleared = GameState.clear_skill_slot(slot_index)
	if cleared:
		_refresh_slots()

func _request_backend_command(command_name: String, payload: Dictionary) -> Dictionary:
	return await BackendClient.request_command(command_name, payload)

func _refresh_skill_info() -> void:
	skill_info_text.text = AbilityPanelTextBuilder.build_skill_info_text(selected_skill_info_id, GameState.current_language)

func _open_skill_info_modal(skill_id: StringName) -> void:
	selected_skill_info_id = skill_id
	_refresh_skill_info()
	skill_info_overlay.visible = true

func _close_skill_info_modal() -> void:
	skill_info_overlay.visible = false

func _apply_skill_info_modal_style() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.10, 0.12, 1.0)
	panel_style.border_color = Color(0.30, 0.34, 0.40, 1.0)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	skill_info_modal.add_theme_stylebox_override("panel", panel_style)
