class_name UnitComponent
extends Node

## Base class for components attached to a Unit.

## Returns the Unit (parent node) this component is attached to.
func get_unit() -> Node:
	return get_parent()
