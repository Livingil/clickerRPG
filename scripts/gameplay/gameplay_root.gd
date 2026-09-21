extends Node2D
class_name GameplayRoot

@onready var hero: Hero = $Hero
@onready var battlefield: Battlefield = $Battlefield
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var ability_controller: AbilityController = $AbilityController
@onready var wave_controller: WaveController = $WaveController

var run_time_sec: float = 0.0
var hero_death_pending: bool = false

func _ready() -> void:
	randomize()
	set_process(true)
	hero.died.connect(_on_hero_died)
	hero.set_battlefield(battlefield)
	enemy_spawner.set_hero(hero)
	enemy_spawner.set_battlefield(battlefield)
	wave_controller.bind_spawner(enemy_spawner)
	if not SignalBus.runtime_reset_requested.is_connected(_on_runtime_reset_requested):
		SignalBus.runtime_reset_requested.connect(_on_runtime_reset_requested)
	run_time_sec = 0.0

func _process(delta: float) -> void:
	run_time_sec += delta

func _unhandled_input(event: InputEvent) -> void:
	if hero == null:
		return

	var tap_position := Vector2.ZERO
	var has_tap := false

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			tap_position = touch.position
			has_tap = true
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			tap_position = mouse.position
			has_tap = true

	if not has_tap:
		return
	if not _is_inside_arena(tap_position):
		return

	if hero.movement_component != null and hero.movement_component.has_method("set_manual_move_target"):
		hero.movement_component.call("set_manual_move_target", tap_position)
	get_viewport().set_input_as_handled()

func _on_hero_died() -> void:
	if hero_death_pending:
		return
	hero_death_pending = true
	call_deferred("_resolve_hero_death")

func _resolve_hero_death() -> void:
	var echo_before := GameState.echo_power
	var collected_echo := GameState.echo_collected
	var death_report: Dictionary = {}
	if BackendClient.logged_in:
		await BackendClient.flush_run_rewards()
		collected_echo = GameState.echo_collected
		var result: Dictionary = await BackendClient.request_command("run.death", {"runTimeSec": run_time_sec})
		if not bool(result.get("offline", false)) and bool(result.get("success", false)):
			death_report = (result.get("result", {}) as Dictionary).get("report", {}) as Dictionary
	if death_report.is_empty():
		GameState.register_run_death(run_time_sec)
		GameState.activate_collected_echo()
		death_report = GameState.build_run_death_report(run_time_sec, echo_before, GameState.echo_power, collected_echo)
	_reset_live_run_state()
	GameState.emit_run_death_report(death_report)

func _on_runtime_reset_requested() -> void:
	_reset_live_run_state()

func _reset_live_run_state() -> void:
	enemy_spawner.clear_active_enemies()
	battlefield.clear_transient_nodes()
	wave_controller.reset_to_first_wave()
	hero.reset_for_new_run()
	run_time_sec = 0.0
	hero_death_pending = false

func _is_inside_arena(world_position: Vector2) -> bool:
	return world_position.x >= GameConstants.ARENA_MIN.x and world_position.x <= GameConstants.ARENA_MAX.x and world_position.y >= GameConstants.ARENA_MIN.y and world_position.y <= GameConstants.ARENA_MAX.y
