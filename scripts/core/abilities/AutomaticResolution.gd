class_name AutomaticResolution
extends AbilityResolution

func validate_contract() -> String:
	return ""

func resolve(definition: AbilityDefinition, source: GameEntity, target: MapActionTarget, _context: GameContext) -> ActionResult:
	if not definition:
		return ActionResult.failure("AutomaticResolution requires an AbilityDefinition.")
	if not source:
		return ActionResult.failure("AutomaticResolution requires a GameEntity source.")
	if not target:
		return ActionResult.failure("AutomaticResolution requires a MapActionTarget.")
	var outcomes: Array[ResolvedOutcome] = [ResolvedOutcome.hit(target, definition.base_power)]
	return ActionResult.success(outcomes)
