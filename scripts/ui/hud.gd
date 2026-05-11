extends CanvasLayer
class_name HUD

@onready var gold_value_label: Label = $Root/Margin/Layout/TopBar/GoldValue
@onready var essence_value_label: Label = $Root/Margin/Layout/TopBar/EssenceValue
@onready var echo_collected_value_label: Label = $Root/Margin/Layout/TopBar/EchoCollectedValue
@onready var echo_power_value_label: Label = $Root/Margin/Layout/TopBar/EchoPowerValue
@onready var dps_value_label: Label = $Root/Margin/Layout/TopBar/DpsValue
@onready var wave_value_label: Label = $Root/Margin/Layout/TopBar/WaveValue
@onready var echo_bonus_value_label: Label = $Root/Margin/Layout/TopBar/EchoActiveBonusValue
@onready var next_echo_bonus_value_label: Label = $Root/Margin/Layout/TopBar/EchoNextBonusValue

func _ready() -> void:
	GameState.resources_changed.connect(_refresh_resources)
	GameState.echo_changed.connect(_refresh_echo)
	GameState.hero_stats_changed.connect(_refresh_dps)
	SignalBus.wave_changed.connect(_refresh_wave)
	_refresh_resources(GameState.gold, GameState.essence)
	_refresh_echo(GameState.echo_collected, GameState.echo_power)
	_refresh_dps()
	_refresh_wave(1)

func _refresh_resources(gold: int, essence: int) -> void:
	gold_value_label.text = str(gold)
	essence_value_label.text = str(essence)

func _refresh_dps() -> void:
	dps_value_label.text = "%.1f" % GameState.get_hero_dps()
	echo_bonus_value_label.text = GameState.get_active_echo_bonus_summary()

func _refresh_wave(current_wave: int) -> void:
	wave_value_label.text = str(current_wave)

func _refresh_echo(current_collected_echo: int, current_echo_power: int) -> void:
	echo_collected_value_label.text = str(current_collected_echo)
	echo_power_value_label.text = str(current_echo_power)
	echo_bonus_value_label.text = GameState.get_active_echo_bonus_summary()
	next_echo_bonus_value_label.text = GameState.get_collected_echo_bonus_summary()
