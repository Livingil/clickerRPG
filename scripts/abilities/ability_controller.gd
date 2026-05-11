extends Node
class_name AbilityController

var active_abilities: Array[AbilityBase] = []
var active_skill_ids: Array[StringName] = []
var hero: Hero
var battlefield: Battlefield

func _ready() -> void:
	hero = get_parent().get_node("Hero") as Hero
	battlefield = get_parent().get_node("Battlefield") as Battlefield
	GameState.school_state_changed.connect(_rebuild_active_abilities)
	_rebuild_active_abilities()

func _process(delta: float) -> void:
	for ability in active_abilities:
		ability.tick(delta)

func handle_hero_attack(_target: Enemy, _damage: float, _is_crit: bool) -> void:
	pass

func get_active_ability_names() -> Array[String]:
	var names: Array[String] = []
	for ability in active_abilities:
		names.append(ability.get_display_name())
	return names

func spawn_effect(effect: Node2D) -> void:
	if effect == null:
		return
	if battlefield == null:
		return
	battlefield.effects_container.add_child(effect)

func _rebuild_active_abilities() -> void:
	var desired_skill_ids := GameState.get_equipped_skill_ids()
	if desired_skill_ids == active_skill_ids:
		return

	active_skill_ids = desired_skill_ids.duplicate()
	active_abilities.clear()
	for skill_id in active_skill_ids:
		_append_ability_from_skill_id(skill_id)

func _append_ability_from_skill_id(skill_id: StringName) -> void:
	match skill_id:
		&"ember_chain":
			active_abilities.append(FireEmberChainAbility.new(self))
		&"cinder_burst":
			active_abilities.append(FireCinderBurstAbility.new(self))
