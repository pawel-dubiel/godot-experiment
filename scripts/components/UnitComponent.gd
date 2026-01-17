class_name UnitComponent
extends Node

## Base class for components attached to a Unit.

## Returns the Unit (parent node) this component is attached to.
func get_unit() -> Node:
	return get_parent()

func _enter_tree() -> void:
	var parent = get_parent()
	if parent.has_method("register_component"):
		parent.register_component(self)
