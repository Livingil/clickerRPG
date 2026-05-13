extends SceneTree
func _init():
	var report := BalanceSimulator.run_multi_profiles(20, 5)
	for profile in BalanceSimulator.get_profile_names():
		var rows: Array = report.get(profile, [])
		print("PROFILE=", profile)
		for row_any in rows:
			var row: Dictionary = row_any
			print(JSON.stringify(row))
	quit()
