class_name ActionDescriptor
extends RefCounted

enum TargetingMode {
	NONE,
	HEX,
	UNIT,
	DIRECTION,
	AREA,
}

var action_id: StringName
var display_name: String
var icon: Texture2D
var targeting_mode: TargetingMode
var behavior: ActionBehavior

func _init(
	p_action_id: StringName,
	p_display_name: String,
	p_icon: Texture2D,
	p_targeting_mode: TargetingMode,
	p_behavior: ActionBehavior
) -> void:
	action_id = p_action_id
	display_name = p_display_name
	icon = p_icon
	targeting_mode = p_targeting_mode
	behavior = p_behavior

func validate_contract() -> String:
	if action_id.is_empty():
		return "ActionDescriptor requires a non-empty action_id."
	if display_name.strip_edges().is_empty():
		return "ActionDescriptor %s requires a display_name." % action_id
	if not icon:
		return "ActionDescriptor %s requires an icon." % action_id
	if not behavior:
		return "ActionDescriptor %s requires an ActionBehavior." % action_id
	return ""

func availability(context: GameContext) -> ActionResult:
	return _require_bool(behavior.availability(context), "availability")

func get_unavailable_reason(context: GameContext) -> ActionResult:
	return _require_string(behavior.get_unavailable_reason(context), "unavailable reason")

func get_candidate_coordinates(context: GameContext) -> ActionResult:
	var result := _require_result(behavior.get_candidate_coordinates(context), "candidate coordinates")
	if not result.is_success():
		return result
	if not result.value is Array:
		return _contract_failure("candidate coordinates must be Array[Vector2i].")
	var coordinates: Array[Vector2i] = []
	for candidate in result.value:
		if typeof(candidate) != TYPE_VECTOR2I:
			return _contract_failure("candidate coordinates contain a non-Vector2i value.")
		coordinates.append(candidate)
	return ActionResult.success(coordinates)

func matches_context(target: Variant, context: GameContext) -> ActionResult:
	return _require_bool(behavior.matches_context(target, context), "contextual match")

func validate_target(target: Variant, context: GameContext) -> ActionResult:
	return _require_bool(behavior.validate_target(target, context), "target validation")

func create_command(target: Variant, context: GameContext) -> ActionResult:
	var result := _require_result(behavior.create_command(target, context), "command creation")
	if not result.is_success():
		return result
	if not result.value is Command:
		return _contract_failure("command creation must return Command.")
	return result

func _require_bool(result: ActionResult, operation: String) -> ActionResult:
	result = _require_result(result, operation)
	if not result.is_success():
		return result
	if typeof(result.value) != TYPE_BOOL:
		return _contract_failure("%s must return bool." % operation)
	return result

func _require_string(result: ActionResult, operation: String) -> ActionResult:
	result = _require_result(result, operation)
	if not result.is_success():
		return result
	if typeof(result.value) != TYPE_STRING:
		return _contract_failure("%s must return String." % operation)
	return result

func _require_result(result: ActionResult, operation: String) -> ActionResult:
	if not result:
		return _contract_failure("%s must return ActionResult." % operation)
	return result

func _contract_failure(detail: String) -> ActionResult:
	var message := "ActionDescriptor %s %s" % [action_id, detail]
	push_error(message)
	return ActionResult.failure(message)
