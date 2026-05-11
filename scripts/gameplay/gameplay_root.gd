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
	hero.set_battlefield(battlefield)
	enemy_spawner.set_hero(hero)
	enemy_spawner.set_battlefield(battlefield)
	wave_controller.bind_spawner(enemy_spawner)
