extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

const DEFAULT_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const HIT_FLASH_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DeathBurstScene = preload("res://scenes/effects/death_burst.tscn")

@export var max_hp: float = GameConstants.ENEMY_BASE_HP
@export var speed: float = GameConstants.ENEMY_BASE_SPEED
@export var attack_damage: float = GameConstants.ENEMY_BASE_DAMAGE
@export var defense: float = GameConstants.ENEMY_BASE_DEFENSE
@export var evasion: float = GameConstants.ENEMY_BASE_EVASION
@export var accuracy: float = GameConstants.ENEMY_BASE_ACCURACY
@export var attack_range: float = GameConstants.ENEMY_ATTACK_RANGE
@export var attack_cooldown: float = GameConstants.ENEMY_ATTACK_COOLDOWN
@export var reward_gold: int = GameConstants.ENEMY_REWARD_GOLD
@export var reward_essence: int = GameConstants.ENEMY_REWARD_ESSENCE
@export var wave_number: int = 1
@export var body_radius: float = 18.0
@export var is_boss: bool = false
@export var boss_kind: StringName = &"none"
@export var burn_duration: float = 3.0
@export var burn_tick_interval: float = 0.5
@export var burn_base_ratio: float = 0.12
@export var burn_stack_bonus_ratio: float = 0.18
@export var burn_max_multiplier: float = 2.5

@onready var movement_component: EnemyMovementComponent = $MovementComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var body: Polygon2D = $Body
@onready var boss_tag: Label = $BossTag
@onready var vulnerability_label: Label = $VulnerabilityLabel

var hp: float = 0.0
var attack_cooldown_left: float = 0.0
var vulnerability_stacks: Dictionary = {}
var vulnerability_timers: Dictionary = {}
var burn_time_left: float = 0.0
var burn_tick_left: float = 0.0
var burn_tick_damage: float = 0.0

var hero_target: Hero

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	attack_cooldown_left = randf_range(0.05, attack_cooldown)
	_setup_boss_tag()
	_refresh_health_bar()
	SignalBus.emit_enemy_spawned(self)

func _physics_process(delta: float) -> void:
	movement_component.move_towards_target(hero_target, delta)
	_tick_attack(delta)
	_tick_vulnerabilities(delta)
	_tick_burn(delta)

func set_target(hero: Hero) -> void:
	hero_target = hero

func take_damage(amount: float) -> void:
	_apply_damage(amount, true)

func _apply_damage(amount: float, show_feedback: bool) -> void:
	var damage_taken := CombatStats.apply_defense(amount, defense)
	hp -= damage_taken
	if show_feedback:
		_play_hit_feedback()
	_refresh_health_bar()
	if hp <= 0.0:
		die()

func take_school_damage(amount: float, school_id: StringName) -> void:
	var school_damage := amount * get_vulnerability_multiplier(school_id)
	take_damage(school_damage)
	apply_vulnerability_stack(school_id)
	if school_id == SchoolRules.SCHOOL_FIRE:
		_apply_burn_from_fire_hit(school_damage)

func receive_school_hit(amount: float, school_id: StringName, attacker_accuracy: float) -> bool:
	var hit_chance := CombatStats.compute_hit_chance(attacker_accuracy, evasion)
	if randf() > hit_chance:
		if GameState.show_miss_text:
			_spawn_combat_text("MISS", Color(0.85, 0.88, 1.0, 1.0), 1.0)
		return false
	var school_damage := amount * get_vulnerability_multiplier(school_id)
	take_damage(school_damage)
	apply_vulnerability_stack(school_id)
	if school_id == SchoolRules.SCHOOL_FIRE:
		_apply_burn_from_fire_hit(school_damage)
	if GameState.show_damage_text:
		_spawn_combat_text(str(int(round(school_damage))), Color(1.0, 0.86, 0.46, 1.0), 1.0)
	return true

func receive_school_crit_hit(amount: float, school_id: StringName, attacker_accuracy: float) -> bool:
	var hit := receive_school_hit(amount, school_id, attacker_accuracy)
	if hit and GameState.show_crit_text:
		_spawn_combat_text("CRIT", Color(1.0, 0.45, 0.2, 1.0), 1.1)
	return hit

func die() -> void:
	_spawn_death_burst()
	GameState.add_gold(reward_gold)
	GameState.add_essence(reward_essence)
	GameState.add_echo(GameState.get_echo_gain_for_enemy(boss_kind, wave_number))
	GameState.add_active_school_mastery_xp(GameState.get_mastery_xp_for_enemy(boss_kind))
	SignalBus.emit_enemy_killed(self)
	died.emit(self)
	queue_free()

func _tick_attack(delta: float) -> void:
	if hero_target == null:
		return
	if hero_target.hp <= 0.0:
		return

	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	var distance := global_position.distance_to(hero_target.global_position)
	if distance > attack_range:
		return
	if attack_cooldown_left > 0.0:
		return

	hero_target.receive_enemy_hit(attack_damage, accuracy, self)
	attack_cooldown_left = attack_cooldown

func clamp_to_arena() -> void:
	global_position = Vector2(
		clampf(global_position.x, GameConstants.ARENA_MIN.x + body_radius, GameConstants.ARENA_MAX.x - body_radius),
		clampf(global_position.y, GameConstants.ARENA_MIN.y + body_radius, GameConstants.ARENA_MAX.y - body_radius)
	)

func get_chase_position() -> Vector2:
	if hero_target == null:
		return global_position
	return Vector2(
		clampf(hero_target.global_position.x, GameConstants.ARENA_MIN.x + body_radius, GameConstants.ARENA_MAX.x - body_radius),
		clampf(hero_target.global_position.y, GameConstants.ARENA_MIN.y + body_radius, GameConstants.ARENA_MAX.y - body_radius)
	)

func _refresh_health_bar() -> void:
	health_bar.max_value = max_hp
	health_bar.value = maxf(0.0, hp)
	_refresh_vulnerability_label()

func apply_vulnerability_stack(school_id: StringName) -> void:
	var current := int(vulnerability_stacks.get(school_id, 0))
	vulnerability_stacks[school_id] = min(current + 1, SchoolRules.VULNERABILITY_MAX_STACKS)
	vulnerability_timers[school_id] = SchoolRules.VULNERABILITY_DURATION
	_refresh_vulnerability_label()

func get_vulnerability_multiplier(school_id: StringName) -> float:
	var stacks := int(vulnerability_stacks.get(school_id, 0))
	return 1.0 + stacks * SchoolRules.VULNERABILITY_STACK_BONUS

func _tick_vulnerabilities(delta: float) -> void:
	if vulnerability_timers.is_empty():
		return

	var expired: Array[StringName] = []
	for school_id_variant in vulnerability_timers.keys():
		var school_id := school_id_variant as StringName
		var time_left := float(vulnerability_timers[school_id]) - delta
		if time_left <= 0.0:
			expired.append(school_id)
		else:
			vulnerability_timers[school_id] = time_left

	for school_id in expired:
		vulnerability_timers.erase(school_id)
		vulnerability_stacks.erase(school_id)

	if expired.size() > 0:
		_refresh_vulnerability_label()

func _apply_burn_from_fire_hit(hit_damage: float) -> void:
	var fire_stacks := int(vulnerability_stacks.get(SchoolRules.SCHOOL_FIRE, 0))
	var multiplier := minf(burn_max_multiplier, 1.0 + float(fire_stacks) * burn_stack_bonus_ratio)
	var next_tick_damage := hit_damage * burn_base_ratio * multiplier

	burn_tick_damage = maxf(burn_tick_damage, next_tick_damage)
	burn_time_left = burn_duration
	if burn_tick_left <= 0.0:
		burn_tick_left = burn_tick_interval

func _tick_burn(delta: float) -> void:
	if burn_time_left <= 0.0 or burn_tick_damage <= 0.0:
		return

	burn_time_left = maxf(0.0, burn_time_left - delta)
	burn_tick_left = maxf(0.0, burn_tick_left - delta)
	if burn_tick_left > 0.0:
		return

	burn_tick_left = burn_tick_interval
	_apply_damage(burn_tick_damage, false)
	if hp > 0.0 and GameState.show_damage_text:
		_spawn_combat_text(str(int(round(burn_tick_damage))), Color(1.0, 0.52, 0.2, 0.9), 0.9)

	if burn_time_left <= 0.0:
		burn_tick_damage = 0.0

func _refresh_vulnerability_label() -> void:
	var best_school := _get_strongest_vulnerability_school()
	if best_school == &"":
		vulnerability_label.visible = false
		return

	var stacks := int(vulnerability_stacks.get(best_school, 0))
	var element_name := String(SchoolRules.SCHOOL_DEFINITIONS.get(best_school, {}).get("name", ""))
	vulnerability_label.visible = true
	vulnerability_label.text = "%s x%d" % [element_name, stacks]

func _get_strongest_vulnerability_school() -> StringName:
	var best_school: StringName = &""
	var best_stacks := 0
	for school_id_variant in vulnerability_stacks.keys():
		var school_id := school_id_variant as StringName
		var stacks := int(vulnerability_stacks[school_id])
		if stacks > best_stacks:
			best_stacks = stacks
			best_school = school_id
	return best_school

func _setup_boss_tag() -> void:
	match boss_kind:
		&"wave":
			boss_tag.visible = true
			boss_tag.text = "BOSS"
			boss_tag.modulate = Color(0.64, 1.0, 0.72, 1.0)
		&"mini":
			boss_tag.visible = true
			boss_tag.text = "MINI"
			boss_tag.modulate = Color(1.0, 0.92, 0.42, 1.0)
		&"grand":
			boss_tag.visible = true
			boss_tag.text = "GRAND"
			boss_tag.modulate = Color(1.0, 0.45, 0.45, 1.0)
		&"apex":
			boss_tag.visible = true
			boss_tag.text = "APEX"
			boss_tag.modulate = Color(0.84, 0.46, 1.0, 1.0)
		_:
			boss_tag.visible = false

func _play_hit_feedback() -> void:
	body.modulate = HIT_FLASH_COLOR
	body.scale = Vector2(1.08, 1.08)

	var tween := create_tween()
	tween.tween_property(body, "modulate", DEFAULT_MODULATE, 0.08)
	tween.parallel().tween_property(body, "scale", Vector2.ONE, 0.08)

func _spawn_death_burst() -> void:
	if DeathBurstScene == null or get_parent() == null:
		return

	var burst := DeathBurstScene.instantiate() as Node2D
	if burst == null:
		return

	burst.global_position = global_position
	if burst.has_method("setup"):
		burst.call("setup", body.color, body_radius)
	get_parent().add_child(burst)

func _spawn_combat_text(text: String, color: Color, scale_value: float) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.z_index = 100
	label.scale = Vector2.ONE * scale_value
	label.position = Vector2(-20.0, -40.0)
	add_child(label)

	var jitter := Vector2(randf_range(-14.0, 14.0), randf_range(-4.0, 4.0))
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0.0, -28.0) + jitter, 0.34)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.34)
	tween.finished.connect(label.queue_free)
