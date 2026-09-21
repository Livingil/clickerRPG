extends Node

const SMOKE_SAVE_PATH: String = "user://save_roundtrip_smoke.json"

func _ready() -> void:
	SaveSystem._loading = true
	GameState.dev_reset_all_progress()
	GameState.gold = 1234
	GameState.essence = 567
	GameState.echo_collected = 8
	GameState.echo_power = 160
	GameState.current_run_wave = 9
	GameState.highest_wave_reached = 77
	GameState.active_school = SchoolRules.SCHOOL_WATER
	GameState.school_mastery_xp[SchoolRules.SCHOOL_WATER] = 12345
	GameState.prestige_shards = 3
	GameState.prestige_shards_earned_total = 5
	GameState.weapon_school_upgrade_levels[SchoolRules.SCHOOL_FIRE] = 2
	GameState.pending_weapon_skill_offers = [
		{"school_id": SchoolRules.SCHOOL_WATER, "text": "Water"},
		{"school_id": SchoolRules.SCHOOL_EARTH, "text": "Earth"},
	]
	GameState.active_ad_boosts[GameState.AD_BOOST_GAME_SPEED] = 120.0
	GameState._apply_game_speed_time_scale()

	SaveSystem._loading = false
	SaveSystem.save_game(SMOKE_SAVE_PATH)

	GameState.dev_reset_all_progress()
	if not is_equal_approx(Engine.time_scale, 1.0):
		push_error("Save roundtrip smoke failed: dev reset did not restore time scale.")
		get_tree().quit(1)
		return

	SaveSystem.load_game(SMOKE_SAVE_PATH)

	if GameState.gold != 1234 or GameState.essence != 567:
		push_error("Save roundtrip smoke failed: resources were not restored.")
		get_tree().quit(1)
		return
	if GameState.current_run_wave != 9 or GameState.highest_wave_reached != 77:
		push_error("Save roundtrip smoke failed: wave state was not restored.")
		get_tree().quit(1)
		return
	if GameState.active_school != SchoolRules.SCHOOL_WATER or GameState.get_school_mastery_xp(SchoolRules.SCHOOL_WATER) != 12345:
		push_error("Save roundtrip smoke failed: school state was not restored.")
		get_tree().quit(1)
		return
	if int(GameState.weapon_school_upgrade_levels.get(SchoolRules.SCHOOL_FIRE, 0)) != 2:
		push_error("Save roundtrip smoke failed: weapon school upgrades were not restored.")
		get_tree().quit(1)
		return
	if GameState.get_pending_weapon_skill_offers().size() != 2:
		push_error("Save roundtrip smoke failed: pending weapon offers were not restored.")
		get_tree().quit(1)
		return
	if not GameState.has_active_ad_boost(GameState.AD_BOOST_GAME_SPEED) or not is_equal_approx(Engine.time_scale, 2.0):
		push_error("Save roundtrip smoke failed: active game speed boost was not restored.")
		get_tree().quit(1)
		return

	print("save_roundtrip_smoke ok version=%d offers=%d speed=%.1f" % [
		GameState.SAVE_VERSION,
		GameState.get_pending_weapon_skill_offers().size(),
		GameState.get_active_ad_boost_time_left(GameState.AD_BOOST_GAME_SPEED),
	])
	get_tree().quit()
