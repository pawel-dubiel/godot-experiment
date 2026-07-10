class_name StatBlock
extends RefCounted

var _base_values: Dictionary = {}
var _modifiers_by_id: Dictionary = {}

func set_base_value(stat_id: StringName, base_value: float) -> ActionResult:
	if stat_id.is_empty():
		return ActionResult.failure("StatBlock requires a non-empty stat ID.")
	if not is_finite(base_value):
		return ActionResult.failure("StatBlock base value for %s must be finite." % stat_id)
	_base_values[stat_id] = base_value
	return ActionResult.success(true)

func add_modifier(modifier: StatModifier) -> ActionResult:
	if not modifier:
		return ActionResult.failure("StatBlock.add_modifier requires a StatModifier.")
	var contract_error := modifier.validate_contract()
	if not contract_error.is_empty():
		return ActionResult.failure(contract_error)
	if not _base_values.has(modifier.stat_id):
		return ActionResult.failure("StatBlock cannot modify undefined stat '%s'." % modifier.stat_id)
	if _modifiers_by_id.has(modifier.modifier_id):
		return ActionResult.failure("StatBlock already contains modifier '%s'." % modifier.modifier_id)
	_modifiers_by_id[modifier.modifier_id] = modifier
	return ActionResult.success(true)

func remove_modifier(modifier_id: StringName) -> ActionResult:
	if not _modifiers_by_id.has(modifier_id):
		return ActionResult.failure("StatBlock does not contain modifier '%s'." % modifier_id)
	_modifiers_by_id.erase(modifier_id)
	return ActionResult.success(true)

func value(stat_id: StringName) -> ActionResult:
	if not _base_values.has(stat_id):
		return ActionResult.failure("StatBlock does not define stat '%s'." % stat_id)
	var flat_total: float = _base_values[stat_id]
	var multiplier := 1.0
	for modifier_value in _modifiers_by_id.values():
		var modifier := modifier_value as StatModifier
		if modifier.stat_id != stat_id:
			continue
		match modifier.operation:
			StatModifier.Operation.FLAT:
				flat_total += modifier.value
			StatModifier.Operation.MULTIPLIER:
				multiplier *= modifier.value
			_:
				return ActionResult.failure("StatBlock encountered unknown modifier operation for '%s'." % modifier.modifier_id)
	return ActionResult.success(flat_total * multiplier)
