extends PanelContainer
class_name RunPanel

@onready var rows_container: VBoxContainer = $Margin/Content/Rows

func _ready() -> void:
	GameState.echo_changed.connect(_on_echo_changed)
	GameState.hero_stats_changed.connect(_refresh)
	SignalBus.wave_changed.connect(_on_wave_changed)
	_refresh()

func _refresh() -> void:
	_ensure_rows()
	_set_row_text(0, "Wave Record: %d" % GameState.highest_wave_reached)
	_set_row_text(1, "Echo: %d" % GameState.echo_collected)
	_set_row_text(2, "Active Echo: %d" % GameState.echo_power)
	_set_row_text(3, "Active Bonus: %s" % GameState.get_active_echo_bonus_summary())
	_set_row_text(4, "After Death: %s" % GameState.get_collected_echo_bonus_summary())

func _on_wave_changed(_wave: int) -> void:
	_refresh()

func _on_echo_changed(_collected_echo: int, _active_echo_power: int) -> void:
	_refresh()

func _ensure_rows() -> void:
	if rows_container.get_child_count() > 0:
		return
	for _i in range(5):
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rows_container.add_child(label)

func _set_row_text(index: int, text: String) -> void:
	if index < 0 or index >= rows_container.get_child_count():
		return
	var label := rows_container.get_child(index) as Label
	if label != null:
		label.text = text
