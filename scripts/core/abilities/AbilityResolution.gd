class_name AbilityResolution
extends Resource

func validate_contract() -> String:
	return "AbilityResolution.validate_contract() must be implemented."

func resolve(_definition: AbilityDefinition, _source: GameEntity, _target: MapActionTarget, _context: GameContext) -> ActionResult:
	return ActionResult.failure("AbilityResolution.resolve() must be implemented.")
