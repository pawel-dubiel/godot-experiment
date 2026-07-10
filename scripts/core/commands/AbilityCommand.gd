class_name AbilityCommand
extends Command

var ability: AbilityInstance
var action_target: MapActionTarget

func _init(p_source: GameEntity, p_ability: AbilityInstance, p_target: MapActionTarget) -> void:
	super(p_source, p_target.entity if p_target else null)
	ability = p_ability
	action_target = p_target

func validate(context: GameContext) -> bool:
	if not source is GameEntity:
		push_error("AbilityCommand requires a GameEntity source.")
		return false
	if not ability or not action_target:
		push_error("AbilityCommand requires AbilityInstance and MapActionTarget.")
		return false
	var definition_error := ability.definition.validate_contract()
	if not definition_error.is_empty():
		push_error(definition_error)
		return false
	var available := ability.availability()
	if not available.is_success() or not available.value:
		return false
	var target_validation := ability.definition.targeting.validate_target(source, action_target, context)
	if not target_validation.is_success():
		push_error(target_validation.error)
		return false
	if not target_validation.value:
		return false
	for requirement in ability.definition.requirements:
		if not requirement.check(context, source, action_target.entity):
			return false
	for cost in ability.definition.costs:
		var payment_check := cost.can_pay(source, context)
		if not payment_check.is_success():
			push_error(payment_check.error)
			return false
		if not payment_check.value:
			return false
	return true

func execute(context: GameContext) -> void:
	if not validate(context):
		failed.emit("Ability validation failed")
		return
	var resolution_result := ability.definition.resolution.resolve(ability.definition, source, action_target, context)
	if not resolution_result.is_success():
		failed.emit(resolution_result.error)
		return
	if not resolution_result.value is Array:
		failed.emit("Ability resolution must return Array[ResolvedOutcome].")
		return
	var outcomes: Array[ResolvedOutcome] = []
	for outcome_value in resolution_result.value:
		if not outcome_value is ResolvedOutcome:
			failed.emit("Ability resolution returned a value that is not ResolvedOutcome.")
			return
		outcomes.append(outcome_value)
	for cost in ability.definition.costs:
		var payment_result := cost.pay(source, context)
		if not payment_result.is_success():
			failed.emit(payment_result.error)
			return
	for outcome in outcomes:
		for effect in ability.definition.outcome_effects:
			var effect_result := effect.apply(context, source, outcome)
			if not effect_result.is_success():
				failed.emit(effect_result.error)
				return
	var commit_result := ability.commit_use()
	if not commit_result.is_success():
		failed.emit(commit_result.error)
		return
	executed.emit()
