extends Button
class_name SkillTileButton

var skill_id: StringName = &""
var source_type: StringName = &""
var source_slot_index: int = -1
var drop_slot_index: int = -1
var drop_enabled: bool = false

func _get_drag_data(_at_position: Vector2) -> Variant:
	if skill_id == &"":
		return null
	var data: Dictionary = {
		"kind": "skill",
		"skill_id": skill_id,
		"source_type": source_type,
		"source_slot_index": source_slot_index,
	}
	var preview: PanelContainer = PanelContainer.new()
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	if icon != null:
		var preview_button: Button = Button.new()
		preview_button.icon = icon
		preview_button.expand_icon = true
		preview_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_button.disabled = true
		preview_button.custom_minimum_size = Vector2(90, 90)
		margin.add_child(preview_button)
	else:
		var label: Label = Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(90, 90)
		margin.add_child(label)
	preview.add_child(margin)
	set_drag_preview(preview)
	return data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not drop_enabled:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if String(data.get("kind", "")) != "skill":
		return false
	var incoming_skill: StringName = StringName(data.get("skill_id", ""))
	if incoming_skill == &"":
		return false
	return drop_slot_index >= 0 and drop_slot_index < GameState.get_permanent_skill_slot_count()

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var incoming_skill: StringName = StringName(data.get("skill_id", ""))
	if incoming_skill == &"":
		return
	GameState.replace_skill(drop_slot_index, incoming_skill)
