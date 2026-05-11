extends Node2D
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var wave_boss_scene: PackedScene
@export var mini_boss_scene: PackedScene
@export var grand_boss_scene: PackedScene
@export var max_active_enemies: int = GameConstants.MAX_ACTIVE_ENEMIES

@onready var spawn_timer: Timer = $SpawnTimer

var hero: Hero
var battlefield: Battlefield
var wave_controller: WaveController
var active_enemies: Array[Enemy] = []

func _ready() -> void:
	spawn_timer.wait_time = GameConstants.SPAWN_INTERVAL
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func set_hero(value: Hero) -> void:
	hero = value

func set_battlefield(value: Battlefield) -> void:
	battlefield = value

func set_wave_controller(value: WaveController) -> void:
	wave_controller = value

func _on_spawn_timer_timeout() -> void:
	_cleanup_enemies()
	var free_slots := max_active_enemies - active_enemies.size()
	if free_slots <= 0:
		return

	var spawn_requests: Array[StringName] = []
	if wave_controller != null:
		spawn_requests = wave_controller.get_spawn_requests(active_enemies.size(), free_slots)
	else:
		spawn_requests.append(&"normal")

	for spawn_kind in spawn_requests:
		if active_enemies.size() >= max_active_enemies:
			break
		spawn_enemy(spawn_kind)

func spawn_enemy(spawn_kind: StringName = &"normal") -> void:
	var scene_to_spawn: PackedScene = enemy_scene
	match spawn_kind:
		&"wave_boss":
			scene_to_spawn = wave_boss_scene
		&"mini_boss":
			scene_to_spawn = mini_boss_scene
		&"grand_boss":
			scene_to_spawn = grand_boss_scene
	if scene_to_spawn == null:
		return
	if battlefield == null:
		return
	if hero == null:
		return

	var enemy := scene_to_spawn.instantiate() as Enemy
	if enemy == null:
		return

	if wave_controller != null:
		wave_controller.configure_enemy(enemy, spawn_kind)
		wave_controller.register_spawn(spawn_kind)

	enemy.global_position = _generate_spawn_position()
	enemy.set_target(hero)
	enemy.died.connect(_on_enemy_died)
	battlefield.enemy_container.add_child(enemy)
	active_enemies.append(enemy)

func _on_enemy_died(enemy: Enemy) -> void:
	active_enemies.erase(enemy)
	if wave_controller != null:
		wave_controller.handle_enemy_killed(enemy, active_enemies.size())

func _cleanup_enemies() -> void:
	active_enemies = active_enemies.filter(func(enemy: Enemy) -> bool:
		return is_instance_valid(enemy)
	)

func clear_active_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

func _generate_spawn_position() -> Vector2:
	var horizontal := randf_range(-GameConstants.ENEMY_SPAWN_RADIUS_X, GameConstants.ENEMY_SPAWN_RADIUS_X)
	var vertical := randf_range(-GameConstants.ENEMY_SPAWN_RADIUS_Y, GameConstants.ENEMY_SPAWN_RADIUS_Y)
	var offset := Vector2(horizontal, vertical)

	if offset.length() < 180.0:
		offset = offset.normalized() * 180.0

	var position := GameConstants.ARENA_CENTER + offset
	return Vector2(
		clampf(position.x, GameConstants.ARENA_MIN.x + 24.0, GameConstants.ARENA_MAX.x - 24.0),
		clampf(position.y, GameConstants.ARENA_MIN.y + 24.0, GameConstants.ARENA_MAX.y - 24.0)
	)
