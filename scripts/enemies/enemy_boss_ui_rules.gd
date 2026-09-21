extends RefCounted
class_name EnemyBossUiRules

static func get_tag_data(boss_kind: StringName) -> Dictionary:
	match boss_kind:
		&"wave":
			return {"visible": true, "text": "BOSS", "color": Color(0.64, 1.0, 0.72, 1.0)}
		&"mini":
			return {"visible": true, "text": "MINI", "color": Color(1.0, 0.92, 0.42, 1.0)}
		&"grand":
			return {"visible": true, "text": "GRAND", "color": Color(1.0, 0.45, 0.45, 1.0)}
		&"apex":
			return {"visible": true, "text": "APEX", "color": Color(0.84, 0.46, 1.0, 1.0)}
		_:
			return {"visible": false, "text": "", "color": Color.WHITE}
