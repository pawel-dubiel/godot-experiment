class_name AbilityActionBehavior
extends ActionBehavior

var _component: AbilityComponent
var _instance: AbilityInstance

func _init(component: AbilityComponent, instance: AbilityInstance) -> void:
	if not component or not instance:
		push_error("AbilityActionBehavior requires AbilityComponent and AbilityInstance.")
		return
	_component = component
	_instance = instance

func availability(_context: GameContext) -> ActionResult:
	return _instance.availability()

func get_unavailable_reason(_context: GameContext) -> ActionResult:
	return ActionResult.success(_instance.unavailable_reason())

func get_candidate_coordinates(context: GameContext) -> ActionResult:
	var source := _component.get_entity() as GameEntity
	return _instance.definition.targeting.candidate_coordinates(source, context)

func matches_context(target: Variant, context: GameContext) -> ActionResult:
	return _validate_target(target, context)

func validate_target(target: Variant, context: GameContext) -> ActionResult:
	return _validate_target(target, context)

func create_command(target: Variant, _context: GameContext) -> ActionResult:
	if not target is MapActionTarget:
		return ActionResult.failure("Ability %s requires a MapActionTarget." % _instance.definition.ability_id)
	var source := _component.get_entity() as GameEntity
	if not source:
		return ActionResult.failure("AbilityComponent requires a GameEntity parent.")
	return ActionResult.success(AbilityCommand.new(source, _instance, target))

func _validate_target(target: Variant, context: GameContext) -> ActionResult:
	if not target is MapActionTarget:
		return ActionResult.success(false)
	var source := _component.get_entity() as GameEntity
	return _instance.definition.targeting.validate_target(source, target, context)
