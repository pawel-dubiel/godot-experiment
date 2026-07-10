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
var last_contract_error := ""

var _availability_check: Callable
var _unavailable_reason_provider: Callable
var _contextual_matcher: Callable
var _target_validator: Callable
var _command_factory: Callable

func _init(
	p_action_id: StringName,
	p_display_name: String,
	p_icon: Texture2D,
	p_targeting_mode: TargetingMode,
	p_availability_check: Callable,
	p_unavailable_reason_provider: Callable,
	p_contextual_matcher: Callable,
	p_target_validator: Callable,
	p_command_factory: Callable
) -> void:
	action_id = p_action_id
	display_name = p_display_name
	icon = p_icon
	targeting_mode = p_targeting_mode
	_availability_check = p_availability_check
	_unavailable_reason_provider = p_unavailable_reason_provider
	_contextual_matcher = p_contextual_matcher
	_target_validator = p_target_validator
	_command_factory = p_command_factory

func validate_contract() -> String:
	if action_id.is_empty():
		return "ActionDescriptor requires a non-empty action_id."
	if display_name.strip_edges().is_empty():
		return "ActionDescriptor %s requires a display_name." % action_id
	if not icon:
		return "ActionDescriptor %s requires an icon." % action_id
	if not _availability_check.is_valid():
		return "ActionDescriptor %s requires an availability check." % action_id
	if not _unavailable_reason_provider.is_valid():
		return "ActionDescriptor %s requires an unavailable-reason provider." % action_id
	if not _contextual_matcher.is_valid():
		return "ActionDescriptor %s requires a contextual matcher." % action_id
	if not _target_validator.is_valid():
		return "ActionDescriptor %s requires a target validator." % action_id
	if not _command_factory.is_valid():
		return "ActionDescriptor %s requires a command factory." % action_id
	return ""

func is_available(context: GameContext) -> bool:
	last_contract_error = ""
	var result = _availability_check.call(context)
	if typeof(result) != TYPE_BOOL:
		_set_contract_error("ActionDescriptor %s availability check must return bool." % action_id)
		return false
	return result

func get_unavailable_reason(context: GameContext) -> String:
	last_contract_error = ""
	var result = _unavailable_reason_provider.call(context)
	if typeof(result) != TYPE_STRING:
		_set_contract_error("ActionDescriptor %s unavailable-reason provider must return String." % action_id)
		return ""
	return result

func matches_context(target: Variant, context: GameContext) -> bool:
	last_contract_error = ""
	var result = _contextual_matcher.call(target, context)
	if typeof(result) != TYPE_BOOL:
		_set_contract_error("ActionDescriptor %s contextual matcher must return bool." % action_id)
		return false
	return result

func is_valid_target(target: Variant, context: GameContext) -> bool:
	last_contract_error = ""
	var result = _target_validator.call(target, context)
	if typeof(result) != TYPE_BOOL:
		_set_contract_error("ActionDescriptor %s target validator must return bool." % action_id)
		return false
	return result

func create_command(target: Variant, context: GameContext) -> Command:
	last_contract_error = ""
	var result = _command_factory.call(target, context)
	if not result is Command:
		_set_contract_error("ActionDescriptor %s command factory must return Command." % action_id)
		return null
	return result as Command

func _set_contract_error(message: String) -> void:
	last_contract_error = message
	push_error(message)
