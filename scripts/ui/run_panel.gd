extends PanelContainer
class_name RunPanel

@onready var title_label: Label = $Margin/Content/Title
@onready var content: VBoxContainer = $Margin/Content
@onready var run_scroll: ScrollContainer = $Margin/Content/Scroll
@onready var body: VBoxContainer = $Margin/Content/Scroll/Body
@onready var overview_header: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewHeader
@onready var wave_key: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/WaveKey
@onready var wave_value: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/WaveValue
@onready var current_dps_key: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/CurrentDpsKey
@onready var current_dps_value: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/CurrentDpsValue
@onready var collected_key: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/CollectedKey
@onready var collected_value: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/CollectedValue
@onready var active_key: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/ActiveKey
@onready var active_value: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/ActiveValue

@onready var echo_header: Label = $Margin/Content/Scroll/Body/EchoSection/EchoHeader
@onready var active_bonus_title: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusTitle
@onready var active_hp: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveHp
@onready var active_dmg: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveDmg
@onready var active_atk: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveAtk
@onready var active_def: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveDef
@onready var active_eva: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveEva
@onready var active_acc: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveAcc
@onready var active_crit: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveCrit
@onready var active_critx: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveCritX

@onready var after_death_bonus_title: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusTitle
@onready var after_hp: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterHp
@onready var after_dmg: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterDmg
@onready var after_atk: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterAtk
@onready var after_def: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterDef
@onready var after_eva: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterEva
@onready var after_acc: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterAcc
@onready var after_crit: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterCrit
@onready var after_critx: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterCritX

var milestone_challenge_row: HBoxContainer
var milestone_challenge_label: Label
var milestone_retry_button: Button
var tabs: TabContainer
var stats_rows: VBoxContainer

func _ready() -> void:
	_setup_statistics_tabs()
	$Margin/Content/Tabs/RunTab/Body/Sep2.visible = false
	$Margin/Content/Tabs/RunTab/Body/StatsSection.visible = false
	_setup_milestone_challenge_row()
	GameState.echo_changed.connect(_refresh)
	GameState.hero_stats_changed.connect(_refresh)
	GameState.upgrades_changed.connect(_refresh)
	SignalBus.wave_changed.connect(_refresh)
	SignalBus.milestone_challenge_state_changed.connect(_on_milestone_challenge_state_changed)
	GameState.language_changed.connect(_refresh)
	_refresh()

func _refresh(_arg0: Variant = null, _arg1: Variant = null) -> void:
	var stats := GameState.build_hero_stats()
	_apply_localized_labels()

	wave_value.text = str(GameState.highest_wave_reached)
	current_dps_value.text = "%.1f" % stats.compute_dps()
	collected_value.text = str(GameState.echo_collected)
	active_value.text = str(GameState.echo_power)

	_apply_echo_bonus_labels(GameState.get_active_echo_bonuses(), true)
	_apply_echo_bonus_labels(GameState.get_collected_echo_bonuses(), false)

	var active_info: Dictionary = GameState.get_echo_progress_info(GameState.echo_power)
	var active_left: int = int(active_info.get("remaining_to_next", 0))
	if GameState.current_language == &"ru":
		active_bonus_title.text = "Активный бонус"
		after_death_bonus_title.text = "Бонус после смерти | До следующего бонуса: " + str(active_left) + " эхо"
	else:
		active_bonus_title.text = "Active Bonus"
		after_death_bonus_title.text = "After Death Bonus | To next bonus: " + str(active_left) + " echo"

	_build_stats_tab(stats)

func _apply_echo_bonus_labels(bonuses: Dictionary, active: bool) -> void:
	var hp_label: Label = active_hp if active else after_hp
	var dmg_label: Label = active_dmg if active else after_dmg
	var atk_label: Label = active_atk if active else after_atk
	var def_label: Label = active_def if active else after_def
	var eva_label: Label = active_eva if active else after_eva
	var acc_label: Label = active_acc if active else after_acc
	var crit_label: Label = active_crit if active else after_crit
	var critx_label: Label = active_critx if active else after_critx
	hp_label.text = "HP +%.0f" % float(bonuses.get("max_hp", 0.0))
	dmg_label.text = "DMG +%.1f" % float(bonuses.get("damage", 0.0))
	atk_label.text = "ATK +%.2f" % float(bonuses.get("attack_speed", 0.0))
	def_label.text = "DEF +%.1f" % float(bonuses.get("defense", 0.0))
	eva_label.text = "EVA +%.1f" % float(bonuses.get("evasion", 0.0))
	acc_label.text = "ACC +%.1f" % float(bonuses.get("accuracy", 0.0))
	crit_label.text = "CRIT +%.2f%%" % (float(bonuses.get("crit_chance", 0.0)) * 100.0)
	critx_label.text = "CRITx +%.2f" % float(bonuses.get("crit_multiplier", 0.0))

func _setup_statistics_tabs() -> void:
	tabs = TabContainer.new()
	tabs.name = "Tabs"
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll_index: int = content.get_children().find(run_scroll)
	content.remove_child(run_scroll)
	content.add_child(tabs)
	if scroll_index >= 0:
		content.move_child(tabs, scroll_index)

	run_scroll.name = "RunTab"
	run_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(run_scroll)

	var stats_scroll := ScrollContainer.new()
	stats_scroll.name = "StatsTab"
	stats_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(stats_scroll)

	stats_rows = VBoxContainer.new()
	stats_rows.name = "StatsRows"
	stats_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_rows.add_theme_constant_override("separation", 8)
	stats_scroll.add_child(stats_rows)

func _apply_localized_labels() -> void:
	title_label.text = GameState.loc("run.title")
	overview_header.text = GameState.loc("run.overview")
	wave_key.text = GameState.loc("run.wave_record")
	current_dps_key.text = GameState.loc("run.current_dps")
	collected_key.text = GameState.loc("run.echo_collected")
	active_key.text = GameState.loc("run.echo_active")
	echo_header.text = GameState.loc("run.echo")
	if tabs != null:
		tabs.set_tab_title(0, GameState.loc("run.run_tab"))
		tabs.set_tab_title(1, GameState.loc("run.stats_tab"))

func _build_stats_tab(stats: CombatStats) -> void:
	if stats_rows == null:
		return
	_clear_container(stats_rows)
	var is_ru: bool = GameState.current_language == &"ru"

	var meta_header := Label.new()
	meta_header.text = "Прогресс забега" if is_ru else "Run Progress"
	stats_rows.add_child(meta_header)

	var meta_grid := GridContainer.new()
	meta_grid.columns = 2
	meta_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	meta_grid.add_theme_constant_override("h_separation", 8)
	meta_grid.add_theme_constant_override("v_separation", 4)
	_add_stat_row(meta_grid, GameState.loc("run.wave_record"), str(GameState.highest_wave_reached))
	_add_stat_row(meta_grid, "Количество смертей" if is_ru else "Deaths", str(GameState.total_deaths))
	_add_stat_row(meta_grid, "Рекорд времени забега" if is_ru else "Best Run Time", GameState.format_duration_short(GameState.best_run_time_sec))
	stats_rows.add_child(meta_grid)

	stats_rows.add_child(HSeparator.new())

	var header := Label.new()
	header.text = GameState.loc("run.hero_stats")
	stats_rows.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)

	var atk_runtime_mult: float = GameState.get_runtime_attack_speed_multiplier()
	var clone_mult: float = GameState.get_clone_attack_multiplier()
	var real_attack_speed: float = stats.attack_speed * atk_runtime_mult
	var real_dps: float = stats.compute_dps() * atk_runtime_mult * (1.0 + clone_mult)

	_add_stat_row(grid, GameState.loc("stat.damage"), "%.1f" % stats.damage)
	_add_stat_row(grid, GameState.loc("stat.attack_speed"), "%.2f" % real_attack_speed)
	_add_stat_row(grid, GameState.loc("stat.dps"), "%.1f" % real_dps)
	_add_stat_row(grid, GameState.loc("stat.max_hp"), "%.0f" % stats.max_hp)
	_add_stat_row(grid, GameState.loc("stat.move_speed"), "%.0f" % GameState.get_hero_move_speed())
	_add_stat_row(grid, "Реген HP" if is_ru else "HP Regen", "%.2f/s %.3f%%" % [
		GameState.get_hero_hp_regen_per_sec(stats.max_hp),
		GameState.get_chest_hp_regen_percent_per_sec() * 100.0,
	])
	_add_stat_row(grid, GameState.loc("stat.crit_chance"), "%.2f%%" % (stats.crit_chance * 100.0))
	_add_stat_row(grid, GameState.loc("stat.crit_mult"), "%.2fx" % stats.crit_multiplier)
	_add_stat_row(grid, GameState.loc("stat.defense"), "%.1f" % stats.defense)
	_add_stat_row(grid, GameState.loc("stat.evasion"), "%.1f" % stats.evasion)
	_add_stat_row(grid, GameState.loc("stat.accuracy"), "%.1f" % stats.accuracy)
	stats_rows.add_child(grid)

	var combat_header := Label.new()
	combat_header.text = "Боевые модификаторы" if is_ru else "Combat Modifiers"
	stats_rows.add_child(combat_header)
	var combat_grid := GridContainer.new()
	combat_grid.columns = 2
	combat_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	combat_grid.add_theme_constant_override("h_separation", 8)
	combat_grid.add_theme_constant_override("v_separation", 4)
	_add_stat_row(combat_grid, "Скорость атаки (x)" if is_ru else "Attack Speed (x)", "%.2f" % atk_runtime_mult)
	_add_stat_row(combat_grid, "Клон (x урон)" if is_ru else "Clone (x dmg)", "%.2f" % (1.0 + clone_mult))
	stats_rows.add_child(combat_grid)

	var school_header := Label.new()
	school_header.text = "Бонусы активной школы" if is_ru else "Active School Bonuses"
	stats_rows.add_child(school_header)
	var school_grid := GridContainer.new()
	school_grid.columns = 2
	school_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	school_grid.add_theme_constant_override("h_separation", 8)
	school_grid.add_theme_constant_override("v_separation", 4)
	var school_bonus: Dictionary = GameState.get_school_mastery_skill_bonuses(GameState.active_school)
	_add_stat_row(school_grid, "Урон навыков" if is_ru else "Skill Damage", "+%.1f%%" % (float(school_bonus.get("damage_bonus", 0.0)) * 100.0))
	_add_stat_row(school_grid, "Снижение КД" if is_ru else "Cooldown Reduction", "-%.1f%%" % (float(school_bonus.get("cooldown_reduction", 0.0)) * 100.0))
	_add_stat_row(school_grid, "Сила эффектов" if is_ru else "Effect Power", "+%.1f%%" % (float(school_bonus.get("proc_bonus", 0.0)) * 100.0))
	var unique_text: String = String(school_bonus.get("unique_bonus_text", ""))
	if not unique_text.is_empty():
		_add_stat_row(school_grid, "Уникальный бонус" if is_ru else "Unique Bonus", unique_text)
	stats_rows.add_child(school_grid)

func _add_stat_row(grid: GridContainer, key_text: String, value_text: String) -> void:
	var key_label := Label.new()
	key_label.text = key_text
	key_label.custom_minimum_size = Vector2(170.0, 0.0)
	key_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var value_label := Label.new()
	value_label.text = value_text
	value_label.custom_minimum_size = Vector2(126.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.clip_text = true
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	grid.add_child(key_label)
	grid.add_child(value_label)

func _setup_milestone_challenge_row() -> void:
	milestone_challenge_row = HBoxContainer.new()
	milestone_challenge_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestone_challenge_label = Label.new()
	milestone_challenge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestone_challenge_label.text = ""
	milestone_retry_button = Button.new()
	milestone_retry_button.text = "Вызвать Босса Снова" if GameState.current_language == &"ru" else "Retry Boss"
	milestone_retry_button.visible = false
	milestone_retry_button.pressed.connect(_on_retry_milestone_pressed)
	milestone_challenge_row.add_child(milestone_challenge_label)
	milestone_challenge_row.add_child(milestone_retry_button)
	body.add_child(milestone_challenge_row)

func _on_milestone_challenge_state_changed(active: bool, time_left: float, wave: int, retry_available: bool) -> void:
	if milestone_challenge_row == null:
		return
	if active:
		var title := "Таймер Босса" if GameState.current_language == &"ru" else "Boss Timer"
		milestone_challenge_label.text = "%s W%d: %.1fс" % [title, wave, time_left] if GameState.current_language == &"ru" else "%s W%d: %.1fs" % [title, wave, time_left]
		milestone_retry_button.visible = false
		return
	if retry_available:
		milestone_challenge_label.text = "Босс не побежден вовремя. Можно вызвать снова." if GameState.current_language == &"ru" else "Boss challenge failed. You can retry."
		milestone_retry_button.text = "Вызвать Босса Снова" if GameState.current_language == &"ru" else "Retry Boss"
		milestone_retry_button.visible = true
		return
	milestone_challenge_label.text = ""
	milestone_retry_button.visible = false

func _on_retry_milestone_pressed() -> void:
	SignalBus.emit_milestone_challenge_retry_requested()

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
