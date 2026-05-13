extends Node

const MAX_WAVE: int = 300
const STEP: int = 25

func _ready() -> void:
	var profiles: Array[StringName] = BalanceSimulator.get_profile_names()
	var report: Dictionary = BalanceSimulator.run_multi_profiles(MAX_WAVE, STEP, profiles)
	_write_json(report)
	_write_csv(report, profiles)
	_print_summary(report, profiles)
	get_tree().quit()

func _write_json(report: Dictionary) -> void:
	var out_path := "user://balance_report_multi.json"
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(report))
	f.close()
	print("saved_json=", out_path)

func _write_csv(report: Dictionary, profiles: Array[StringName]) -> void:
	var out_path := "user://balance_report_multi.csv"
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_line("profile,wave,hero_dps,normal_ttk,apex_ttk,gold,essence,wave_gold_income,wave_gold_spent,wave_essence_income,wave_essence_spent,weapon,helm,chest,gloves,boots,ring,amulet,relic,artifact_levels,echo_power,echo_collected,run_index,death_count,first_death_wave,latest_death_wave,furthest_wave_reached")
	for profile in profiles:
		var rows: Array = report.get(profile, [])
		for row_any in rows:
			var row: Dictionary = row_any
			var e: Dictionary = row.get("equip", {})
			f.store_line("%s,%d,%.4f,%.6f,%.6f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [
				String(profile),
				int(row.get("wave", 0)),
				float(row.get("hero_dps", 0.0)),
				float(row.get("normal_ttk", 0.0)),
				float(row.get("apex_ttk", 0.0)),
				int(row.get("gold", 0)),
				int(row.get("essence", 0)),
				int(row.get("wave_gold_income", 0)),
				int(row.get("wave_gold_spent", 0)),
				int(row.get("wave_essence_income", 0)),
				int(row.get("wave_essence_spent", 0)),
				int(e.get("weapon", 0)),
				int(e.get("helm", 0)),
				int(e.get("chest", 0)),
				int(e.get("gloves", 0)),
				int(e.get("boots", 0)),
				int(e.get("ring", 0)),
				int(e.get("amulet", 0)),
				int(e.get("relic", 0)),
				int(row.get("artifact_levels", 0)),
				int(row.get("echo_power", 0)),
				int(row.get("echo_collected", 0)),
				int(row.get("run_index", 0)),
				int(row.get("death_count", 0)),
				int(row.get("first_death_wave", -1)),
				int(row.get("latest_death_wave", -1)),
				int(row.get("furthest_wave_reached", 0)),
			])
	f.close()
	print("saved_csv=", out_path)

func _print_summary(report: Dictionary, profiles: Array[StringName]) -> void:
	for profile in profiles:
		var rows: Array = report.get(profile, [])
		if rows.is_empty():
			continue
		var last: Dictionary = rows[rows.size() - 1]
		print("profile=%s wave=%d run=%d deaths=%d first_death=%d latest_death=%d furthest=%d dps=%.2f normal_ttk=%.4f apex_ttk=%.4f gold=%d essence=%d" % [
			String(profile),
			int(last.get("wave", 0)),
			int(last.get("run_index", 0)),
			int(last.get("death_count", 0)),
			int(last.get("first_death_wave", -1)),
			int(last.get("latest_death_wave", -1)),
			int(last.get("furthest_wave_reached", 0)),
			float(last.get("hero_dps", 0.0)),
			float(last.get("normal_ttk", 0.0)),
			float(last.get("apex_ttk", 0.0)),
			int(last.get("gold", 0)),
			int(last.get("essence", 0)),
		])
