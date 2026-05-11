extends Node2D
class_name MagicProjectile

var speed: float = GameConstants.HERO_PROJECTILE_SPEED
var damage: float = 0.0
var is_crit: bool = false
var target: Enemy
var school_id: StringName = &"fire"
@onready var body: Polygon2D = $Body

func setup(target_enemy: Enemy, projectile_damage: float, crit: bool, attack_school_id: StringName) -> void:
	target = target_enemy
	damage = projectile_damage
	is_crit = crit
	school_id = attack_school_id
	if is_node_ready():
		_apply_school_visual()

func _ready() -> void:
	_apply_school_visual()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var step := speed * delta

	if distance <= step:
		target.take_school_damage(damage, school_id)
		queue_free()
		return

	global_position += to_target.normalized() * step

func _apply_school_visual() -> void:
	match school_id:
		&"fire":
			body.color = Color(1.0, 0.45, 0.18, 1.0)
		&"water":
			body.color = Color(0.3, 0.68, 1.0, 1.0)
		&"earth":
			body.color = Color(0.63, 0.5, 0.34, 1.0)
		&"air":
			body.color = Color(0.84, 0.9, 1.0, 1.0)
		&"lightning":
			body.color = Color(1.0, 0.95, 0.3, 1.0)
