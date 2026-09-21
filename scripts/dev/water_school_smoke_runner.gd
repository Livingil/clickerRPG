extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_base.tscn")

func _ready() -> void:
	SaveSystem._loading = true
	GameState.active_school = SchoolRules.SCHOOL_WATER
	GameState.highest_wave_reached = 40
	GameState.school_mastery_xp[SchoolRules.SCHOOL_WATER] = 7000
	GameState.equipped_skill_ids = [&"frost_orb", &"tidal_pulse", &"glacial_field", &""]

	var main_scene := MAIN_SCENE.instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var ability_controller := main_scene.get_node("GameplayRoot/AbilityController") as AbilityController
	var names := ability_controller.get_active_ability_names()
	if not names.has("Frost Orb") or not names.has("Tidal Pulse") or not names.has("Blizzard"):
		push_error("Water smoke failed: water abilities were not active. %s" % names)
		get_tree().quit(1)
		return

	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.max_hp = 100000.0
	add_child(enemy)
	await get_tree().process_frame
	for _i in range(5):
		enemy.apply_water_chill_stack()

	if int(enemy.vulnerability_stacks.get(SchoolRules.SCHOOL_WATER, 0)) != 5:
		push_error("Water smoke failed: W stacks were not applied.")
		get_tree().quit(1)
		return
	if not enemy.is_control_locked():
		push_error("Water smoke failed: freeze was not applied at 5 stacks.")
		get_tree().quit(1)
		return
	if enemy.get_movement_speed_multiplier() > 0.01:
		push_error("Water smoke failed: frozen enemy can still move.")
		get_tree().quit(1)
		return
	enemy.freeze_time_left = 0.0
	enemy.apply_vulnerability_stack(SchoolRules.SCHOOL_FIRE)
	if enemy.get_movement_speed_multiplier() >= 1.0 or enemy.get_attack_recovery_multiplier() >= 1.0:
		push_error("Water smoke failed: chill slow multipliers were not applied.")
		get_tree().quit(1)
		return
	if not enemy.vulnerability_label.text.contains("W5") or not enemy.vulnerability_label.text.contains("F1"):
		push_error("Water smoke failed: all stack label did not show W5.")
		get_tree().quit(1)
		return

	print("water_school_smoke ok abilities=%s label=%s" % [names, enemy.vulnerability_label.text])
	get_tree().quit()
