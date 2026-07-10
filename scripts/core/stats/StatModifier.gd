class_name StatModifier
extends Resource

enum Operation {
	FLAT,
	MULTIPLIER,
}

@export var modifier_id: StringName
@export var stat_id: StringName
@export var operation: Operation = Operation.FLAT
@export var value: float

func validate_contract() -> String:
	if modifier_id.is_empty():
		return "StatModifier requires a non-empty modifier_id."
	if stat_id.is_empty():
		return "StatModifier %s requires a non-empty stat_id." % modifier_id
	if not is_finite(value):
		return "StatModifier %s requires a finite value." % modifier_id
	if operation == Operation.MULTIPLIER and value <= 0.0:
		return "StatModifier %s multiplier must be greater than zero." % modifier_id
	return ""
