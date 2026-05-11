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
	hero.died.connect(_on_hero_died)
	hero.set_battlefield(battlefield)
	enemy_spawner.set_hero(hero)
	enemy_spawner.set_battlefield(battlefield)
	wave_controller.bind_spawner(enemy_spawner)

func _on_hero_died() -> void:
	GameState.activate_collected_echo()
	enemy_spawner.clear_active_enemies()
	wave_controller.reset_to_first_wave()
	hero.reset_for_new_run()
