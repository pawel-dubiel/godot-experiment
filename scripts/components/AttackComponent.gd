class_name AttackComponent
extends EntityComponent

## Component that enables a unit to attack.
## Acts as a CommandProvider.

@export var attack_damage: int = 10
@export_range(0, 1000, 1) var attack_range: int = 1

const ATTACK_ICON := preload("res://assets/ui/action-attack.svg")

## Returns a list of available commands for this unit.
## In a full UI implementation, the UI would call this when the unit is selected.
func get_action_descriptors(_context: GameContext) -> Array[ActionDescriptor]:
	var descriptor := ActionDescriptor.new(
		&"attack",
		"Attack",
		ATTACK_ICON,
		ActionDescriptor.TargetingMode.UNIT,
		func(_current_context): return true,
		func(_current_context): return "",
		func(_current_context): return _get_candidate_coordinates(),
		func(target, current_context): return _is_valid_action_target(target, current_context),
		func(target, current_context): return _is_valid_action_target(target, current_context),
		func(target, _current_context): return create_attack_command(target.entity) if target is MapActionTarget and target.entity else null
	)
	return [descriptor]

func _get_candidate_coordinates() -> Variant:
	var entity := get_entity() as GameEntity
	if not entity:
		return "AttackComponent requires a GameEntity parent to enumerate candidates."
	if attack_range < 0:
		return "AttackComponent attack_range must be non-negative."
	return HexCoordinates.within_range(entity.grid_position, attack_range)

func _is_valid_action_target(target: Variant, context: GameContext) -> bool:
	if not target is MapActionTarget or not target.entity or target.entity == get_entity():
		return false
	return create_attack_command(target.entity).validate(context)

## Factory method to create an attack command against a specific target
func create_attack_command(target: Node) -> AttackCommand:
	var cmd = AttackCommand.new(get_entity(), target, attack_damage, attack_range)
	return cmd
