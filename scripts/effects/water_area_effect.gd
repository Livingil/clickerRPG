extends Node2D
class_name WaterAreaEffect

enum AreaKind { PUDDLE, TIDAL, BLIZZARD }

var kind: AreaKind = AreaKind.PUDDLE
var radius: float = 120.0
var duration: float = 3.0
var tick_interval: float = 0.5
var damage_per_tick: float = 0.0
var accuracy: float = 0.0
var heal_per_hit: float = 0.0
var max_heal_per_tick: float = 0.0
var hero: Hero
var life_time: float = 0.0
var tick_left: float = 0.0
var tick_in_progress: bool = false

func setup(
	center_position: Vector2,
	area_kind: AreaKind,
	area_radius: float,
	area_duration: float,
	area_tick_interval: float,
	tick_damage: float,
	attack_accuracy: float,
	owner_hero: Hero = null,
	heal_value_per_hit: float = 0.0,
	heal_cap_per_tick: float = 0.0
) -> void:
	global_position = center_position
	kind = area_kind
	radius = area_radius
	duration = area_duration
	tick_interval = area_tick_interval
	damage_per_tick = tick_damage
	accuracy = attack_accuracy
	hero = owner_hero
	heal_per_hit = heal_value_per_hit
	max_heal_per_tick = heal_cap_per_tick

func _ready() -> void:
	tick_left = 0.05
	queue_redraw()

func _process(delta: float) -> void:
	life_time += delta
	tick_left -= delta
	if tick_left <= 0.0 and not tick_in_progress:
		tick_left += tick_interval
		tick_in_progress = true
		_apply_tick()
	queue_redraw()
	if life_time >= duration:
		queue_free()

func _draw() -> void:
	var alpha := 1.0 - clampf(life_time / maxf(0.001, duration), 0.0, 1.0)
	match kind:
		AreaKind.PUDDLE:
			_draw_puddle(alpha)
		AreaKind.TIDAL:
			_draw_tidal(alpha)
		AreaKind.BLIZZARD:
			_draw_blizzard(alpha)

func _apply_tick() -> void:
	var hero_stats: HeroStatsComponent = hero.stats_component if hero != null else null
	if hero_stats == null:
		tick_in_progress = false
		return
	var healed_this_tick := 0.0
	var targets: Array[Enemy] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy is not Enemy:
			continue
		var enemy_node := enemy as Enemy
		if not _contains_enemy(enemy_node):
			continue
		targets.append(enemy_node)
	var hit_targets: Array[Enemy] = await CombatResolver.apply_school_hit_batch(hero_stats, targets, SchoolRules.SCHOOL_WATER, damage_per_tick)
	if hit_targets.size() > 0 and hero != null and heal_per_hit > 0.0:
		for _i in range(hit_targets.size()):
			var remaining_heal := max_heal_per_tick - healed_this_tick if max_heal_per_tick > 0.0 else heal_per_hit
			if remaining_heal <= 0.0:
				break
			var heal_value := minf(heal_per_hit, remaining_heal)
			hero.heal(heal_value)
			healed_this_tick += heal_value
	tick_in_progress = false

func _contains_enemy(enemy: Enemy) -> bool:
	if kind == AreaKind.BLIZZARD:
		return _is_inside_arena(enemy.global_position)
	return enemy.global_position.distance_to(global_position) <= radius

func _is_inside_arena(world_position: Vector2) -> bool:
	return world_position.x >= GameConstants.ARENA_MIN.x and world_position.x <= GameConstants.ARENA_MAX.x and world_position.y >= GameConstants.ARENA_MIN.y and world_position.y <= GameConstants.ARENA_MAX.y

func _draw_puddle(alpha: float) -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.25, 0.62, 1.0, 0.18 * alpha))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.64, 0.90, 1.0, 0.72 * alpha), 2.0, true)
	draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 40, Color(0.90, 0.98, 1.0, 0.32 * alpha), 1.5, true)

func _draw_tidal(alpha: float) -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.10, 0.40, 0.78, 0.16 * alpha))
	for i in range(3):
		var wave_radius := radius * (0.35 + 0.22 * float(i)) + sin((life_time * 3.0) + float(i)) * 6.0
		draw_arc(Vector2.ZERO, wave_radius, 0.0, TAU, 56, Color(0.55, 0.86, 1.0, 0.44 * alpha), 2.0, true)

func _draw_blizzard(alpha: float) -> void:
	var arena_size := GameConstants.ARENA_MAX - GameConstants.ARENA_MIN
	var top_left := to_local(GameConstants.ARENA_MIN)
	draw_rect(Rect2(top_left, arena_size), Color(0.40, 0.72, 1.0, 0.08 * alpha), true)
	for i in range(24):
		var t := float(i) / 24.0
		var x := top_left.x + fmod((t * arena_size.x + life_time * 120.0), arena_size.x)
		var y := top_left.y + fmod((float(i * 37) + life_time * 190.0), arena_size.y)
		draw_line(Vector2(x, y), Vector2(x - 16.0, y + 28.0), Color(0.85, 0.96, 1.0, 0.46 * alpha), 2.0, true)
