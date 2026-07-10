class_name ContextualActionResolver
extends Node

func resolve(actions: Array, target: Variant, context: GameContext) -> Dictionary:
	var matches: Array[ActionDescriptor] = []
	for candidate in actions:
		if not candidate is ActionDescriptor:
			return _error("ContextualActionResolver requires ActionDescriptor values.")
		var descriptor := candidate as ActionDescriptor
		var availability := descriptor.availability(context)
		if not availability.is_success():
			return _error(availability.error)
		if not availability.value:
			continue
		var contextual_match := descriptor.matches_context(target, context)
		if not contextual_match.is_success():
			return _error(contextual_match.error)
		if contextual_match.value:
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
