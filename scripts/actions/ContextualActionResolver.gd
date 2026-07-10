class_name ContextualActionResolver
extends Node

func resolve(actions: Array, target: Variant, context: GameContext) -> Dictionary:
	var matches: Array[ActionDescriptor] = []
	for candidate in actions:
		if not candidate is ActionDescriptor:
			return _error("ContextualActionResolver requires ActionDescriptor values.")
		var descriptor := candidate as ActionDescriptor
		var available := descriptor.is_available(context)
		if not descriptor.last_contract_error.is_empty():
			return _error(descriptor.last_contract_error)
		if not available:
			continue
		var is_match := descriptor.matches_context(target, context)
		if not descriptor.last_contract_error.is_empty():
			return _error(descriptor.last_contract_error)
		if is_match:
			matches.append(descriptor)

	if matches.is_empty():
		return {"status": &"unavailable", "reason": "No contextual action is available for this target."}
	if matches.size() == 1:
		return {"status": &"resolved", "action": matches[0], "reason": ""}

	var conflicting_ids: Array[String] = []
	for descriptor in matches:
		conflicting_ids.append(String(descriptor.action_id))
	return _error("Conflicting contextual action defaults: %s." % ", ".join(conflicting_ids))

func _error(reason: String) -> Dictionary:
	push_error(reason)
	return {"status": &"error", "reason": reason}
