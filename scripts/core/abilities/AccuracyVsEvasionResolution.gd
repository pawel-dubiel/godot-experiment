class_name AccuracyVsEvasionResolution
extends AbilityResolution

@export var accuracy_stat_id: StringName
@export var evasion_stat_id: StringName
@export_range(0.0, 1.0, 0.01) var base_hit_chance: float = 0.5
@export var stat_difference_factor: float = 0.01
@export_range(0.0, 1.0, 0.01) var minimum_hit_chance: float = 0.0
@export_range(0.0, 1.0, 0.01) var maximum_hit_chance: float = 1.0

func validate_contract() -> String:
	if accuracy_stat_id.is_empty():
		return "AccuracyVsEvasionResolution requires accuracy_stat_id."
	if evasion_stat_id.is_empty():
		return "AccuracyVsEvasionResolution requires evasion_stat_id."
	for probability in [base_hit_chance, minimum_hit_chance, maximum_hit_chance]:
		if not is_finite(probability) or probability < 0.0 or probability > 1.0:
			return "AccuracyVsEvasionResolution probabilities must be finite values from zero to one."
	if not is_finite(stat_difference_factor):
		return "AccuracyVsEvasionResolution stat_difference_factor must be finite."
	if minimum_hit_chance > maximum_hit_chance:
		return "AccuracyVsEvasionResolution minimum_hit_chance must not exceed maximum_hit_chance."
	return ""

func resolve(definition: AbilityDefinition, source: GameEntity, target: MapActionTarget, context: GameContext) -> ActionResult:
	var contract_error := validate_contract()
	if not contract_error.is_empty():
		return ActionResult.failure(contract_error)
	if not definition or not source or not target or not target.entity:
		return ActionResult.failure("AccuracyVsEvasionResolution requires definition, source, and an entity target.")
	if not context or not context.random_source:
		return ActionResult.failure("AccuracyVsEvasionResolution requires GameContext.random_source.")
	var source_stats := source.get_component(StatsComponent) as StatsComponent
	var target_stats := target.entity.get_component(StatsComponent) as StatsComponent
	if not source_stats:
		return ActionResult.failure("AccuracyVsEvasionResolution source %s requires StatsComponent." % source.name)
	if not target_stats:
		return ActionResult.failure("AccuracyVsEvasionResolution target %s requires StatsComponent." % target.entity.name)
	var accuracy_result := source_stats.stat_value(accuracy_stat_id)
	if not accuracy_result.is_success():
		return accuracy_result
	var evasion_result := target_stats.stat_value(evasion_stat_id)
	if not evasion_result.is_success():
		return evasion_result
	var hit_chance := clampf(
		base_hit_chance + (accuracy_result.value - evasion_result.value) * stat_difference_factor,
		minimum_hit_chance,
		maximum_hit_chance
	)
	var random_result := context.random_source.next_float()
	if not random_result.is_success():
		return random_result
	var outcomes: Array[ResolvedOutcome] = []
	if random_result.value < hit_chance:
		outcomes.append(ResolvedOutcome.hit(target, definition.base_power))
	else:
		outcomes.append(ResolvedOutcome.miss(target))
	return ActionResult.success(outcomes)
