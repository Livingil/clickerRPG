extends PanelContainer
class_name PrestigePanel

@onready var hint_label: Label = $Margin/Content/Hint
@onready var echo_status_label: Label = $Margin/Content/EchoStatus
@onready var prestige_button: Button = $Margin/Content/PrestigeButton

func _ready() -> void:
	GameState.echo_changed.connect(_on_echo_changed)
	GameState.hero_stats_changed.connect(_refresh)
	prestige_button.pressed.connect(_on_prestige_pressed)
	_refresh()

func _refresh() -> void:
	hint_label.text = "Permanent reset layer\nPrestige resets stored Echo and active Echo power"
	echo_status_label.text = "Stored Echo: %d\nActive Echo: %d\nActive Bonus: %s" % [
		GameState.echo_collected,
		GameState.echo_power,
		GameState.get_active_echo_bonus_summary(),
	]

func _on_echo_changed(_collected_echo: int, _active_echo_power: int) -> void:
	_refresh()

func _on_prestige_pressed() -> void:
	GameState.perform_prestige()
