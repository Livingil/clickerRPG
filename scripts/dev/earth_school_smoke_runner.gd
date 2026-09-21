extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_base.tscn")

func _ready() -> void:
	SaveSystem._loading = true
	GameState.active_school = SchoolRules.SCHOOL_EARTH
	GameState.highest_wave_reached = 40
	GameState.school_mastery_xp[SchoolRules.SCHOOL_EARTH] = 7000
	GameState.equipped_skill_ids = [&"stone_spike", &"quake_ring", &"bastion_crash", &""]

	var main_scene := MAIN_SCENE.instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var ability_controller := main_scene.get_node("GameplayRoot/AbilityController") as AbilityController
	var names := ability_controller.get_active_ability_names()
	if not names.has("Stone Spike") or not names.has("Quake Ring") or not names.has("Bastion Crash"):
		push_error("Earth smoke failed: earth abilities were not active. %s" % names)
		get_tree().quit(1)
		return

	var enemy := ENEMY_SCENE.instantiate() as Enemy
	add_child(enemy)
	await get_tree().process_frame
	enemy.defense = 100.0
	var base_defense := enemy.get_effective_defense()
	for _i in range(5):
		enemy.receive_school_hit(1.0, SchoolRules.SCHOOL_EARTH, 999.0)

	if int(enemy.vulnerability_stacks.get(SchoolRules.SCHOOL_EARTH, 0)) != 5:
		push_error("Earth smoke failed: E stacks were not applied.")
		get_tree().quit(1)
		return
	if enemy.is_control_locked():
		push_error("Earth smoke failed: earth stacks applied control lock.")
		get_tree().quit(1)
		return
	if enemy.get_effective_defense() >= base_defense:
		push_error("Earth smoke failed: effective defense did not decrease.")
		get_tree().quit(1)
		return
	if not enemy.vulnerability_label.text.contains("E5"):
		push_error("Earth smoke failed: earth stack label was not visible.")
		get_tree().quit(1)
		return

	var hero := main_scene.get_node("GameplayRoot/Hero") as Hero
	if hero.stats_component.current_stats.defense <= 0.0:
		hero.stats_component.current_stats.defense = 4.0
	var hero_base_defense := hero.stats_component.get_defense()
	hero.apply_bastion()
	if hero.get_effective_defense() <= hero_base_defense:
		push_error("Earth smoke failed: bastion did not increase hero defense.")
		get_tree().quit(1)
		return

	print("earth_school_smoke ok abilities=%s enemy_def=%.1f label=%s hero_def=%.1f" % [
		names,
		enemy.get_effective_defense(),
		enemy.vulnerability_label.text,
		hero.get_effective_defense(),
	])
	get_tree().quit()
