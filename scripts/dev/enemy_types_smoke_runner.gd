extends Node

const ENEMY_SCENE := preload("res://scenes/enemies/enemy_base.tscn")

func _ready() -> void:
	var wave_controller := WaveController.new()
	add_child(wave_controller)

	wave_controller.current_wave = 1
	if wave_controller._get_available_normal_enemy_types() != [GameConstants.ENEMY_TYPE_BASIC]:
		push_error("Enemy types smoke failed: wave 1 should only have basic.")
		get_tree().quit(1)
		return

	wave_controller.current_wave = 10
	if not wave_controller._get_available_normal_enemy_types().has(GameConstants.ENEMY_TYPE_TANK):
		push_error("Enemy types smoke failed: tank is not available at wave 10.")
		get_tree().quit(1)
		return

	wave_controller.current_wave = 30
	if not wave_controller._get_available_normal_enemy_types().has(GameConstants.ENEMY_TYPE_FAST):
		push_error("Enemy types smoke failed: fast is not available at wave 30.")
		get_tree().quit(1)
		return

	wave_controller.current_wave = 50
	if not wave_controller._get_available_normal_enemy_types().has(GameConstants.ENEMY_TYPE_RANGED):
		push_error("Enemy types smoke failed: ranged is not available at wave 50.")
		get_tree().quit(1)
		return

	wave_controller.mono_normal_enemy_type = GameConstants.ENEMY_TYPE_RANGED
	for _i in range(3):
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		wave_controller.configure_enemy(enemy, &"normal")
		add_child(enemy)
		await get_tree().process_frame
		if enemy.normal_enemy_type != GameConstants.ENEMY_TYPE_RANGED:
			push_error("Enemy types smoke failed: mono wave did not force ranged.")
			get_tree().quit(1)
			return
		if enemy.attack_range <= GameConstants.ENEMY_ATTACK_RANGE:
			push_error("Enemy types smoke failed: ranged attack range was not increased.")
			get_tree().quit(1)
			return
		if enemy.body.polygon.size() != 4:
			push_error("Enemy types smoke failed: ranged should be a narrow rectangle.")
			get_tree().quit(1)
			return
		enemy.queue_free()

	var tank := ENEMY_SCENE.instantiate() as Enemy
	tank.set_normal_enemy_type(GameConstants.ENEMY_TYPE_TANK)
	add_child(tank)
	await get_tree().process_frame
	if tank.body.polygon.size() != 6 or tank.defense < 18.0:
		push_error("Enemy types smoke failed: tank shape or defense is wrong.")
		get_tree().quit(1)
		return

	var fast := ENEMY_SCENE.instantiate() as Enemy
	fast.set_normal_enemy_type(GameConstants.ENEMY_TYPE_FAST)
	add_child(fast)
	await get_tree().process_frame
	if fast.body.polygon.size() < 12 or fast.speed <= GameConstants.ENEMY_BASE_SPEED:
		push_error("Enemy types smoke failed: fast shape or speed is wrong.")
		get_tree().quit(1)
		return

	print("enemy_types_smoke ok wave50=%s mono=%s tank_def=%.1f fast_speed=%.1f" % [
		wave_controller._get_available_normal_enemy_types(),
		wave_controller.mono_normal_enemy_type,
		tank.defense,
		fast.speed,
	])
	get_tree().quit()
