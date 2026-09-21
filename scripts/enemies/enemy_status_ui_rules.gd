extends RefCounted
class_name EnemyStatusUiRules

static func get_school_stack_code(school_id: StringName) -> String:
	match school_id:
		SchoolRules.SCHOOL_FIRE:
			return "F"
		SchoolRules.SCHOOL_WATER:
			return "W"
		SchoolRules.SCHOOL_EARTH:
			return "E"
		SchoolRules.SCHOOL_AIR:
			return "A"
		SchoolRules.SCHOOL_LIGHTNING:
			return "L"
		_:
			return "?"
