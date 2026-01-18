class_name EntityComponent
extends Node

## Base class for components attached to a GameEntity.

## Returns the GameEntity (parent node) this component is attached to.
func get_entity() -> Node:
	return get_parent()

func _enter_tree() -> void:
	var parent = get_parent()
	if parent is GameEntity:
		parent.register_component(self)
