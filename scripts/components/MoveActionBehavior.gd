class_name MoveActionBehavior
extends ActionBehavior

var _movement: MovementComponent

func _init(movement: MovementComponent) -> void:
	if not movement:
		push_error("MoveActionBehavior requires a MovementComponent.")
		return
	_movement = movement

func availability(_context: GameContext) -> ActionResult:
	return ActionResult.success(_movement.has_move_validator())

func get_unavailable_reason(_context: GameContext) -> ActionResult:
	var reason := "" if _movement.has_move_validator() else "Movement validation is not configured."
	return ActionResult.success(reason)

func get_candidate_coordinates(_context: GameContext) -> ActionResult:
	return _movement.get_candidate_coordinates()

func matches_context(target: Variant, context: GameContext) -> ActionResult:
	return ActionResult.success(_movement.is_valid_action_target(target, context))

func validate_target(target: Variant, context: GameContext) -> ActionResult:
	return ActionResult.success(_movement.is_valid_action_target(target, context))

func create_command(target: Variant, _context: GameContext) -> ActionResult:
	if not target is MapActionTarget:
		return ActionResult.failure("Move action requires a MapActionTarget.")
	return ActionResult.success(MoveCommand.new(_movement.get_entity(), target.grid_position, _movement))
