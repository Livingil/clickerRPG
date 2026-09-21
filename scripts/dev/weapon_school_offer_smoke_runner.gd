extends Node

func _ready() -> void:
	SaveSystem._loading = true
	GameState.dev_reset_all_progress()
	GameState.gold = 100000000
	GameState.equipment_levels[&"weapon"] = 99
	var before_by_school: Dictionary = {}
	for school_id in SchoolRules.SCHOOL_ORDER:
		before_by_school[school_id] = GameState.get_skill_damage_multiplier(_get_first_skill_for_school(school_id))

	if not GameState.buy_equipment_upgrade(&"weapon"):
		push_error("Weapon school offer smoke failed: could not buy weapon upgrade.")
		get_tree().quit(1)
		return

	var offers := GameState.get_pending_weapon_skill_offers()
	if offers.size() != 3:
		push_error("Weapon school offer smoke failed: expected 3 school offers, got %d." % offers.size())
		get_tree().quit(1)
		return

	var seen: Dictionary = {}
	for offer in offers:
		var school_id := offer.get("school_id", &"") as StringName
		if not SchoolRules.SCHOOL_DEFINITIONS.has(school_id):
			push_error("Weapon school offer smoke failed: offer is not a school. %s" % offer)
			get_tree().quit(1)
			return
		if seen.has(school_id):
			push_error("Weapon school offer smoke failed: duplicate school offer. %s" % offers)
			get_tree().quit(1)
			return
		seen[school_id] = true

	var picked_school := offers[0].get("school_id", &"") as StringName
	if not GameState.apply_weapon_skill_offer(0):
		push_error("Weapon school offer smoke failed: could not apply offer.")
		get_tree().quit(1)
		return
	if int(GameState.weapon_school_upgrade_levels.get(picked_school, 0)) != 1:
		push_error("Weapon school offer smoke failed: picked school tier did not increase.")
		get_tree().quit(1)
		return
	if not GameState.get_pending_weapon_skill_offers().is_empty():
		push_error("Weapon school offer smoke failed: offers were not cleared.")
		get_tree().quit(1)
		return

	var picked_skill := _get_first_skill_for_school(picked_school)
	var picked_after := GameState.get_skill_damage_multiplier(picked_skill)
	if picked_after <= float(before_by_school[picked_school]):
		push_error("Weapon school offer smoke failed: picked school damage did not increase.")
		get_tree().quit(1)
		return
	for school_id in SchoolRules.SCHOOL_ORDER:
		if school_id == picked_school:
			continue
		var skill_id := _get_first_skill_for_school(school_id)
		if not is_equal_approx(GameState.get_skill_damage_multiplier(skill_id), float(before_by_school[school_id])):
			push_error("Weapon school offer smoke failed: unrelated school changed.")
			get_tree().quit(1)
			return

	print("weapon_school_offer_smoke ok picked=%s offers=%s dmg=%.3f" % [String(picked_school), offers, picked_after])
	get_tree().quit()

func _get_first_skill_for_school(school_id: StringName) -> StringName:
	var skills: Array = SchoolRules.SCHOOL_DEFINITIONS.get(school_id, {}).get("skills", [])
	if skills.is_empty():
		return &""
	return skills[0] as StringName
