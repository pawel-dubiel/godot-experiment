class_name OutcomeEffect
extends Resource

func validate_contract() -> String:
	return "OutcomeEffect.validate_contract() must be implemented."

func apply(_context: GameContext, _source: GameEntity, _outcome: ResolvedOutcome) -> ActionResult:
	return ActionResult.failure("OutcomeEffect.apply() must be implemented.")
