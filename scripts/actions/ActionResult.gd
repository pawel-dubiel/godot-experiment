class_name ActionResult
extends RefCounted

var value: Variant
var error: String

func _init(p_value: Variant, p_error: String) -> void:
	value = p_value
	error = p_error

static func success(result_value: Variant) -> ActionResult:
	return ActionResult.new(result_value, "")

static func failure(message: String) -> ActionResult:
	if message.strip_edges().is_empty():
		push_error("ActionResult.failure requires a non-empty error message.")
		return null
	return ActionResult.new(null, message)

func is_success() -> bool:
	return error.is_empty()
