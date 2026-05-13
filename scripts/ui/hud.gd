extends CanvasLayer
class_name HUD

const TAB_SKILLS: StringName = &"skills"
const TAB_UPGRADES: StringName = &"upgrades"
const TAB_RUN: StringName = &"run"
const CHALLENGE_TIME_LIMIT: float = 30.0
const DEV_PREVIEW_TIMER_KEY: Key = KEY_F6

@onready var gold_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/TopRow/GoldValue
@onready var essence_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/TopRow/EssenceValue
@onready var wave_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/TopRow/WaveValue
@onready var dps_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/TopRow/DpsValue
@onready var settings_button: Button = $Root/HeaderBar/HeaderMargin/HeaderContent/TopRow/SettingsButton
@onready var hp_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/BottomRow/HpValue
@onready var echo_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/BottomRow/EchoValue
@onready var school_value_label: Label = $Root/HeaderBar/HeaderMargin/HeaderContent/BottomRow/SchoolValue
@onready var prestige_toggle_button: Button = $Root/HeaderBar/HeaderMargin/HeaderContent/BottomRow/PrestigeToggleButton
@onready var challenge_timer_layer: Control = $Root/ChallengeTimerLayer
@onready var challenge_timer_bar: ProgressBar = $Root/ChallengeTimerLayer/TimerBar
@onready var challenge_timer_label: Label = $Root/ChallengeTimerLayer/TimerLabel
@onready var retry_boss_button: Button = $Root/RetryBossButton

@onready var sheet_container: PanelContainer = $Root/BottomSheetContainer
@onready var skills_tab_button: Button = $Root/FooterBar/FooterMargin/FooterButtons/SkillsButton
@onready var upgrades_tab_button: Button = $Root/FooterBar/FooterMargin/FooterButtons/UpgradesButton
@onready var run_tab_button: Button = $Root/FooterBar/FooterMargin/FooterButtons/RunButton

@onready var ability_panel: PanelContainer = $Root/BottomSheetContainer/SheetMargin/TabContentHost/AbilityPanel
@onready var upgrade_panel: PanelContainer = $Root/BottomSheetContainer/SheetMargin/TabContentHost/UpgradePanel
@onready var run_panel: PanelContainer = $Root/BottomSheetContainer/SheetMargin/TabContentHost/RunPanel
@onready var prestige_popup: PanelContainer = $Root/PrestigePopup
@onready var settings_popup: PanelContainer = $Root/SettingsPopup
@onready var language_label: Label = $Root/SettingsPopup/Margin/Content/LanguageRow/LanguageLabel
@onready var language_option: OptionButton = $Root/SettingsPopup/Margin/Content/LanguageRow/LanguageOption
@onready var damage_toggle: CheckButton = $Root/SettingsPopup/Margin/Content/DamageToggle
@onready var crit_toggle: CheckButton = $Root/SettingsPopup/Margin/Content/CritToggle
@onready var miss_toggle: CheckButton = $Root/SettingsPopup/Margin/Content/MissToggle
@onready var hero_damage_toggle: CheckButton = $Root/SettingsPopup/Margin/Content/HeroDamageToggle
@onready var hero_miss_toggle: CheckButton = $Root/SettingsPopup/Margin/Content/HeroMissToggle
@onready var settings_summary_label: Label = $Root/SettingsPopup/Margin/Content/Summary
@onready var sim_button: Button = $Root/SettingsPopup/Margin/Content/SimButton
@onready var sim_result_label: Label = $Root/SettingsPopup/Margin/Content/SimScroll/SimResult
@onready var sim_report_popup: PanelContainer = $Root/SimReportPopup
@onready var sim_report_title: Label = $Root/SimReportPopup/Margin/Content/TopRow/Title
@onready var sim_report_close_button: Button = $Root/SimReportPopup/Margin/Content/TopRow/CloseButton
@onready var sim_report_rich_text: RichTextLabel = $Root/SimReportPopup/Margin/Content/ReportScroll/ReportRichText

var active_tab: StringName = &""
var hero: Hero
var dev_preview_timer_active: bool = false
var dev_preview_time_left: float = 0.0
var hp_refresh_accumulator: float = 0.0

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
	$Root/ChallengeTimerLayer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/ChallengeTimerLayer/TimerBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/ChallengeTimerLayer/TimerLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/RetryBossButton.mouse_filter = Control.MOUSE_FILTER_STOP
	$Root/FooterBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/FooterBar/FooterMargin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/FooterBar/FooterMargin/FooterButtons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/BottomSheetContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/BottomSheetContainer/SheetMargin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/BottomSheetContainer/SheetMargin/TabContentHost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/PrestigePopup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/SettingsPopup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root/SimReportPopup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skills_tab_button.mouse_filter = Control.MOUSE_FILTER_STOP
	upgrades_tab_button.mouse_filter = Control.MOUSE_FILTER_STOP
	run_tab_button.mouse_filter = Control.MOUSE_FILTER_STOP
	prestige_toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
	language_option.mouse_filter = Control.MOUSE_FILTER_STOP
	damage_toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	crit_toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	miss_toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	hero_damage_toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	hero_miss_toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	sim_button.mouse_filter = Control.MOUSE_FILTER_STOP
	sim_report_close_button.mouse_filter = Control.MOUSE_FILTER_STOP

	GameState.resources_changed.connect(_refresh_resources)
	GameState.echo_changed.connect(_refresh_echo)
	GameState.hero_stats_changed.connect(_refresh_stats)
	GameState.school_state_changed.connect(_refresh_school_status)
	GameState.school_mastery_changed.connect(_refresh_school_status)
	GameState.combat_text_settings_changed.connect(_refresh_combat_text_settings)
	GameState.language_changed.connect(_refresh_localized_texts)
	SignalBus.wave_changed.connect(_refresh_wave)
	SignalBus.milestone_challenge_state_changed.connect(_on_milestone_challenge_state_changed)

	skills_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_SKILLS))
	upgrades_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_UPGRADES))
	run_tab_button.pressed.connect(_on_tab_pressed.bind(TAB_RUN))
	prestige_toggle_button.pressed.connect(_toggle_prestige_popup)
	settings_button.pressed.connect(_toggle_settings_popup)
	language_option.item_selected.connect(_on_language_selected)
	damage_toggle.toggled.connect(_on_combat_toggle_changed)
	crit_toggle.toggled.connect(_on_combat_toggle_changed)
	miss_toggle.toggled.connect(_on_combat_toggle_changed)
	hero_damage_toggle.toggled.connect(_on_combat_toggle_changed)
	hero_miss_toggle.toggled.connect(_on_combat_toggle_changed)
	sim_button.pressed.connect(_run_balance_sim)
	sim_report_close_button.pressed.connect(_close_sim_report)
	retry_boss_button.pressed.connect(_on_retry_boss_pressed)

	sheet_container.visible = false
	prestige_popup.visible = false
	settings_popup.visible = false
	sim_report_popup.visible = false
	challenge_timer_layer.visible = false
	retry_boss_button.visible = false
	challenge_timer_bar.min_value = 0.0
	challenge_timer_bar.max_value = CHALLENGE_TIME_LIMIT
	challenge_timer_bar.value = CHALLENGE_TIME_LIMIT
	challenge_timer_label.text = "30с"
	_set_active_tab(&"")
	_refresh_resources(GameState.gold, GameState.essence)
	_refresh_echo(GameState.echo_collected, GameState.echo_power)
	_refresh_stats()
	_refresh_school_status()
	_refresh_wave(1)
	_setup_language_options()
	_refresh_localized_texts()

func _process(_delta: float) -> void:
	if dev_preview_timer_active:
		dev_preview_time_left = maxf(0.0, dev_preview_time_left - _delta)
		_on_milestone_challenge_state_changed(true, dev_preview_time_left, 0, false)
		if dev_preview_time_left <= 0.0:
			dev_preview_timer_active = false
			_on_milestone_challenge_state_changed(false, 0.0, 0, false)
	hp_refresh_accumulator += _delta
	if hp_refresh_accumulator >= 0.1:
		hp_refresh_accumulator = 0.0
		_refresh_hp()

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == DEV_PREVIEW_TIMER_KEY:
			dev_preview_timer_active = true
			dev_preview_time_left = CHALLENGE_TIME_LIMIT
			_on_milestone_challenge_state_changed(true, dev_preview_time_left, 0, false)

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

func _on_milestone_challenge_state_changed(active: bool, time_left: float, _wave: int, _retry_available: bool) -> void:
	if not active:
		challenge_timer_layer.visible = false
		retry_boss_button.visible = _retry_available
		return
	challenge_timer_layer.visible = true
	retry_boss_button.visible = false
	var clamped_left: float = clampf(time_left, 0.0, CHALLENGE_TIME_LIMIT)
	challenge_timer_bar.value = clamped_left
	if GameState.current_language == &"ru":
		challenge_timer_label.text = "%dс" % int(ceil(clamped_left))
	else:
		challenge_timer_label.text = "%ds" % int(ceil(clamped_left))

func _on_retry_boss_pressed() -> void:
	SignalBus.emit_milestone_challenge_retry_requested()

func _refresh_hp() -> void:
	if hero == null:
		hp_value_label.text = "HP --"
		return
	hp_value_label.text = "HP %d/%d" % [int(round(hero.hp)), int(round(hero.max_hp))]

func _refresh_school_status() -> void:
	var summary := GameState.get_active_school_summary()
	var level_xp := int(summary["mastery_xp"]) - int(summary["current_level_floor_xp"])
	var next_level_xp := int(summary["next_level_xp"]) - int(summary["current_level_floor_xp"])
	school_value_label.text = "%s Lv%d XP %d/%d" % [
		summary["name"],
		summary["mastery_level"],
		level_xp,
		next_level_xp,
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

func _toggle_settings_popup() -> void:
	settings_popup.visible = not settings_popup.visible

func _on_combat_toggle_changed(_value: bool) -> void:
	GameState.set_combat_text_settings(
		damage_toggle.button_pressed,
		crit_toggle.button_pressed,
		miss_toggle.button_pressed,
		hero_damage_toggle.button_pressed,
		hero_miss_toggle.button_pressed
	)

func _refresh_combat_text_settings() -> void:
	damage_toggle.set_pressed_no_signal(GameState.show_damage_text)
	crit_toggle.set_pressed_no_signal(GameState.show_crit_text)
	miss_toggle.set_pressed_no_signal(GameState.show_miss_text)
	hero_damage_toggle.set_pressed_no_signal(GameState.show_hero_damage_text)
	hero_miss_toggle.set_pressed_no_signal(GameState.show_hero_miss_text)
	var on_text := GameState.loc("ui.on")
	var off_text := GameState.loc("ui.off")
	var enemy_line := GameState.loc("ui.enemy_summary") % [
		on_text if GameState.show_damage_text else off_text,
		on_text if GameState.show_crit_text else off_text,
		on_text if GameState.show_miss_text else off_text,
	]
	var hero_line := GameState.loc("ui.hero_summary") % [
		on_text if GameState.show_hero_damage_text else off_text,
		on_text if GameState.show_hero_miss_text else off_text,
	]
	settings_summary_label.text = "%s\n%s" % [enemy_line, hero_line]

func _setup_language_options() -> void:
	language_option.clear()
	language_option.add_item("Русский")
	language_option.set_item_metadata(0, &"ru")
	language_option.add_item("English")
	language_option.set_item_metadata(1, &"en")
	_select_current_language_option()

func _on_language_selected(index: int) -> void:
	var language_code_str := String(language_option.get_item_metadata(index))
	var language_code: StringName = StringName(language_code_str)
	GameState.set_language(language_code)
	_select_current_language_option()

func _select_current_language_option() -> void:
	for index in range(language_option.item_count):
		var language_code := language_option.get_item_metadata(index) as StringName
		if language_code == GameState.current_language:
			language_option.select(index)
			return

func _refresh_localized_texts() -> void:
	settings_button.text = GameState.loc("ui.settings")
	skills_tab_button.text = GameState.loc("ui.skills")
	upgrades_tab_button.text = GameState.loc("ui.upgrades")
	run_tab_button.text = GameState.loc("ui.run")
	prestige_toggle_button.text = GameState.loc("ui.prestige")
	language_label.text = GameState.loc("ui.language")
	$Root/SettingsPopup/Margin/Content/Title.text = GameState.loc("ui.combat_text")
	damage_toggle.text = GameState.loc("ui.show_damage")
	crit_toggle.text = GameState.loc("ui.show_crit")
	miss_toggle.text = GameState.loc("ui.show_miss")
	hero_damage_toggle.text = GameState.loc("ui.show_hero_damage")
	hero_miss_toggle.text = GameState.loc("ui.show_hero_miss")
	sim_button.text = "Запустить Симуляцию Баланса" if GameState.current_language == &"ru" else "Run Balance Sim"
	retry_boss_button.text = "Вызвать босса" if GameState.current_language == &"ru" else "Summon Boss"
	sim_report_title.text = "Отчет Симуляции Баланса" if GameState.current_language == &"ru" else "Balance Simulation Report"
	sim_report_close_button.text = "Закрыть" if GameState.current_language == &"ru" else "Close"
	if sim_result_label.text.is_empty():
		sim_result_label.text = "Здесь будет отчет симуляции." if GameState.current_language == &"ru" else "Simulation report will appear here."
	_refresh_combat_text_settings()

func _run_balance_sim() -> void:
	var rows := GameState.run_balance_simulation(2000, 200)
	if rows.is_empty():
		sim_result_label.text = "Нет данных симуляции." if GameState.current_language == &"ru" else "No simulation data."
		return

	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % ("Баланс-отчет" if GameState.current_language == &"ru" else "Balance Report"))
	lines.append("")
	lines.append("[b]Wave | DPS | TTK Normal | TTK Apex | Echo | Gold[/b]")
	for row_data in rows:
		var wave: int = int(row_data.get("wave", 0))
		var hero_dps: float = float(row_data.get("hero_dps", 0.0))
		var normal_ttk: float = float(row_data.get("normal_ttk", 0.0))
		var apex_ttk: float = float(row_data.get("apex_ttk", 0.0))
		var echo_power: int = int(row_data.get("echo_power", 0))
		var gold_now: int = int(row_data.get("gold", 0))
		lines.append(
			("W%d | %.1f | %.2fs | %.2fs | %d | %d" % [wave, hero_dps, normal_ttk, apex_ttk, echo_power, gold_now])
		)

	var last := rows[rows.size() - 1]
	var eq: Dictionary = last.get("equip", {})
	lines.append("")
	lines.append("[b]Final State[/b]")
	lines.append(
		("Eq: W%d H%d C%d G%d B%d R%d A%d Re%d" % [
			int(eq.get(&"weapon", 0)),
			int(eq.get(&"helm", 0)),
			int(eq.get(&"chest", 0)),
			int(eq.get(&"gloves", 0)),
			int(eq.get(&"boots", 0)),
			int(eq.get(&"ring", 0)),
			int(eq.get(&"amulet", 0)),
			int(eq.get(&"relic", 0)),
		])
	)
	lines.append(
		("Artifacts: %d owned / total levels %d" % [
			int(last.get("artifacts_owned", 0)),
			int(last.get("artifact_levels", 0)),
		])
	)
	sim_report_rich_text.clear()
	sim_report_rich_text.text = "\n".join(lines)
	sim_report_popup.visible = true
	settings_popup.visible = false

func _close_sim_report() -> void:
	sim_report_popup.visible = false
