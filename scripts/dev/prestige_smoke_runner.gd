extends Node

func _ready() -> void:
	var attack_upgrade_id: StringName = &"attack"
	SaveSystem._loading = true
	GameState.dev_reset_all_progress()
	GameState.highest_wave_reached = 50
	GameState.school_mastery_xp[SchoolRules.SCHOOL_FIRE] = 240000
	var expected_shards := GameState.get_prestige_shards_for_current_run()
	if expected_shards != 1:
		push_error("Prestige smoke failed: first prestige should grant exactly 1 shard.")
		get_tree().quit(1)
		return
	if not GameState.perform_prestige():
		push_error("Prestige smoke failed: perform_prestige returned false.")
		get_tree().quit(1)
		return
	if GameState.prestige_shards != expected_shards:
		push_error("Prestige smoke failed: shards were not granted.")
		get_tree().quit(1)
		return
	if GameState.prestige_shards_earned_total != expected_shards:
		push_error("Prestige smoke failed: total earned shards were not updated.")
		get_tree().quit(1)
		return
	if GameState.highest_wave_reached != 1 or GameState.can_perform_prestige():
		push_error("Prestige smoke failed: wave was not reset after prestige.")
		get_tree().quit(1)
		return
	var xp_mult := GameState.get_school_xp_multiplier()
	if xp_mult <= 1.0:
		push_error("Prestige smoke failed: school XP multiplier did not increase.")
		get_tree().quit(1)
		return
	var shards_before_buy := GameState.prestige_shards
	if not GameState.buy_prestige_upgrade(attack_upgrade_id):
		push_error("Prestige smoke failed: could not buy attack upgrade.")
		get_tree().quit(1)
		return
	if GameState.prestige_shards >= shards_before_buy:
		push_error("Prestige smoke failed: upgrade did not spend shards.")
		get_tree().quit(1)
		return
	print("prestige_smoke ok shards=%d xp_mult=%.2f attack_level=%d" % [
		expected_shards,
		xp_mult,
		GameState.get_prestige_upgrade_level(attack_upgrade_id),
	])
	get_tree().quit()
