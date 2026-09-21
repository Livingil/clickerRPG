extends Node

func _ready() -> void:
	SaveSystem._loading = true
	GameState.dev_reset_all_progress()
	GameState.echo_power = 996
	GameState.echo_collected = 4
	var echo_before := GameState.echo_power
	var collected_echo := GameState.echo_collected
	GameState.activate_collected_echo()
	var report := GameState.build_run_death_report(12.0, echo_before, GameState.echo_power, collected_echo)

	if int(report.get("collected_echo", 0)) != 4 or int(report.get("echo_before", 0)) != 996 or int(report.get("echo_after", 0)) != 1000:
		push_error("Run death report smoke failed: echo values are wrong. %s" % report)
		get_tree().quit(1)
		return
	if float(report.get("damage_after", 0.0)) <= float(report.get("damage_before", 0.0)):
		push_error("Run death report smoke failed: report did not show new echo stat bonus.")
		get_tree().quit(1)
		return
	if int(report.get("remaining_to_next_echo_bonus", 0)) <= 0:
		push_error("Run death report smoke failed: next echo progress is missing.")
		get_tree().quit(1)
		return

	print("run_death_report_smoke ok echo=%d->%d dmg=%.1f->%.1f next=%d" % [
		int(report.get("echo_before", 0)),
		int(report.get("echo_after", 0)),
		float(report.get("damage_before", 0.0)),
		float(report.get("damage_after", 0.0)),
		int(report.get("remaining_to_next_echo_bonus", 0)),
	])
	get_tree().quit()
