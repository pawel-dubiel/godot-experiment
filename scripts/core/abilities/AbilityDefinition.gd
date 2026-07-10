class_name AbilityDefinition
extends Resource

@export var ability_id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var targeting: AbilityTargeting
@export var base_power: float
@export var requirements: Array[Requirement] = []
@export var costs: Array[AbilityCost] = []
@export var resolution: AbilityResolution
@export var outcome_effects: Array[OutcomeEffect] = []
@export_range(0, 1000, 1) var cooldown_turns: int = 0
@export var uses_charges := false
@export_range(1, 1000, 1) var maximum_charges: int = 1

func validate_contract() -> String:
	if ability_id.is_empty():
		return "AbilityDefinition requires a non-empty ability_id."
	if display_name.strip_edges().is_empty():
		return "AbilityDefinition %s requires display_name." % ability_id
	if not icon:
		return "AbilityDefinition %s requires an icon." % ability_id
	if not targeting:
		return "AbilityDefinition %s requires AbilityTargeting." % ability_id
	var targeting_error := targeting.validate_contract()
	if not targeting_error.is_empty():
		return "AbilityDefinition %s: %s" % [ability_id, targeting_error]
	if not is_finite(base_power) or base_power < 0.0:
		return "AbilityDefinition %s base_power must be finite and non-negative." % ability_id
	if not resolution:
		return "AbilityDefinition %s requires AbilityResolution." % ability_id
	var resolution_error := resolution.validate_contract()
	if not resolution_error.is_empty():
		return "AbilityDefinition %s: %s" % [ability_id, resolution_error]
	if outcome_effects.is_empty():
		return "AbilityDefinition %s requires at least one OutcomeEffect." % ability_id
	for effect in outcome_effects:
		if not effect:
			return "AbilityDefinition %s contains a missing OutcomeEffect." % ability_id
		var effect_error := effect.validate_contract()
		if not effect_error.is_empty():
			return "AbilityDefinition %s: %s" % [ability_id, effect_error]
	for requirement in requirements:
		if not requirement:
			return "AbilityDefinition %s contains a missing Requirement." % ability_id
		var requirement_error := requirement.validate_contract()
		if not requirement_error.is_empty():
			return "AbilityDefinition %s: %s" % [ability_id, requirement_error]
	for cost in costs:
		if not cost:
			return "AbilityDefinition %s contains a missing AbilityCost." % ability_id
		var cost_error := cost.validate_contract()
		if not cost_error.is_empty():
			return "AbilityDefinition %s: %s" % [ability_id, cost_error]
	if uses_charges and maximum_charges <= 0:
		return "AbilityDefinition %s maximum_charges must be positive when charges are enabled." % ability_id
	return ""
