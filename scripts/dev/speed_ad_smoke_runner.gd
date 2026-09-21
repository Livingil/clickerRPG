extends Node

func _ready() -> void:
	SaveSystem._loading = true
	GameState.active_ad_boosts.clear()
	Engine.time_scale = 1.0

	GameState.accept_game_speed_ad_boost()
	if not GameState.has_active_ad_boost(GameState.AD_BOOST_GAME_SPEED):
		push_error("Speed ad smoke failed: boost was not activated.")
		get_tree().quit(1)
		return
	if not is_equal_approx(Engine.time_scale, 2.0):
		push_error("Speed ad smoke failed: time_scale was not set to x2.")
		get_tree().quit(1)
		return

	GameState.active_ad_boosts[GameState.AD_BOOST_GAME_SPEED] = 0.001
	await get_tree().process_frame
	await get_tree().process_frame

	if GameState.has_active_ad_boost(GameState.AD_BOOST_GAME_SPEED):
		push_error("Speed ad smoke failed: boost did not expire.")
		get_tree().quit(1)
		return
	if not is_equal_approx(Engine.time_scale, 1.0):
		push_error("Speed ad smoke failed: time_scale was not restored.")
		get_tree().quit(1)
		return

	print("speed_ad_smoke ok")
	get_tree().quit()
