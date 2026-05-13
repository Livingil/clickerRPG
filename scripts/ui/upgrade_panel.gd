extends PanelContainer
class_name UpgradePanel

@onready var tabs: TabContainer = $Margin/Content/Tabs
@onready var title_label: Label = $Margin/Content/Title
@onready var stats_rows: VBoxContainer = $Margin/Content/Tabs/StatsTab/StatsScroll/StatsRows
@onready var equipment_rows: VBoxContainer = $Margin/Content/Tabs/EquipmentTab/EquipmentScroll/EquipmentRows
@onready var artifacts_rows: VBoxContainer = $Margin/Content/Tabs/ArtifactsTab/ArtifactsScroll/ArtifactsRows

var expanded_equipment_id: StringName = &""

func _ready() -> void:
	_apply_localized_labels()
	GameState.resources_changed.connect(_refresh_all)
	GameState.upgrades_changed.connect(_refresh_all)
	GameState.hero_stats_changed.connect(_refresh_all)
	GameState.language_changed.connect(_refresh_all)
	_refresh_all()

func _refresh_all(_arg0: Variant = null, _arg1: Variant = null) -> void:
	_apply_localized_labels()
	_build_stats_tab()
	_build_equipment_tab()
	_build_artifacts_tab()

func _build_stats_tab() -> void:
	_clear_container(stats_rows)
	var is_ru: bool = GameState.current_language == &"ru"
	var meta_header := Label.new()
	meta_header.text = "Прогресс забега" if is_ru else "Run Progress"
	stats_rows.add_child(meta_header)

	var meta_grid := GridContainer.new()
	meta_grid.columns = 2
	meta_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_grid.add_theme_constant_override("h_separation", 14)
	meta_grid.add_theme_constant_override("v_separation", 4)
	_add_stat_row(meta_grid, ("Рекорд волны" if is_ru else "Wave Record"), str(GameState.highest_wave_reached))
	_add_stat_row(meta_grid, ("Количество смертей" if is_ru else "Deaths"), str(GameState.total_deaths))
	_add_stat_row(meta_grid, ("Рекорд времени забега" if is_ru else "Best Run Time"), GameState.format_duration_short(GameState.best_run_time_sec))
	stats_rows.add_child(meta_grid)

	var sep := HSeparator.new()
	stats_rows.add_child(sep)

	var header := Label.new()
	header.text = GameState.loc("run.hero_stats")
	stats_rows.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 4)

	var stats := GameState.build_hero_stats()
	var atk_runtime_mult: float = GameState.get_runtime_attack_speed_multiplier()
	var clone_mult: float = GameState.get_clone_attack_multiplier()
	var real_attack_speed: float = stats.attack_speed * atk_runtime_mult
	var real_dps: float = stats.compute_dps() * atk_runtime_mult * (1.0 + clone_mult)

	_add_stat_row(grid, GameState.loc("stat.damage"), "%.1f" % stats.damage)
	_add_stat_row(grid, GameState.loc("stat.attack_speed"), "%.2f" % real_attack_speed)
	_add_stat_row(grid, GameState.loc("stat.dps"), "%.1f" % real_dps)
	_add_stat_row(grid, GameState.loc("stat.max_hp"), "%.0f" % stats.max_hp)
	_add_stat_row(grid, GameState.loc("stat.crit_chance"), "%.2f%%" % (stats.crit_chance * 100.0))
	_add_stat_row(grid, GameState.loc("stat.crit_mult"), "%.2fx" % stats.crit_multiplier)
	_add_stat_row(grid, GameState.loc("stat.defense"), "%.1f" % stats.defense)
	_add_stat_row(grid, GameState.loc("stat.evasion"), "%.1f" % stats.evasion)
	_add_stat_row(grid, GameState.loc("stat.accuracy"), "%.1f" % stats.accuracy)
	stats_rows.add_child(grid)

	var combat_header := Label.new()
	combat_header.text = "Боевые модификаторы" if is_ru else "Combat Modifiers"
	stats_rows.add_child(combat_header)
	var combat_grid := GridContainer.new()
	combat_grid.columns = 2
	combat_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_grid.add_theme_constant_override("h_separation", 14)
	combat_grid.add_theme_constant_override("v_separation", 4)
	_add_stat_row(combat_grid, ("Скорость атаки (x)" if is_ru else "Attack Speed (x)"), "%.2f" % atk_runtime_mult)
	_add_stat_row(combat_grid, ("Клон (x урон)" if is_ru else "Clone (x dmg)"), "%.2f" % (1.0 + clone_mult))
	stats_rows.add_child(combat_grid)

	var school_header := Label.new()
	school_header.text = "Бонусы активной школы" if is_ru else "Active School Bonuses"
	stats_rows.add_child(school_header)
	var school_grid := GridContainer.new()
	school_grid.columns = 2
	school_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	school_grid.add_theme_constant_override("h_separation", 14)
	school_grid.add_theme_constant_override("v_separation", 4)
	var school_bonus: Dictionary = GameState.get_school_mastery_skill_bonuses(GameState.active_school)
	_add_stat_row(school_grid, ("Урон навыков" if is_ru else "Skill Damage"), "+%.1f%%" % (float(school_bonus.get("damage_bonus", 0.0)) * 100.0))
	_add_stat_row(school_grid, ("Снижение КД" if is_ru else "Cooldown Reduction"), "-%.1f%%" % (float(school_bonus.get("cooldown_reduction", 0.0)) * 100.0))
	_add_stat_row(school_grid, ("Сила эффектов" if is_ru else "Effect Power"), "+%.1f%%" % (float(school_bonus.get("proc_bonus", 0.0)) * 100.0))
	var unique_text: String = String(school_bonus.get("unique_bonus_text", ""))
	if unique_text != "":
		_add_stat_row(school_grid, ("Уникальный бонус" if is_ru else "Unique Bonus"), unique_text)
	stats_rows.add_child(school_grid)

func _build_equipment_tab() -> void:
	_clear_container(equipment_rows)
	var offers := GameState.get_pending_weapon_skill_offers()
	if not offers.is_empty():
		var offer_title := Label.new()
		offer_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		offer_title.text = "Weapon Milestone: choose 1 skill upgrade"
		equipment_rows.add_child(offer_title)
		for i in range(offers.size()):
			var offer: Dictionary = offers[i]
			var offer_button := Button.new()
			offer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			offer_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			offer_button.text = String(offer.get("text", "Upgrade"))
			offer_button.pressed.connect(_on_pick_weapon_offer.bind(i))
			equipment_rows.add_child(offer_button)

	var next_locked_shown := false
	for equipment_id in GameState.get_equipment_ids():
		var row := VBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 4)
		var unlocked: bool = GameState.is_equipment_unlocked(equipment_id)
		if not unlocked:
			if next_locked_shown:
				continue
			next_locked_shown = true

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.72, 0.72, 0.76, 1.0)
		var card_margin := MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 8)
		card_margin.add_theme_constant_override("margin_right", 8)
		card_margin.add_theme_constant_override("margin_top", 6)
		card_margin.add_theme_constant_override("margin_bottom", 6)
		card.add_child(card_margin)
		var card_body := VBoxContainer.new()
		card_body.add_theme_constant_override("separation", 4)
		card_margin.add_child(card_body)

		var top_row := HBoxContainer.new()
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_theme_constant_override("separation", 8)

		var info_button := Button.new()
		info_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		info_button.flat = true
		var level: int = GameState.get_equipment_level(equipment_id)
		var upgrade_cost: int = GameState.get_equipment_upgrade_cost(equipment_id)
		var unlock_cost: int = GameState.get_equipment_unlock_cost(equipment_id)
		info_button.text = "%s  %s%d" % [
			("%s %s" % ["[LOCK]", GameState.get_equipment_display_name(equipment_id)]) if not unlocked else GameState.get_equipment_display_name(equipment_id),
			("Ур." if GameState.current_language == &"ru" else "Lv."),
			level
		]
		info_button.disabled = not unlocked
		if unlocked:
			info_button.pressed.connect(_on_toggle_equipment_details.bind(equipment_id))
		else:
			info_button.modulate = Color(0.55, 0.55, 0.58, 1.0)

		var buy_button := Button.new()
		buy_button.custom_minimum_size = Vector2(96.0, 0.0)
		if unlocked:
			buy_button.text = ("%d зол." % upgrade_cost) if GameState.current_language == &"ru" else ("%d g" % upgrade_cost)
			buy_button.disabled = GameState.gold < upgrade_cost
			buy_button.pressed.connect(_on_buy_equipment.bind(equipment_id))
		else:
			buy_button.text = ("Открыть %d" % unlock_cost) if GameState.current_language == &"ru" else ("Unlock %d" % unlock_cost)
			buy_button.disabled = not GameState.can_unlock_equipment(equipment_id)
			buy_button.pressed.connect(_on_unlock_equipment.bind(equipment_id))

		var boost_row := HBoxContainer.new()
		boost_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boost_row.add_theme_constant_override("separation", 10)
		var base_boost_label := Label.new()
		base_boost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		base_boost_label.text = GameState.get_equipment_base_boost_short(equipment_id)
		base_boost_label.modulate = Color(0.55, 0.95, 0.55, 1.0) if unlocked else Color(0.62, 0.62, 0.66, 1.0)
		var proc_boost_label := Label.new()
		proc_boost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		proc_boost_label.text = ("%s | %s" % [
			GameState.get_equipment_proc_boost_short(equipment_id),
			GameState.get_equipment_next_perk_upgrade_text(equipment_id),
		])
		proc_boost_label.modulate = Color(0.45, 0.9, 0.45, 1.0)

		var effect_label := Label.new()
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_label.modulate = Color(0.8, 0.82, 0.86, 1.0)
		effect_label.text = GameState.get_equipment_effect_summary(equipment_id)
		effect_label.visible = unlocked and equipment_id == expanded_equipment_id

		boost_row.add_child(base_boost_label)
		boost_row.add_child(proc_boost_label)
		top_row.add_child(info_button)
		top_row.add_child(buy_button)
		card_body.add_child(top_row)
		card_body.add_child(boost_row)
		card_body.add_child(effect_label)
		row.add_child(card)
		equipment_rows.add_child(row)

func _build_artifacts_tab() -> void:
	_clear_container(artifacts_rows)
	for row_data in GameState.get_artifact_ui_rows():
		var row := VBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 4)

		var top_row := HBoxContainer.new()
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_theme_constant_override("separation", 8)

		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var owned := bool(row_data["owned"])
		var level := int(row_data["level"])
		name_label.text = "%s  %s  %s%d" % [
			row_data["name"],
			("[Есть]" if owned else "[Закрыт]") if GameState.current_language == &"ru" else ("[Owned]" if owned else "[Locked]"),
			("Ур." if GameState.current_language == &"ru" else "Lv."),
			level,
		]

		var buy_button := Button.new()
		buy_button.custom_minimum_size = Vector2(96.0, 0.0)
		buy_button.text = ("%d эсс." % int(row_data["cost"])) if GameState.current_language == &"ru" else ("%d e" % int(row_data["cost"]))
		buy_button.disabled = not bool(row_data["affordable"])
		buy_button.pressed.connect(_on_buy_artifact.bind(row_data["id"] as StringName))

		var effect_label := Label.new()
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_label.modulate = Color(0.8, 0.82, 0.86, 1.0)
		effect_label.text = GameState.get_artifact_effect_summary(row_data["id"] as StringName)

		top_row.add_child(name_label)
		top_row.add_child(buy_button)
		row.add_child(top_row)
		row.add_child(effect_label)
		artifacts_rows.add_child(row)

func _on_buy_equipment(equipment_id: StringName) -> void:
	GameState.buy_equipment_upgrade(equipment_id)

func _on_unlock_equipment(equipment_id: StringName) -> void:
	GameState.unlock_equipment(equipment_id)

func _on_buy_artifact(artifact_id: StringName) -> void:
	GameState.buy_artifact_upgrade(artifact_id)

func _on_pick_weapon_offer(offer_index: int) -> void:
	GameState.apply_weapon_skill_offer(offer_index)

func _on_toggle_equipment_details(equipment_id: StringName) -> void:
	expanded_equipment_id = &"" if expanded_equipment_id == equipment_id else equipment_id
	_build_equipment_tab()

func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func _apply_localized_labels() -> void:
	var is_ru := GameState.current_language == &"ru"
	title_label.text = "Улучшения" if is_ru else "Upgrades"
	tabs.set_tab_title(0, "Статы" if is_ru else "Stats")
	tabs.set_tab_title(1, "Экипировка" if is_ru else "Equipment")
	tabs.set_tab_title(2, "Артефакты" if is_ru else "Artifacts")

func _add_stat_row(grid: GridContainer, key_text: String, value_text: String) -> void:
	var key_label := Label.new()
	key_label.text = key_text
	var value_label := Label.new()
	value_label.text = value_text
	grid.add_child(key_label)
	grid.add_child(value_label)
