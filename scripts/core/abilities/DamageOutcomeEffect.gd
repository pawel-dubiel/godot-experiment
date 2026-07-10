class_name DamageOutcomeEffect
extends OutcomeEffect

func validate_contract() -> String:
	return ""

func apply(_context: GameContext, source: GameEntity, outcome: ResolvedOutcome) -> ActionResult:
	if not source:
		return ActionResult.failure("DamageOutcomeEffect requires a GameEntity source.")
	if not outcome or not outcome.target:
		return ActionResult.failure("DamageOutcomeEffect requires a target outcome.")
	if not outcome.is_successful:
		return ActionResult.success(false)
	if not outcome.target.entity:
		return ActionResult.failure("DamageOutcomeEffect requires an entity target for a successful outcome.")
	var amount := roundi(outcome.magnitude)
	if amount < 0:
		return ActionResult.failure("DamageOutcomeEffect cannot apply negative damage.")
	outcome.target.entity.send_message("incoming_damage", {"amount": amount, "source": source})
	return ActionResult.success(true)
