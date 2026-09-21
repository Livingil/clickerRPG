extends RefCounted
class_name HudPanelRouter

const TAB_SKILLS: StringName = &"skills"
const TAB_UPGRADES: StringName = &"upgrades"
const TAB_RUN: StringName = &"run"

var active_tab: StringName = &""
var sheet_container: Control
var ability_panel: Control
var upgrade_panel: Control
var run_panel: Control
var prestige_popup: Control
var settings_popup: Control
var skills_tab_button: Button
var upgrades_tab_button: Button
var run_tab_button: Button

func configure(
	p_sheet_container: Control,
	p_ability_panel: Control,
	p_upgrade_panel: Control,
	p_run_panel: Control,
	p_prestige_popup: Control,
	p_settings_popup: Control,
	p_skills_tab_button: Button,
	p_upgrades_tab_button: Button,
	p_run_tab_button: Button
) -> void:
	sheet_container = p_sheet_container
	ability_panel = p_ability_panel
	upgrade_panel = p_upgrade_panel
	run_panel = p_run_panel
	prestige_popup = p_prestige_popup
	settings_popup = p_settings_popup
	skills_tab_button = p_skills_tab_button
	upgrades_tab_button = p_upgrades_tab_button
	run_tab_button = p_run_tab_button

func set_active_tab(tab_id: StringName) -> void:
	active_tab = tab_id
	if sheet_container != null:
		sheet_container.visible = active_tab != &""
	if ability_panel != null:
		ability_panel.visible = active_tab == TAB_SKILLS
	if upgrade_panel != null:
		upgrade_panel.visible = active_tab == TAB_UPGRADES
	if run_panel != null:
		run_panel.visible = active_tab == TAB_RUN

	if skills_tab_button != null:
		skills_tab_button.button_pressed = active_tab == TAB_SKILLS
	if upgrades_tab_button != null:
		upgrades_tab_button.button_pressed = active_tab == TAB_UPGRADES
	if run_tab_button != null:
		run_tab_button.button_pressed = active_tab == TAB_RUN

func toggle_tab(tab_id: StringName) -> void:
	if active_tab == tab_id:
		set_active_tab(&"")
		return
	set_active_tab(tab_id)

func toggle_prestige_popup() -> void:
	if prestige_popup == null:
		return
	var should_open: bool = not prestige_popup.visible
	prestige_popup.visible = should_open
	if should_open:
		close_settings_popup()

func toggle_settings_popup() -> void:
	if settings_popup == null:
		return
	var should_open: bool = not settings_popup.visible
	settings_popup.visible = should_open
	if should_open:
		close_prestige_popup()

func open_prestige_popup() -> void:
	if prestige_popup != null:
		prestige_popup.visible = true
	close_settings_popup()

func close_prestige_popup() -> void:
	if prestige_popup != null:
		prestige_popup.visible = false

func close_settings_popup() -> void:
	if settings_popup != null:
		settings_popup.visible = false
