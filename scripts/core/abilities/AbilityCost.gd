class_name AbilityCost
extends Resource

func validate_contract() -> String:
	return "AbilityCost.validate_contract() must be implemented."

func can_pay(_source: GameEntity, _context: GameContext) -> ActionResult:
	return ActionResult.failure("AbilityCost.can_pay() must be implemented.")

func pay(_source: GameEntity, _context: GameContext) -> ActionResult:
	return ActionResult.failure("AbilityCost.pay() must be implemented.")
