extends PanelContainer
class_name AbilityPanel

@onready var school_value_label: Label = $Margin/Content/SchoolValue
@onready var mastery_value_label: Label = $Margin/Content/MasteryValue
@onready var slot_value_label: Label = $Margin/Content/SlotValue
@onready var available_buttons: VBoxContainer = $Margin/Content/AvailableButtons
@onready var skill_rows: VBoxContainer = $Margin/Content/SkillRows

var pending_skill_id: StringName = &""

func _ready() -> void:
	GameState.school_state_changed.connect(_refresh)
	GameState.school_mastery_changed.connect(_refresh_mastery_only)
	_refresh()

func _refresh() -> void:
	_refresh_header()

	for child in available_buttons.get_children():
		child.queue_free()
	for child in skill_rows.get_children():
		child.queue_free()

	for skill_data in GameState.get_available_skill_ui_data():
		var button := Button.new()
		var skill_id := skill_data["id"] as StringName
		var button_text := "%s (Lv.%d)  %s" % [
			skill_data["name"],
			skill_data["unlock_level"],
			skill_data["state_text"],
		]
		if pending_skill_id == skill_id:
			button_text += "  [Selected]"
		button.text = button_text
		button.disabled = bool(skill_data["equipped"])
		button.pressed.connect(_on_skill_pressed.bind(skill_id, bool(skill_data["can_equip"])))
		available_buttons.add_child(button)

	for row_text in GameState.get_ability_panel_rows():
		var title := Label.new()
		title.text = row_text
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		skill_rows.add_child(title)

	for slot_index in range(4):
		var slot_button := Button.new()
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_button.text = _build_slot_text(slot_index)
		slot_button.disabled = slot_index >= GameState.get_permanent_skill_slot_count()
		slot_button.pressed.connect(_on_slot_pressed.bind(slot_index))
		skill_rows.add_child(slot_button)

func _build_slot_text(slot_index: int) -> String:
	if slot_index >= GameState.get_permanent_skill_slot_count():
		return "Slot %d: Locked at wave %d" % [slot_index + 1, SchoolRules.SLOT_WAVE_UNLOCKS[slot_index]]
	var equipped_skill_ids := GameState.get_equipped_skill_ids()
	var equipped_skill_id: StringName = &""
	if slot_index < equipped_skill_ids.size():
		equipped_skill_id = equipped_skill_ids[slot_index]
	var slot_text := "Slot %d: " % (slot_index + 1)
	if equipped_skill_id == &"":
		slot_text += "Empty"
	else:
		var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(equipped_skill_id, {})
		slot_text += String(skill_data.get("name", equipped_skill_id))
	if pending_skill_id != &"":
		slot_text += " -> Tap to set"
	else:
		slot_text += " -> Tap to clear"
	return slot_text

func _on_skill_pressed(skill_id: StringName, can_equip: bool) -> void:
	if not can_equip:
		return
	pending_skill_id = skill_id
	_refresh()

func _on_slot_pressed(slot_index: int) -> void:
	if pending_skill_id != &"":
		if GameState.replace_skill(slot_index, pending_skill_id):
			pending_skill_id = &""
		_refresh()
		return

	if GameState.clear_skill_slot(slot_index):
		_refresh()

func _refresh_mastery_only() -> void:
	_refresh_header()

func _refresh_header() -> void:
	var school_summary := GameState.get_active_school_summary()
	school_value_label.text = "%s / %s" % [school_summary["name"], school_summary["core_label"]]
	mastery_value_label.text = "Lv.%d  XP %d / %d" % [
		school_summary["mastery_level"],
		school_summary["mastery_xp"],
		school_summary["next_level_xp"],
	]
	slot_value_label.text = "%d / 4 permanent skill slots" % GameState.get_permanent_skill_slot_count()
