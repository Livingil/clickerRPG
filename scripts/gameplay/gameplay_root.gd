extends Node2D
class_name GameplayRoot

@onready var hero: Hero = $Hero
@onready var battlefield: Battlefield = $Battlefield
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var ability_controller: AbilityController = $AbilityController
@onready var wave_controller: WaveController = $WaveController

func _ready() -> void:
	randomize()
	hero.attack_performed.connect(ability_controller.handle_hero_attack)
	hero.attack_performed.connect(_on_hero_attack_performed)
	hero.died.connect(_on_hero_died)
	hero.set_battlefield(battlefield)
	enemy_spawner.set_hero(hero)
	enemy_spawner.set_battlefield(battlefield)
	wave_controller.bind_spawner(enemy_spawner)

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
	GameState.activate_collected_echo()
	enemy_spawner.clear_active_enemies()
	wave_controller.reset_to_first_wave()
	hero.reset_for_new_run()

func _on_hero_attack_performed(_target: Enemy, _damage: float, _is_crit: bool) -> void:
	GameState.add_active_school_mastery_xp(1)

func _is_inside_arena(world_position: Vector2) -> bool:
	return world_position.x >= GameConstants.ARENA_MIN.x and world_position.x <= GameConstants.ARENA_MAX.x and world_position.y >= GameConstants.ARENA_MIN.y and world_position.y <= GameConstants.ARENA_MAX.y
