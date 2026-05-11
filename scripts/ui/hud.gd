extends CanvasLayer
class_name HUD

@onready var gold_value_label: Label = $Root/Margin/Layout/TopBar/GoldValue
@onready var essence_value_label: Label = $Root/Margin/Layout/TopBar/EssenceValue
@onready var dps_value_label: Label = $Root/Margin/Layout/TopBar/DpsValue
@onready var wave_value_label: Label = $Root/Margin/Layout/TopBar/WaveValue

func _ready() -> void:
	GameState.resources_changed.connect(_refresh_resources)
	GameState.hero_stats_changed.connect(_refresh_dps)
	SignalBus.wave_changed.connect(_refresh_wave)
	_refresh_resources(GameState.gold, GameState.essence)
	_refresh_dps()
	_refresh_wave(1)

func _refresh_resources(gold: int, essence: int) -> void:
	gold_value_label.text = str(gold)
	essence_value_label.text = str(essence)

func _refresh_dps() -> void:
	dps_value_label.text = "%.1f" % GameState.get_hero_dps()

func _refresh_wave(current_wave: int) -> void:
	wave_value_label.text = str(current_wave)
