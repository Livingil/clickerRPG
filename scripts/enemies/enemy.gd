extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

const DEFAULT_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)
const HIT_FLASH_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const DeathBurstScene: PackedScene = preload("res://scenes/effects/death_burst.tscn")

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
@export var normal_enemy_type: StringName = GameConstants.ENEMY_TYPE_BASIC
@export var server_instance_id: String = ""
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
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var hp: float = 0.0
var attack_cooldown_left: float = 0.0
var vulnerability_stacks: Dictionary = {}
var vulnerability_timers: Dictionary = {}
var burn_time_left: float = 0.0
var burn_tick_left: float = 0.0
var burn_tick_damage: float = 0.0
var freeze_time_left: float = 0.0
var freeze_internal_cooldown_left: float = 0.0
var lightning_discharge_cooldown_left: float = 0.0

var hero_target: Hero

func _ready() -> void:
	add_to_group("enemies")
	_apply_normal_enemy_visual()
	hp = max_hp
	attack_cooldown_left = randf_range(0.05, attack_cooldown)
	_setup_boss_tag()
	_refresh_health_bar()
	SignalBus.emit_enemy_spawned(self)

func _physics_process(delta: float) -> void:
	_tick_control_status(delta)
	movement_component.move_towards_target(hero_target, delta)
	_tick_attack(delta)
	_tick_vulnerabilities(delta)
	_tick_burn(delta)

func set_target(hero: Hero) -> void:
	hero_target = hero

func take_damage(amount: float) -> void:
	_apply_damage(amount, true)

func _apply_damage(amount: float, show_feedback: bool) -> void:
	var damage_taken: float = CombatStats.apply_defense(amount, get_effective_defense())
	_apply_resolved_damage(damage_taken, show_feedback)

func _apply_resolved_damage(damage_taken: float, show_feedback: bool) -> void:
	hp -= damage_taken
	if show_feedback:
		_play_hit_feedback()
	_refresh_health_bar()
	if hp <= 0.0:
		die()

func take_school_damage(amount: float, school_id: StringName) -> void:
	var school_damage: float = amount * get_vulnerability_multiplier(school_id)
	take_damage(school_damage)
	apply_vulnerability_stack(school_id)
	if school_id == SchoolRules.SCHOOL_FIRE:
		_apply_burn_from_fire_hit(school_damage)
	elif school_id == SchoolRules.SCHOOL_WATER:
		_apply_water_chill_from_hit()
	elif school_id == SchoolRules.SCHOOL_LIGHTNING:
		_apply_lightning_charge_from_hit(school_damage, 999.0)

func receive_school_hit(amount: float, school_id: StringName, attacker_accuracy: float) -> bool:
	var hit_chance: float = CombatStats.compute_hit_chance(attacker_accuracy, evasion)
	if randf() > hit_chance:
		if GameState.show_miss_text:
			_spawn_combat_text("MISS", Color(0.85, 0.88, 1.0, 1.0), 1.0)
		return false
	var school_damage: float = amount * get_vulnerability_multiplier(school_id)
	take_damage(school_damage)
	apply_vulnerability_stack(school_id)
	if school_id == SchoolRules.SCHOOL_FIRE:
		_apply_burn_from_fire_hit(school_damage)
	elif school_id == SchoolRules.SCHOOL_WATER:
		_apply_water_chill_from_hit()
	elif school_id == SchoolRules.SCHOOL_LIGHTNING:
		_apply_lightning_charge_from_hit(school_damage, attacker_accuracy)
	if GameState.show_damage_text:
		_spawn_combat_text(str(int(round(school_damage))), Color(1.0, 0.86, 0.46, 1.0), 1.0)
	return true

func receive_school_crit_hit(amount: float, school_id: StringName, attacker_accuracy: float) -> bool:
	var hit: bool = receive_school_hit(amount, school_id, attacker_accuracy)
	if hit and GameState.show_crit_text:
		_spawn_combat_text("CRIT", Color(1.0, 0.45, 0.2, 1.0), 1.1)
	return hit

func receive_resolved_school_hit(attack_result: Dictionary, school_id: StringName, attacker_accuracy: float) -> bool:
	if not bool(attack_result.get("hit", false)):
		if GameState.show_miss_text:
			_spawn_combat_text("MISS", Color(0.85, 0.88, 1.0, 1.0), 1.0)
		return false
	var school_damage := float(attack_result.get("schoolDamage", 0.0))
	var damage_taken := float(attack_result.get("damageTaken", school_damage))
	_apply_resolved_damage(damage_taken, true)
	apply_vulnerability_stack(school_id)
	if school_id == SchoolRules.SCHOOL_FIRE:
		_apply_burn_from_fire_hit(school_damage)
	elif school_id == SchoolRules.SCHOOL_WATER:
		_apply_water_chill_from_hit()
	elif school_id == SchoolRules.SCHOOL_LIGHTNING:
		_apply_lightning_charge_from_hit(school_damage, attacker_accuracy)
	if GameState.show_damage_text:
		_spawn_combat_text(str(int(round(school_damage))), Color(1.0, 0.86, 0.46, 1.0), 1.0)
	if bool(attack_result.get("isCrit", false)) and GameState.show_crit_text:
		_spawn_combat_text("CRIT", Color(1.0, 0.45, 0.2, 1.0), 1.1)
	return true

func die() -> void:
	_spawn_death_burst()
	_claim_death_rewards()
	SignalBus.emit_enemy_killed(self)
	died.emit(self)
	queue_free()

func _claim_death_rewards() -> void:
	var echo_gain: int = GameState.get_echo_gain_for_enemy(boss_kind, wave_number)
	if BackendClient.queue_enemy_reward(server_instance_id, reward_gold, reward_essence, echo_gain):
		return
	GameState.add_gold(reward_gold)
	GameState.add_essence(reward_essence)
	GameState.add_echo(echo_gain)

func _tick_attack(delta: float) -> void:
	if hero_target == null:
		return
	if hero_target.hp <= 0.0:
		return
	if is_control_locked():
		return

	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta * get_attack_recovery_multiplier())
	var distance: float = global_position.distance_to(hero_target.global_position)
	if distance > attack_range:
		return
	if attack_cooldown_left > 0.0:
		return

	if EnemyProjectileAttack.uses_projectile_attack(normal_enemy_type, is_boss):
		EnemyProjectileAttack.spawn_or_apply_contact_attack(self, hero_target, attack_damage, get_effective_accuracy(), body_radius)
	else:
		_resolve_and_apply_enemy_hit()
	attack_cooldown_left = attack_cooldown

func _resolve_and_apply_enemy_hit() -> void:
	if hero_target == null:
		return
	var result := await CombatResolver.resolve_enemy_attack(self, hero_target, attack_damage, get_effective_accuracy())
	if is_instance_valid(hero_target):
		hero_target.receive_resolved_enemy_hit(result, self)

func clamp_to_arena() -> void:
	global_position = Vector2(
		clampf(global_position.x, GameConstants.ARENA_MIN.x + body_radius, GameConstants.ARENA_MAX.x - body_radius),
		clampf(global_position.y, GameConstants.ARENA_MIN.y + body_radius, GameConstants.ARENA_MAX.y - body_radius)
	)

func get_chase_position() -> Vector2:
	if hero_target == null:
		return global_position
	if normal_enemy_type == GameConstants.ENEMY_TYPE_RANGED and not is_boss:
		var to_enemy: Vector2 = global_position - hero_target.global_position
		var distance: float = to_enemy.length()
		var direction: Vector2 = to_enemy.normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		if distance < GameConstants.ENEMY_RANGED_PREFERRED_DISTANCE * 0.72:
			return global_position + direction * GameConstants.ENEMY_RANGED_PREFERRED_DISTANCE
		if distance <= GameConstants.ENEMY_RANGED_PREFERRED_DISTANCE:
			return global_position
	return Vector2(
		clampf(hero_target.global_position.x, GameConstants.ARENA_MIN.x + body_radius, GameConstants.ARENA_MAX.x - body_radius),
		clampf(hero_target.global_position.y, GameConstants.ARENA_MIN.y + body_radius, GameConstants.ARENA_MAX.y - body_radius)
	)

func set_normal_enemy_type(enemy_type: StringName) -> void:
	normal_enemy_type = enemy_type
	var modifiers: Dictionary = EnemyTypeRules.get_normal_type_modifiers(normal_enemy_type)
	if modifiers.size() <= 1:
		normal_enemy_type = GameConstants.ENEMY_TYPE_BASIC
	max_hp *= float(modifiers.get("max_hp", 1.0))
	speed *= float(modifiers.get("speed", 1.0))
	attack_damage *= float(modifiers.get("attack_damage", 1.0))
	defense *= float(modifiers.get("defense", 1.0))
	evasion *= float(modifiers.get("evasion", 1.0))
	attack_range *= float(modifiers.get("attack_range", 1.0))
	attack_cooldown *= float(modifiers.get("attack_cooldown", 1.0))
	reward_gold = maxi(1, int(round(float(reward_gold) * float(modifiers.get("reward_gold", 1.0)))))
	reward_essence = maxi(1, int(round(float(reward_essence) * float(modifiers.get("reward_essence", 1.0)))))
	body_radius = float(modifiers.get("body_radius", 18.0))
	if is_node_ready():
		_apply_normal_enemy_visual()

func _refresh_health_bar() -> void:
	health_bar.max_value = max_hp
	health_bar.value = maxf(0.0, hp)
	_refresh_vulnerability_label()

func apply_vulnerability_stack(school_id: StringName) -> void:
	var current: int = int(vulnerability_stacks.get(school_id, 0))
	vulnerability_stacks[school_id] = min(current + 1, SchoolRules.VULNERABILITY_MAX_STACKS)
	vulnerability_timers[school_id] = SchoolRules.VULNERABILITY_DURATION
	_refresh_vulnerability_label()

func force_freeze(duration: float = SchoolRules.WATER_FREEZE_DURATION) -> void:
	_apply_freeze(duration, true)

func apply_water_chill_stack() -> void:
	apply_vulnerability_stack(SchoolRules.SCHOOL_WATER)
	_apply_water_chill_from_hit()

func is_control_locked() -> bool:
	return freeze_time_left > 0.0

func get_movement_speed_multiplier() -> float:
	var water_stacks: int = int(vulnerability_stacks.get(SchoolRules.SCHOOL_WATER, 0))
	return EnemySchoolEffectRules.get_movement_speed_multiplier(is_control_locked(), water_stacks)

func get_attack_recovery_multiplier() -> float:
	var water_stacks: int = int(vulnerability_stacks.get(SchoolRules.SCHOOL_WATER, 0))
	return EnemySchoolEffectRules.get_attack_recovery_multiplier(is_control_locked(), water_stacks)

func get_effective_defense() -> float:
	var earth_stacks: int = int(vulnerability_stacks.get(SchoolRules.SCHOOL_EARTH, 0))
	return EnemySchoolEffectRules.get_effective_defense(defense, earth_stacks, is_boss)

func get_effective_accuracy() -> float:
	var air_stacks: int = int(vulnerability_stacks.get(SchoolRules.SCHOOL_AIR, 0))
	return EnemySchoolEffectRules.get_effective_accuracy(accuracy, air_stacks, is_boss)

func apply_knockback_from(source_position: Vector2, distance: float) -> void:
	var direction: Vector2 = (global_position - source_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_position += direction * distance
	clamp_to_arena()

func apply_pull_towards(target_position: Vector2, distance: float) -> void:
	var direction: Vector2 = (target_position - global_position).normalized()
	if direction == Vector2.ZERO:
		return
	global_position += direction * distance
	clamp_to_arena()

func delay_next_attack(delay_seconds: float) -> void:
	var effective_delay: float = delay_seconds
	if is_boss:
		effective_delay *= SchoolRules.AIR_ATTACK_DELAY_BOSS_MULTIPLIER
	attack_cooldown_left = maxf(attack_cooldown_left, effective_delay)

func get_vulnerability_multiplier(school_id: StringName) -> float:
	var stacks: int = int(vulnerability_stacks.get(school_id, 0))
	return EnemySchoolEffectRules.get_vulnerability_multiplier(school_id, stacks)

func _tick_vulnerabilities(delta: float) -> void:
	if vulnerability_timers.is_empty():
		return

	var expired: Array[StringName] = []
	for school_id_variant in vulnerability_timers.keys():
		var school_id: StringName = school_id_variant as StringName
		var time_left: float = float(vulnerability_timers[school_id]) - delta
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
	var fire_stacks: int = int(vulnerability_stacks.get(SchoolRules.SCHOOL_FIRE, 0))
	var next_tick_damage: float = EnemySchoolEffectRules.get_next_burn_tick_damage(
		hit_damage,
		fire_stacks,
		burn_base_ratio,
		burn_stack_bonus_ratio,
		burn_max_multiplier
	)

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

func _tick_control_status(delta: float) -> void:
	var was_frozen: bool = freeze_time_left > 0.0
	freeze_time_left = maxf(0.0, freeze_time_left - delta)
	freeze_internal_cooldown_left = maxf(0.0, freeze_internal_cooldown_left - delta)
	lightning_discharge_cooldown_left = maxf(0.0, lightning_discharge_cooldown_left - delta)
	if was_frozen and freeze_time_left <= 0.0:
		body.modulate = DEFAULT_MODULATE
		_refresh_vulnerability_label()

func _apply_water_chill_from_hit() -> void:
	var water_stacks: int = int(vulnerability_stacks.get(SchoolRules.SCHOOL_WATER, 0))
	if water_stacks >= SchoolRules.VULNERABILITY_MAX_STACKS:
		_apply_freeze(SchoolRules.WATER_FREEZE_DURATION, false)

func _apply_freeze(duration: float, ignore_internal_cooldown: bool) -> void:
	if not ignore_internal_cooldown and freeze_internal_cooldown_left > 0.0:
		return
	var effective_duration: float = EnemySchoolEffectRules.get_effective_freeze_duration(duration, is_boss)
	freeze_time_left = maxf(freeze_time_left, effective_duration)
	freeze_internal_cooldown_left = SchoolRules.WATER_FREEZE_INTERNAL_COOLDOWN
	body.modulate = Color(0.68, 0.90, 1.0, 1.0)
	_refresh_vulnerability_label()
	if GameState.show_damage_text:
		_spawn_combat_text("FREEZE", Color(0.55, 0.86, 1.0, 1.0), 0.95)

func _apply_lightning_charge_from_hit(hit_damage: float, attacker_accuracy: float) -> void:
	var lightning_stacks: int = int(vulnerability_stacks.get(SchoolRules.SCHOOL_LIGHTNING, 0))
	if lightning_stacks < SchoolRules.LIGHTNING_DISCHARGE_STACKS:
		return
	if lightning_discharge_cooldown_left > 0.0:
		return
	lightning_discharge_cooldown_left = SchoolRules.LIGHTNING_DISCHARGE_INTERNAL_COOLDOWN
	vulnerability_stacks.erase(SchoolRules.SCHOOL_LIGHTNING)
	vulnerability_timers.erase(SchoolRules.SCHOOL_LIGHTNING)
	_refresh_vulnerability_label()
	var discharge_damage: float = hit_damage * SchoolRules.LIGHTNING_DISCHARGE_DAMAGE_RATIO * GameState.get_skill_proc_multiplier(&"spark_jump")
	_apply_damage(discharge_damage, false)
	if hp > 0.0 and GameState.show_damage_text:
		_spawn_combat_text("DISCHARGE", Color(1.0, 0.95, 0.35, 1.0), 0.92)
	var chain_target: Enemy = _find_lightning_discharge_chain_target()
	if chain_target != null:
		chain_target.receive_school_hit(discharge_damage * SchoolRules.LIGHTNING_DISCHARGE_CHAIN_RATIO, SchoolRules.SCHOOL_LIGHTNING, attacker_accuracy)

func _find_lightning_discharge_chain_target() -> Enemy:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var best: Enemy = null
	var best_distance_sq: float = SchoolRules.LIGHTNING_DISCHARGE_CHAIN_RANGE * SchoolRules.LIGHTNING_DISCHARGE_CHAIN_RANGE
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy is not Enemy or enemy == self:
			continue
		var enemy_node: Enemy = enemy as Enemy
		var distance_sq: float = global_position.distance_squared_to(enemy_node.global_position)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best = enemy_node
	return best

func _refresh_vulnerability_label() -> void:
	if vulnerability_stacks.is_empty() and freeze_time_left <= 0.0:
		vulnerability_label.visible = false
		return

	var parts: Array[String] = []
	if freeze_time_left > 0.0:
		parts.append("FRZ")
	for school_id in SchoolRules.SCHOOL_ORDER:
		var stacks: int = int(vulnerability_stacks.get(school_id, 0))
		if stacks <= 0:
			continue
		parts.append("%s%d" % [EnemyStatusUiRules.get_school_stack_code(school_id), stacks])
	vulnerability_label.visible = true
	vulnerability_label.text = " ".join(parts)

func _get_strongest_vulnerability_school() -> StringName:
	var best_school: StringName = &""
	var best_stacks: int = 0
	for school_id_variant in vulnerability_stacks.keys():
		var school_id: StringName = school_id_variant as StringName
		var stacks: int = int(vulnerability_stacks[school_id])
		if stacks > best_stacks:
			best_stacks = stacks
			best_school = school_id
	return best_school

func _setup_boss_tag() -> void:
	var tag_data: Dictionary = EnemyBossUiRules.get_tag_data(boss_kind)
	boss_tag.visible = bool(tag_data.get("visible", false))
	boss_tag.text = String(tag_data.get("text", ""))
	boss_tag.modulate = tag_data.get("color", Color.WHITE) as Color

func _apply_normal_enemy_visual() -> void:
	if body == null or is_boss:
		return
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = body_radius
	body.color = EnemyTypeRules.get_body_color(normal_enemy_type)
	body.polygon = EnemyTypeRules.get_body_polygon(normal_enemy_type, body_radius)

func _play_hit_feedback() -> void:
	EnemyVisualFeedback.play_hit_feedback(self, body, HIT_FLASH_COLOR, _get_body_base_modulate())

func _get_body_base_modulate() -> Color:
	return Color(0.68, 0.90, 1.0, 1.0) if freeze_time_left > 0.0 else DEFAULT_MODULATE

func _spawn_death_burst() -> void:
	EnemyVisualFeedback.spawn_death_burst(get_parent(), DeathBurstScene, global_position, body.color, body_radius)

func _spawn_combat_text(text: String, color: Color, scale_value: float) -> void:
	EnemyVisualFeedback.spawn_combat_text(self, text, color, scale_value)
