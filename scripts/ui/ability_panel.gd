extends PanelContainer
class_name AbilityPanel

@onready var title_label: Label = $Margin/Content/Title
@onready var school_tabs: HBoxContainer = $Margin/Content/SchoolTabs
@onready var school_value_label: Label = $Margin/Content/SchoolValue
@onready var mastery_value_label: Label = $Margin/Content/MasteryValue
@onready var current_bonus_value_label: Label = $Margin/Content/CurrentBonusValue
@onready var next_unlock_value_label: Label = $Margin/Content/NextUnlockValue
@onready var available_header_label: Label = $Margin/Content/Scroll/Body/AvailableHeader
@onready var available_buttons: VBoxContainer = $Margin/Content/Scroll/Body/AvailableButtons
@onready var slots_header_label: Label = $Margin/Content/SlotsHeader
@onready var skill_rows: VBoxContainer = $Margin/Content/SkillRows

var pending_skill_id: StringName = &""
var cached_core_level: int = -1
var cached_school_id: StringName = &""

func _ready() -> void:
	GameState.school_state_changed.connect(_refresh)
	GameState.school_mastery_changed.connect(_on_mastery_changed)
	GameState.language_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	_rebuild_school_tabs()
	_refresh_header()
	_refresh_available_skills()
	_refresh_slots()
	cached_school_id = GameState.active_school
	cached_core_level = GameState.get_school_core_mastery_level(cached_school_id)

func _on_mastery_changed() -> void:
	var current_school: StringName = GameState.active_school
	var current_core_level: int = GameState.get_school_core_mastery_level(current_school)
	_refresh_header()
	# Rebuild skill list only when unlock thresholds can change.
	if current_school != cached_school_id or current_core_level != cached_core_level:
		_refresh_available_skills()
		cached_school_id = current_school
		cached_core_level = current_core_level

func _rebuild_school_tabs() -> void:
	for child in school_tabs.get_children():
		child.queue_free()
	for school_id in GameState.get_school_ids():
		var def: Dictionary = GameState.get_school_definition(school_id)
		var button := Button.new()
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

	var school_summary := GameState.get_active_school_summary()
	var current_school: StringName = GameState.active_school
	var core_level: int = GameState.get_school_core_mastery_level(current_school)
	var level_floor_xp: int = int(school_summary["current_level_floor_xp"])
	var xp_now: int = int(school_summary["mastery_xp"]) - level_floor_xp
	var next_xp: int = int(school_summary["next_level_xp"]) - level_floor_xp

	school_value_label.text = "%s / %s" % [school_summary["name"], school_summary["core_label"]]
	mastery_value_label.text = ("Ур.%d  XP %d / %d" % [core_level, xp_now, next_xp]) if is_ru else ("Lv.%d  XP %d / %d" % [core_level, xp_now, next_xp])
	current_bonus_value_label.text = _build_current_bonus_text(current_school, core_level, is_ru)
	next_unlock_value_label.text = _build_next_unlock_text(current_school, core_level, is_ru)

func _refresh_available_skills() -> void:
	for child in available_buttons.get_children():
		child.queue_free()

	var school_def: Dictionary = GameState.get_school_definition(GameState.active_school)
	var school_skills: Array = school_def.get("skills", [])
	var core_level: int = GameState.get_school_core_mastery_level(GameState.active_school)
	var equipped_ids: Array[StringName] = GameState.get_equipped_skill_ids()

	for skill_id_any in school_skills:
		var skill_id := skill_id_any as StringName
		var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(skill_id, {})
		var unlock_level: int = int(skill_data.get("unlock_level", 999))
		if core_level < unlock_level:
			continue
		var button := Button.new()
		var equipped: bool = equipped_ids.has(skill_id)
		var text := String(skill_data.get("name", skill_id))
		if pending_skill_id == skill_id:
			text += "  [%s]" % GameState.loc("abilities.selected")
		if equipped:
			text += "  (%s)" % GameState.loc("abilities.state_equipped")
		button.text = text
		button.disabled = equipped
		button.pressed.connect(_on_skill_pressed.bind(skill_id))
		available_buttons.add_child(button)

func _refresh_slots() -> void:
	for child in skill_rows.get_children():
		child.queue_free()
	for slot_index in range(4):
		var slot_button := Button.new()
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_button.text = _build_slot_text(slot_index)
		slot_button.disabled = slot_index >= GameState.get_permanent_skill_slot_count()
		slot_button.pressed.connect(_on_slot_pressed.bind(slot_index))
		skill_rows.add_child(slot_button)

func _build_slot_text(slot_index: int) -> String:
	if slot_index >= GameState.get_permanent_skill_slot_count():
		return "%s %d: %s %d" % [
			GameState.loc("abilities.slot"),
			slot_index + 1,
			GameState.loc("abilities.locked_wave"),
			SchoolRules.SLOT_WAVE_UNLOCKS[slot_index],
		]
	var equipped_skill_ids := GameState.get_equipped_skill_ids()
	var equipped_skill_id: StringName = &""
	if slot_index < equipped_skill_ids.size():
		equipped_skill_id = equipped_skill_ids[slot_index]
	var slot_text := "%s %d: " % [GameState.loc("abilities.slot"), slot_index + 1]
	if equipped_skill_id == &"":
		slot_text += GameState.loc("abilities.empty")
	else:
		var skill_data: Dictionary = SchoolRules.SKILL_DEFINITIONS.get(equipped_skill_id, {})
		slot_text += String(skill_data.get("name", equipped_skill_id))
	if pending_skill_id != &"":
		slot_text += " -> %s" % GameState.loc("abilities.tap_set")
	else:
		slot_text += " -> %s" % GameState.loc("abilities.tap_clear")
	return slot_text

func _build_current_bonus_text(school_id: StringName, core_level: int, is_ru: bool) -> String:
	var bonuses: Dictionary = GameState.get_school_mastery_skill_bonuses(school_id)
	var dmg_pct: float = float(bonuses.get("damage_bonus", 0.0)) * 100.0
	var cd_pct: float = float(bonuses.get("cooldown_reduction", 0.0)) * 100.0
	var proc_pct: float = float(bonuses.get("proc_bonus", 0.0)) * 100.0
	var unique_text: String = String(bonuses.get("unique_bonus_text", ""))
	if is_ru:
		var base_ru := "Текущие бонусы: +%.1f%% урон, -%.1f%% КД, +%.1f%% сила эффектов" % [dmg_pct, cd_pct, proc_pct]
		if unique_text != "":
			base_ru += " | Lv10: " + unique_text
		return base_ru
	var base_en := "Current bonuses: +%.1f%% damage, -%.1f%% cd, +%.1f%% effect power" % [dmg_pct, cd_pct, proc_pct]
	if unique_text != "":
		base_en += " | Lv10: " + unique_text
	return base_en

func _build_next_unlock_text(school_id: StringName, core_level: int, is_ru: bool) -> String:
	var next_level: int = core_level + 1
	var next_reward: String = ""
	match next_level:
		1:
			next_reward = "Открытие 1-го навыка школы" if is_ru else "Unlock 1st school skill"
		2:
			next_reward = "+4% урон навыков" if is_ru else "+4% skill damage"
		3:
			next_reward = "-3% КД навыков" if is_ru else "-3% skill cooldown"
		4:
			next_reward = "Открытие 2-го навыка школы" if is_ru else "Unlock 2nd school skill"
		5:
			next_reward = "Открытие 3-го навыка школы" if is_ru else "Unlock 3rd school skill"
		6:
			next_reward = "+8% сила эффектов школы" if is_ru else "+8% school effect power"
		7:
			next_reward = "-5% КД навыков школы" if is_ru else "-5% school skill cooldown"
		8:
			next_reward = "+10% урон навыков школы" if is_ru else "+10% school skill damage"
		9:
			next_reward = "-5% КД навыков школы" if is_ru else "-5% school skill cooldown"
		10:
			next_reward = "Уникальный бонус школы" if is_ru else "Unique school bonus"
		_:
			next_reward = "+1.5% урон, +1% сила эффектов" if is_ru else "+1.5% damage, +1% effect power"
	return ("Следующий уровень (Lv.%d): %s" % [next_level, next_reward]) if is_ru else ("Next level (Lv.%d): %s" % [next_level, next_reward])

func _on_school_tab_pressed(school_id: StringName) -> void:
	GameState.set_active_school(school_id)
	pending_skill_id = &""
	_refresh()

func _on_skill_pressed(skill_id: StringName) -> void:
	pending_skill_id = skill_id
	_refresh_slots()

func _on_slot_pressed(slot_index: int) -> void:
	if pending_skill_id != &"":
		if GameState.replace_skill(slot_index, pending_skill_id):
			pending_skill_id = &""
		_refresh()
		return
	if GameState.clear_skill_slot(slot_index):
		_refresh_slots()
