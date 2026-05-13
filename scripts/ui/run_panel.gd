extends PanelContainer
class_name RunPanel

@onready var wave_value: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/WaveValue
@onready var current_dps_value: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/CurrentDpsValue
@onready var collected_value: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/CollectedValue
@onready var active_value: Label = $Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/ActiveValue

@onready var active_hp: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveHp
@onready var active_dmg: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveDmg
@onready var active_atk: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveAtk
@onready var active_def: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveDef
@onready var active_eva: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveEva
@onready var active_acc: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveAcc
@onready var active_crit: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveCrit
@onready var active_critx: Label = $Margin/Content/Scroll/Body/EchoSection/ActiveBonusGrid/ActiveCritX

@onready var after_hp: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterHp
@onready var after_dmg: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterDmg
@onready var after_atk: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterAtk
@onready var after_def: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterDef
@onready var after_eva: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterEva
@onready var after_acc: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterAcc
@onready var after_crit: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterCrit
@onready var after_critx: Label = $Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusGrid/AfterCritX

@onready var damage_value: Label = $Margin/Content/Scroll/Body/StatsSection/StatsGrid/DamageValue
@onready var attack_speed_value: Label = $Margin/Content/Scroll/Body/StatsSection/StatsGrid/AttackSpeedValue
@onready var dps_value: Label = $Margin/Content/Scroll/Body/StatsSection/StatsGrid/DpsValue
@onready var hp_value: Label = $Margin/Content/Scroll/Body/StatsSection/StatsGrid/HpValue
@onready var crit_chance_value: Label = $Margin/Content/Scroll/Body/StatsSection/StatsGrid/CritChanceValue
@onready var crit_mult_value: Label = $Margin/Content/Scroll/Body/StatsSection/StatsGrid/CritMultValue
@onready var defense_value: Label = $Margin/Content/Scroll/Body/StatsSection/StatsGrid/DefenseValue
@onready var evasion_value: Label = $Margin/Content/Scroll/Body/StatsSection/StatsGrid/EvasionValue
@onready var accuracy_value: Label = $Margin/Content/Scroll/Body/StatsSection/StatsGrid/AccuracyValue
@onready var body: VBoxContainer = $Margin/Content/Scroll/Body

var milestone_challenge_row: HBoxContainer
var milestone_challenge_label: Label
var milestone_retry_button: Button

func _ready() -> void:
	$Margin/Content/Scroll/Body/Sep2.visible = false
	$Margin/Content/Scroll/Body/StatsSection.visible = false
	_setup_milestone_challenge_row()
	GameState.echo_changed.connect(_refresh)
	GameState.hero_stats_changed.connect(_refresh)
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

	active_hp.text = "HP +%.0f" % GameState.get_active_echo_hp_bonus()
	active_dmg.text = "DMG +%.1f" % GameState.get_active_echo_damage_bonus()
	active_atk.text = "ATK +%.2f" % GameState.get_active_echo_attack_speed_bonus()
	active_def.text = "DEF +%.1f" % GameState.get_active_echo_defense_bonus()
	active_eva.text = "EVA +%.1f" % GameState.get_active_echo_evasion_bonus()
	active_acc.text = "ACC +%.1f" % GameState.get_active_echo_accuracy_bonus()
	active_crit.text = "CRIT +%.2f%%" % (GameState.get_active_echo_crit_chance_bonus() * 100.0)
	active_critx.text = "CRITx +%.2f" % GameState.get_active_echo_crit_multiplier_bonus()

	after_hp.text = "HP +%.0f" % GameState.get_collected_echo_hp_bonus()
	after_dmg.text = "DMG +%.1f" % GameState.get_collected_echo_damage_bonus()
	after_atk.text = "ATK +%.2f" % GameState.get_collected_echo_attack_speed_bonus()
	after_def.text = "DEF +%.1f" % GameState.get_collected_echo_defense_bonus()
	after_eva.text = "EVA +%.1f" % GameState.get_collected_echo_evasion_bonus()
	after_acc.text = "ACC +%.1f" % GameState.get_collected_echo_accuracy_bonus()
	after_crit.text = "CRIT +%.2f%%" % (GameState.get_collected_echo_crit_chance_bonus() * 100.0)
	after_critx.text = "CRITx +%.2f" % GameState.get_collected_echo_crit_multiplier_bonus()

	var is_ru: bool = GameState.current_language == &"ru"
	var active_info: Dictionary = GameState.get_echo_progress_info(GameState.echo_power)
	var active_left: int = int(active_info.get("remaining_to_next", 0))
	if is_ru:
		$Margin/Content/Scroll/Body/EchoSection/ActiveBonusTitle.text = "Активный бонус"
		$Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusTitle.text = "Бонус после смерти | До следующего бонуса: " + str(active_left) + " эхо"
	else:
		$Margin/Content/Scroll/Body/EchoSection/ActiveBonusTitle.text = "Active Bonus"
		$Margin/Content/Scroll/Body/EchoSection/AfterDeathBonusTitle.text = "After Death Bonus | To next bonus: " + str(active_left) + " echo"

func _apply_localized_labels() -> void:
	$Margin/Content/Title.text = GameState.loc("run.title")
	$Margin/Content/Scroll/Body/OverviewSection/OverviewHeader.text = GameState.loc("run.overview")
	$Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/WaveKey.text = GameState.loc("run.wave_record")
	$Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/CurrentDpsKey.text = GameState.loc("run.current_dps")
	$Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/CollectedKey.text = GameState.loc("run.echo_collected")
	$Margin/Content/Scroll/Body/OverviewSection/OverviewGrid/ActiveKey.text = GameState.loc("run.echo_active")
	$Margin/Content/Scroll/Body/EchoSection/EchoHeader.text = GameState.loc("run.echo")

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
