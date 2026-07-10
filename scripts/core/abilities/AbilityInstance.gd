class_name AbilityInstance
extends RefCounted

var definition: AbilityDefinition
var remaining_charges: int
var cooldown_remaining: int

func _init(p_definition: AbilityDefinition) -> void:
	definition = p_definition
	remaining_charges = definition.maximum_charges if definition.uses_charges else 0
	cooldown_remaining = 0

static func create(definition: AbilityDefinition) -> ActionResult:
	if not definition:
		return ActionResult.failure("AbilityInstance.create requires an AbilityDefinition.")
	var contract_error := definition.validate_contract()
	if not contract_error.is_empty():
		return ActionResult.failure(contract_error)
	return ActionResult.success(AbilityInstance.new(definition))

func availability() -> ActionResult:
	if cooldown_remaining > 0:
		return ActionResult.success(false)
	if definition.uses_charges and remaining_charges <= 0:
		return ActionResult.success(false)
	return ActionResult.success(true)

func unavailable_reason() -> String:
	if cooldown_remaining > 0:
		return "%s is cooling down for %d more turn(s)." % [definition.display_name, cooldown_remaining]
	if definition.uses_charges and remaining_charges <= 0:
		return "%s has no charges remaining." % definition.display_name
	return ""

func commit_use() -> ActionResult:
	var available := availability()
	if not available.is_success():
		return available
	if not available.value:
		return ActionResult.failure("AbilityInstance %s cannot be used: %s" % [definition.ability_id, unavailable_reason()])
	if definition.uses_charges:
		remaining_charges -= 1
	cooldown_remaining = definition.cooldown_turns
	return ActionResult.success(true)

func advance_turn() -> ActionResult:
	if cooldown_remaining > 0:
		cooldown_remaining -= 1
	return ActionResult.success(true)
