extends Node2D
class_name Hero

signal attack_performed(target: Enemy, damage: float, is_crit: bool)
signal died

@onready var stats_component: HeroStatsComponent = $StatsComponent
@onready var attack_component: HeroAttackComponent = $AttackComponent
@onready var movement_component: Node = $MovementComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $HealthBar
@onready var body: Polygon2D = $Body

var max_hp: float = GameConstants.HERO_BASE_HP
var hp: float = GameConstants.HERO_BASE_HP
var body_radius: float = 24.0

func _ready() -> void:
	reset_for_new_run()
	attack_component.attack_performed.connect(_on_attack_performed)
	GameState.hero_stats_changed.connect(_on_hero_stats_changed)

func _physics_process(delta: float) -> void:
	if hp <= 0.0:
		return
	movement_component.tick(delta)
	attack_component.tick(delta)

func set_battlefield(battlefield: Battlefield) -> void:
	attack_component.set_battlefield(battlefield)

func _on_attack_performed(target: Enemy, damage: float, is_crit: bool) -> void:
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
	else:
		_play_body_pulse(Color(1.0, 0.95, 0.85, 1.0), 1.08, 0.09)
	attack_performed.emit(target, damage, is_crit)
	SignalBus.emit_hero_attack_performed(target, damage, is_crit)

func _on_hero_stats_changed() -> void:
	stats_component.rebuild_from_game_state()
	_apply_runtime_stats(false)

func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return

	var damage_taken := CombatStats.apply_defense(amount, stats_component.get_defense())
	hp = maxf(0.0, hp - damage_taken)
	if GameState.show_hero_damage_text:
		_spawn_combat_text(str(int(round(damage_taken))), Color(1.0, 0.55, 0.55, 1.0), 1.0)
	_refresh_health_bar()
	if hp <= 0.0:
		die()

func receive_enemy_hit(amount: float, enemy_accuracy: float, attacker: Enemy = null) -> bool:
	if GameState.should_block_incoming_hit():
		if GameState.show_hero_miss_text:
			_spawn_combat_text("BLOCK", Color(0.75, 1.0, 0.8, 1.0), 0.95)
		return false
	var hit_chance := CombatStats.compute_hit_chance(enemy_accuracy, stats_component.get_evasion())
	if randf() > hit_chance:
		if GameState.show_hero_miss_text:
			_spawn_combat_text("MISS", Color(0.82, 0.95, 1.0, 1.0), 0.95)
		return false
	var hp_before := hp
	take_damage(amount)
	GameState.on_hero_damaged(self, attacker, maxf(0.0, hp_before - hp))
	if GameState.get_runtime_attack_speed_multiplier() > 1.0:
		_spawn_combat_text("HASTE", Color(0.8, 1.0, 0.7, 1.0), 0.85)
	if GameState.get_clone_attack_multiplier() > 0.0:
		_spawn_combat_text("CLONE", Color(0.72, 0.72, 1.0, 1.0), 0.85)
	return true

func reset_for_new_run() -> void:
	global_position = GameConstants.HERO_START_POSITION
	stats_component.rebuild_from_game_state()
	_apply_runtime_stats(true)

func die() -> void:
	died.emit()
	SignalBus.emit_hero_died()

func play_skill_cast(skill_name: StringName) -> void:
	match skill_name:
		&"ember_chain":
			_play_body_pulse(Color(1.0, 0.55, 0.25, 1.0), 1.14, 0.16)
		&"cinder_burst":
			_play_body_pulse(Color(1.0, 0.35, 0.12, 1.0), 1.2, 0.18)
		&"ash_storm":
			_play_body_pulse(Color(0.92, 0.32, 0.08, 1.0), 1.26, 0.22)
		_:
			_play_body_pulse(Color(0.85, 0.85, 1.0, 1.0), 1.1, 0.12)

func _refresh_health_bar() -> void:
	health_bar.max_value = max_hp
	health_bar.value = hp

func clamp_to_arena() -> void:
	global_position = Vector2(
		clampf(global_position.x, GameConstants.ARENA_MIN.x + body_radius, GameConstants.ARENA_MAX.x - body_radius),
		clampf(global_position.y, GameConstants.ARENA_MIN.y + body_radius, GameConstants.ARENA_MAX.y - body_radius)
	)

func _play_body_pulse(color: Color, scale_amount: float, duration: float) -> void:
	body.modulate = color
	body.scale = Vector2.ONE * scale_amount
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color(1, 1, 1, 1), duration)
	tween.parallel().tween_property(body, "scale", Vector2.ONE, duration)

func _apply_runtime_stats(restore_full_hp: bool) -> void:
	var previous_hp_ratio := 1.0
	if max_hp > 0.0:
		previous_hp_ratio = hp / max_hp
	max_hp = stats_component.get_max_hp()
	if restore_full_hp:
		hp = max_hp
	else:
		hp = clampf(max_hp * previous_hp_ratio, 0.0, max_hp)
	_refresh_health_bar()

func _spawn_combat_text(text: String, color: Color, scale_value: float) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.z_index = 100
	label.scale = Vector2.ONE * scale_value
	label.position = Vector2(-20.0, -52.0)
	add_child(label)

	var jitter := Vector2(randf_range(-12.0, 12.0), randf_range(-4.0, 4.0))
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0.0, -24.0) + jitter, 0.32)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.32)
	tween.finished.connect(label.queue_free)
