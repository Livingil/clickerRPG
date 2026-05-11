extends CanvasLayer
class_name HUD

const TAB_SKILLS: StringName = &"skills"
const TAB_UPGRADES: StringName = &"upgrades"
const TAB_RUN: StringName = &"run"

@onready var gold_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/TopRow/GoldValue
@onready var essence_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/TopRow/EssenceValue
@onready var wave_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/TopRow/WaveValue
@onready var dps_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/TopRow/DpsValue
@onready var hp_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/BottomRow/HpValue
@onready var echo_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/BottomRow/EchoValue
@onready var school_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/BottomRow/SchoolValue
@onready var prestige_toggle_button: Button = $Root/HeaderBar/HeaderMargin/HeaderContent/BottomRow/PrestigeToggleButton

@onready var sheet_container: PanelContainer = $Root/BottomSheetContainer
@onready var skills_tab_button: Button = $Root/FooterBar/FooterMargin/FooterButtons/SkillsButton
@onready var upgrades_tab_button: Button = $Root/FooterBar/FooterMargin/FooterButtons/UpgradesButton
@onready var run_tab_button: Button = $Root/FooterBar/FooterMargin/FooterButtons/RunButton

@onready var ability_panel: PanelContainer = $Root/BottomSheetContainer/SheetMargin/TabContentHost/AbilityPanel
@onready var upgrade_panel: PanelContainer = $Root/BottomSheetContainer/SheetMargin/TabContentHost/UpgradePanel
@onready var run_panel: PanelContainer = $Root/BottomSheetContainer/SheetMargin/TabContentHost/RunPanel
@onready var prestige_popup: PanelContainer = $Root/PrestigePopup

var active_tab: StringName = &""
var hero: Hero

func _ready() -> void:
	var gameplay_root := get_parent().get_node_or_null("GameplayRoot")
	if gameplay_root != null:
		hero = gameplay_root.get_node_or_null("Hero") as Hero

	$Root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/HeaderBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/HeaderBar/HeaderMargin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/HeaderBar/HeaderMargin/HeaderContent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/HeaderBar/HeaderMargin/HeaderContent/TopRow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/HeaderBar/HeaderMargin/HeaderContent/BottomRow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/FooterBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/FooterBar/FooterMargin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/FooterBar/FooterMargin/FooterButtons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/BottomSheetContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/BottomSheetContainer/SheetMargin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/BottomSheetContainer/SheetMargin/TabContentHost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/PrestigePopup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skills_tab_button.mouse_filter = Control.MOUSE_FILTER_STOP
	upgrades_tab_button.mouse_filter = Control.MOUSE_FILTER_STOP
	run_tab_button.mouse_filter = Control.MOUSE_FILTER_STOP
	prestige_toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP

	GameState.resources_changed.connect(_refresh_resources)
	GameState.echo_changed.connect(_refresh_echo)
	GameState.hero_stats_changed.connect(_refresh_stats)
	GameState.school_state_changed.connect(_refresh_school_status)
	SignalBus.wave_changed.connect(_refresh_wave)

	skills_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_SKILLS))
	upgrades_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_UPGRADES))
	run_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_RUN))
	prestige_toggle_button.pressed.connect(_toggle_prestige_popup)

	sheet_container.visible = false
	prestige_popup.visible = false
	_set_active_tab(&"")
	_refresh_resources(GameState.gold, GameState.essence)
	_refresh_echo(GameState.echo_collected, GameState.echo_power)
	_refresh_stats()
	_refresh_school_status()
	_refresh_wave(1)

func _process(_delta: float) -> void:
	_refresh_hp()

func _refresh_resources(gold: int, essence: int) -> void:
	gold_value_label.text = "Gold %d" % gold
	essence_value_label.text = "Ess %d" % essence

func _refresh_echo(_collected_echo: int, _active_echo_power: int) -> void:
	echo_value_label.text = "Echo %d | Active %d" % [GameState.echo_collected, GameState.echo_power]

func _refresh_stats() -> void:
	dps_value_label.text = "DPS %.1f" % GameState.get_hero_dps()
	_refresh_hp()

func _refresh_wave(current_wave: int) -> void:
	wave_value_label.text = "Wave %d" % current_wave

func _refresh_hp() -> void:
	if hero == null:
		hp_value_label.text = "HP --"
		return
	hp_value_label.text = "HP %d/%d" % [int(round(hero.hp)), int(round(hero.max_hp))]

func _refresh_school_status() -> void:
	var summary := GameState.get_active_school_summary()
	school_value_label.text = "%s Lv%d S%d/4" % [
		summary["name"],
		summary["mastery_level"],
		GameState.get_permanent_skill_slot_count(),
	]

func _on_tab_pressed(tab_id: StringName) -> void:
	if active_tab == tab_id:
		_set_active_tab(&"")
		return
	_set_active_tab(tab_id)

func _set_active_tab(tab_id: StringName) -> void:
	active_tab = tab_id
	sheet_container.visible = active_tab != &""
	ability_panel.visible = active_tab == TAB_SKILLS
	upgrade_panel.visible = active_tab == TAB_UPGRADES
	run_panel.visible = active_tab == TAB_RUN

	skills_tab_button.button_pressed = active_tab == TAB_SKILLS
	upgrades_tab_button.button_pressed = active_tab == TAB_UPGRADES
	run_tab_button.button_pressed = active_tab == TAB_RUN

func _toggle_prestige_popup() -> void:
	prestige_popup.visible = not prestige_popup.visible
