class_name GameEntity
extends Node2D # Converted to 2D per user request

## Base Entity class key for optimization.
## Maintains a cache of components to avoid get_children() loops.

# Dictionary[Script or String, UnitComponent]
var _components: Dictionary = {}

# Message Bus: Map[String, Array[Callable]]
var _subscribers: Dictionary = {}

# Core property for Map positioning
@export var grid_position: Vector2i = Vector2i(0, 0)
@export var tile_map: TileMapLayer
@export var is_selected := false:
	set(value):
		if is_selected == value:
			return
		is_selected = value
		_update_selection_indicator()
@export var selection_radius := 34.0
@export var selection_color := Color(1.0, 0.82, 0.18, 1.0)
@export var selection_width := 4.0
@export var selection_indicator_z_index := 100
@export var orientation: int = 0: # 0 to 5, representing 6 walls of a hex
	set(value):
		orientation = wrapi(value, 0, 6)
		_update_visual_orientation()

var _selection_indicator: Line2D

func _ready() -> void:
	z_index = 10 # Force on top
	z_as_relative = false
	add_to_group("units")
	_ensure_selection_indicator()

	if tile_map:
		_snap_to_grid()

func set_tile_map(value: TileMapLayer) -> bool:
	if not value:
		push_error("GameEntity %s requires a TileMapLayer for grid positioning." % name)
		return false

	tile_map = value
	return _snap_to_grid()

func _snap_to_grid() -> bool:
	if not tile_map:
		push_error("GameEntity %s cannot snap to grid without tile_map." % name)
		return false

	position = tile_map.map_to_local(grid_position)
	_update_visual_orientation()
	return true

func move_to_grid_position(new_position: Vector2i) -> bool:
	if not tile_map:
		push_error("GameEntity %s cannot move to grid position without tile_map." % name)
		return false

	var local_pos = tile_map.map_to_local(new_position)
	var diff = local_pos - position
	if diff.length_squared() > 0.1:
		var angle = diff.angle()
		var deg = rad_to_deg(angle)
		if deg < 0:
			deg += 360

		orientation = int(round(deg / 60.0)) % 6

	grid_position = new_position
	position = local_pos
	return true

func _update_visual_orientation() -> void:
	# Rotate the Visuals node if present
	var visuals = get_node_or_null("Visuals")
	if visuals:
		# Hex walls are typically at 30, 90, 150... or 0, 60, 120 depending on point-top vs flat-top.
		visuals.rotation_degrees = orientation * 60.0
	queue_redraw()

func set_selected(value: bool) -> void:
	is_selected = value

func _ensure_selection_indicator() -> void:
	if _selection_indicator:
		return

	_selection_indicator = Line2D.new()
	_selection_indicator.name = "SelectionIndicator"
	_selection_indicator.closed = true
	_selection_indicator.default_color = selection_color
	_selection_indicator.width = selection_width
	_selection_indicator.z_index = selection_indicator_z_index
	_selection_indicator.z_as_relative = false
	_selection_indicator.visible = is_selected
	_selection_indicator.points = _build_selection_ring_points()
	add_child(_selection_indicator)

func _update_selection_indicator() -> void:
	if not is_node_ready():
		return

	_ensure_selection_indicator()
	_selection_indicator.default_color = selection_color
	_selection_indicator.width = selection_width
	_selection_indicator.z_index = selection_indicator_z_index
	_selection_indicator.points = _build_selection_ring_points()
	_selection_indicator.visible = is_selected

func _build_selection_ring_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(72):
		var angle = TAU * float(index) / 72.0
		points.append(Vector2(cos(angle), sin(angle)) * selection_radius)
	return points

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
