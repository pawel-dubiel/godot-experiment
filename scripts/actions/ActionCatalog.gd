class_name ActionCatalog
extends Node

func collect(entity: GameEntity, context: GameContext) -> Dictionary:
	if not entity:
		return _error("ActionCatalog requires a selected GameEntity.")
	if not entity.has_method("get_registered_components"):
		return _error("ActionCatalog requires GameEntity.get_registered_components().")

	var actions: Array[ActionDescriptor] = []
	var ids: Dictionary = {}
	for component in entity.get_registered_components():
		if not component.has_method("get_action_descriptors"):
			continue
		var provided_actions = component.get_action_descriptors(context)
		if not provided_actions is Array:
			return _error("Action provider %s must return an Array." % component.name)
		for candidate in provided_actions:
			if not candidate is ActionDescriptor:
				return _error("Action provider %s returned a value that is not an ActionDescriptor." % component.name)
			var descriptor := candidate as ActionDescriptor
			var contract_error := descriptor.validate_contract()
			if not contract_error.is_empty():
				return _error("Action provider %s: %s" % [component.name, contract_error])
			var availability := descriptor.availability(context)
			if not availability.is_success():
				return _error(availability.error)
			if not availability.value:
				var unavailable_reason := descriptor.get_unavailable_reason(context)
				if not unavailable_reason.is_success():
					return _error(unavailable_reason.error)
				if unavailable_reason.value.strip_edges().is_empty():
					return _error("Unavailable action '%s' from provider %s requires a player-facing reason." % [descriptor.action_id, component.name])
			if ids.has(descriptor.action_id):
				return _error("Duplicate action ID '%s' from providers %s and %s." % [descriptor.action_id, ids[descriptor.action_id], component.name])
			ids[descriptor.action_id] = component.name
			actions.append(descriptor)

	actions.sort_custom(func(left: ActionDescriptor, right: ActionDescriptor): return left.action_id < right.action_id)
	return {"status": &"ok", "actions": actions, "reason": ""}

func _error(reason: String) -> Dictionary:
	push_error(reason)
	return {"status": &"error", "actions": [], "reason": reason}
