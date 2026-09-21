extends Node

const HERO_SCENE := preload("res://scenes/hero/hero.tscn")
const EnemyProjectileScript := preload("res://scripts/effects/enemy_projectile.gd")

func _ready() -> void:
	GameState.show_hero_damage_text = false
	GameState.show_hero_miss_text = false

	var hero := HERO_SCENE.instantiate() as Hero
	add_child(hero)
	await get_tree().process_frame

	hero.global_position = Vector2(360.0, 620.0)
	hero.max_hp = 100.0
	hero.hp = 100.0

	var projectile := EnemyProjectileScript.new() as Node2D
	add_child(projectile)
	projectile.setup(Vector2(360.0, 260.0), hero, 25.0, 999.0, null)

	var frames_left := 180
	while frames_left > 0 and is_instance_valid(projectile) and hero.hp >= 100.0:
		frames_left -= 1
		await get_tree().physics_frame

	if hero.hp >= 100.0:
		push_error("Enemy projectile smoke failed: hero HP did not decrease.")
		get_tree().quit(1)
		return

	print("enemy_projectile_smoke ok hp=%.1f" % hero.hp)
	get_tree().quit()
