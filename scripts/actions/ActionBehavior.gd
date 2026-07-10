class_name ActionBehavior
extends RefCounted

func availability(_context: GameContext) -> ActionResult:
	return ActionResult.failure("ActionBehavior.availability() must be implemented.")

func get_unavailable_reason(_context: GameContext) -> ActionResult:
	return ActionResult.failure("ActionBehavior.get_unavailable_reason() must be implemented.")

func get_candidate_coordinates(_context: GameContext) -> ActionResult:
	return ActionResult.failure("ActionBehavior.get_candidate_coordinates() must be implemented.")

func matches_context(_target: Variant, _context: GameContext) -> ActionResult:
	return ActionResult.failure("ActionBehavior.matches_context() must be implemented.")

func validate_target(_target: Variant, _context: GameContext) -> ActionResult:
	return ActionResult.failure("ActionBehavior.validate_target() must be implemented.")

func create_command(_target: Variant, _context: GameContext) -> ActionResult:
	return ActionResult.failure("ActionBehavior.create_command() must be implemented.")
