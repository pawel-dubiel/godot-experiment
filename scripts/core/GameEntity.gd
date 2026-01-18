class_name GameEntity
extends Node3D # Or Node2D, depending on game type. Using Node3D as generic base.

## Base Entity class key for optimization.
## Maintains a cache of components to avoid get_children() loops.

# Dictionary[Script or String, UnitComponent]
var _components: Dictionary = {}

# Message Bus: Map[String, Array[Callable]]
var _subscribers: Dictionary = {}

# Core property for Map positioning
var grid_position: Vector2i = Vector2i(0, 0)

func _ready() -> void:
	# Add to a group for global access if needed
	add_to_group("units")

## Subscribe to a message topic.
## Handler must be a specific method (Callable) that accepts a data Dictionary.
func subscribe(topic: String, handler: Callable) -> void:
	if not _subscribers.has(topic):
		_subscribers[topic] = []
	
	# Avoid duplicates
	if not _subscribers[topic].has(handler):
		_subscribers[topic].append(handler)

## Unsubscribe from a message topic.
func unsubscribe(topic: String, handler: Callable) -> void:
	if _subscribers.has(topic):
		_subscribers[topic].erase(handler)

## Send a message to all components listening to this topic.
func send_message(topic: String, data: Dictionary = {}) -> void:
	if _subscribers.has(topic):
		for handler in _subscribers[topic]:
			# Call the handler with the data dictionary
			handler.call(data)

func register_component(component: Node) -> void:
	# We can use the script resource as the key for strict type checking
	# or the class_name string if we parse it. 
	# For now, let's use the Script resource itself as the key.
	var script = component.get_script()
	if script:
		_components[script] = component
		# Also optionally register by class_name string if needed, 
		# but explicit script reference is safer for unique components.

## Fast lookup O(1)
func get_component(component_type: Script) -> Node:
	return _components.get(component_type)
	
## Helper for string-based lookup (slower, but sometimes needed)
func get_component_by_name(type_name: String) -> Node:
	for comp in _components.values():
		if comp.is_class(type_name) or (comp.get_script() and comp.get_script().resource_path.contains(type_name)):
			return comp
	return null
