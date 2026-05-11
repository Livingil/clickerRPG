extends PanelContainer
class_name PrestigePanel

@onready var hint_label: Label = $Margin/Content/Hint
@onready var echo_status_label: Label = $Margin/Content/EchoStatus

func _ready() -> void:
	GameState.echo_changed.connect(_refresh)
	GameState.hero_stats_changed.connect(_refresh)
	_refresh()

func _refresh(_value: Variant = null) -> void:
	hint_label.text = "Permanent reset layer\nPrestige resets stored Echo and active Echo power"
	echo_status_label.text = "Stored Echo: %d\nActive Echo: %d\nActive Bonus: %s" % [
		GameState.echo_collected,
		GameState.echo_power,
		GameState.get_active_echo_bonus_summary(),
	]
