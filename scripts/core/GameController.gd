class_name GameController
extends Node

@export var map_service: MapService
@export var tile_map: TileMapLayer
@export var units_root: Node
@export var selection_pick_radius := 45.0

var current_selection: GameEntity
var _units_by_grid_position: Dictionary = {}
var _tracked_unit_ids: Dictionary = {}

func _ready() -> void:
	if not _resolve_dependencies():
		return
	call_deferred("_rebuild_unit_index")
	print("GameController Ready. Click Unit to Select, Right Click to Move/Attack.")

func _resolve_dependencies() -> bool:
	if not map_service:
		push_error("GameController requires map_service.")
		return false
	if not tile_map:
		push_error("GameController requires tile_map.")
		return false
	if not units_root:
		push_error("GameController requires units_root.")
		return false
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_select(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_action(event.position)

func _handle_select(_screen_pos: Vector2) -> void:
	if not _has_input_dependencies():
		return

	var global_mouse_pos = _get_global_mouse_pos()
	var grid_pos = _get_grid_position_for_world_position(global_mouse_pos)
	var selected_entity = _get_unit_near_world_position(global_mouse_pos, grid_pos)
	_set_current_selection(selected_entity)

	if selected_entity:
		print("Selected: %s" % selected_entity.name)
	else:
		print("Deselected")

func _handle_action(_screen_pos: Vector2) -> void:
	if not current_selection:
		return
	if not _has_input_dependencies():
		return

	var global_mouse_pos = _get_global_mouse_pos()
	var grid_pos = _get_grid_position_for_world_position(global_mouse_pos)
	var target_entity = _get_unit_near_world_position(global_mouse_pos, grid_pos)

	if target_entity and target_entity != current_selection:
		var attack_comp = current_selection.get_component(AttackComponent)
		if attack_comp:
			print("Attacking %s" % target_entity.name)
			var cmd = attack_comp.create_attack_command(target_entity)
			var context = GameContext.new(map_service)
			cmd.execute(context)
			return
		push_error("Selected unit %s cannot act on occupied grid position %s without AttackComponent." % [current_selection.name, grid_pos])
		return

	if not _can_move_to_grid_position(grid_pos):
		return

	var move_comp = current_selection.get_component(MovementComponent)
	if move_comp:
		move_comp.move_to(grid_pos)
	else:
		push_error("Selected unit %s cannot move without MovementComponent." % current_selection.name)

func _get_grid_position_for_world_position(world_position: Vector2) -> Vector2i:
	var local_pos = tile_map.to_local(world_position)
	return tile_map.local_to_map(local_pos)

func _has_input_dependencies() -> bool:
	if not map_service:
		push_error("GameController cannot handle input without map_service.")
		return false
	if not tile_map:
		push_error("GameController cannot handle input without tile_map.")
		return false
	if not units_root:
		push_error("GameController cannot handle input without units_root.")
		return false
	return true

func _can_move_to_grid_position(grid_position: Vector2i) -> bool:
	if not current_selection:
		push_error("GameController cannot validate movement without a current_selection.")
		return false
	return _can_unit_move_to_grid_position(current_selection, grid_position)

func _can_unit_move_to_grid_position(unit: GameEntity, grid_position: Vector2i) -> bool:
	var occupying_unit = _get_unit_at_grid_position(grid_position)
	if occupying_unit and occupying_unit != unit:
		push_error("Cannot move %s to occupied grid position %s; occupied by %s." % [unit.name, grid_position, occupying_unit.name])
		return false
	return true

func _rebuild_unit_index() -> void:
	if not units_root:
		push_error("GameController cannot build unit index without units_root.")
		return

	_units_by_grid_position.clear()
	for node in units_root.get_children():
		if node is GameEntity:
			if _track_unit(node):
				_index_unit(node)

func _track_unit(unit: GameEntity) -> bool:
	var unit_id = unit.get_instance_id()
	if _tracked_unit_ids.has(unit_id):
		return true

	if not unit.set_tile_map(tile_map):
		return false

	var movement_component = unit.get_component(MovementComponent) as MovementComponent
	if movement_component:
		movement_component.set_move_validator(Callable(self, "_can_unit_move_to_grid_position"))

	_tracked_unit_ids[unit_id] = true
	unit.subscribe("moved", _on_unit_moved.bind(unit))
	return true

func _index_unit(unit: GameEntity) -> void:
	var existing_unit = _units_by_grid_position.get(unit.grid_position)
	if existing_unit and existing_unit != unit:
		push_error("Grid position %s is already occupied by %s; cannot index %s." % [unit.grid_position, existing_unit.name, unit.name])
		return

	_units_by_grid_position[unit.grid_position] = unit

func _on_unit_moved(data: Dictionary, unit: GameEntity) -> void:
	if not data.has("from") or not data.has("to"):
		push_error("GameController expected moved event data with 'from' and 'to'.")
		return

	var previous_position: Vector2i = data["from"]
	var new_position: Vector2i = data["to"]
	var destination_unit = _units_by_grid_position.get(new_position)
	if destination_unit and destination_unit != unit:
		push_error("Cannot index moved unit %s at occupied grid position %s; occupied by %s." % [unit.name, new_position, destination_unit.name])
		return

	var indexed_unit = _units_by_grid_position.get(previous_position)
	if indexed_unit == unit:
		_units_by_grid_position.erase(previous_position)
	elif indexed_unit:
		push_error("Grid position %s is indexed for %s, not moved unit %s." % [previous_position, indexed_unit.name, unit.name])
		return

	_index_unit(unit)

func _get_unit_at_grid_position(grid_position: Vector2i) -> GameEntity:
	return _units_by_grid_position.get(grid_position) as GameEntity

func _get_unit_near_world_position(world_position: Vector2, center_grid_position: Vector2i) -> GameEntity:
	var nearest_unit: GameEntity
	var nearest_distance := selection_pick_radius
	for grid_position in _get_candidate_grid_positions(center_grid_position):
		var unit = _get_unit_at_grid_position(grid_position)
		if not unit:
			continue

		var distance = unit.global_position.distance_to(world_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_unit = unit

	return nearest_unit

func _get_candidate_grid_positions(center_grid_position: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = [center_grid_position]
	for grid_position in tile_map.get_surrounding_cells(center_grid_position):
		positions.append(grid_position)
	return positions

func _set_current_selection(next_selection: GameEntity) -> void:
	if current_selection == next_selection:
		return

	if current_selection and is_instance_valid(current_selection):
		current_selection.set_selected(false)

	current_selection = next_selection
	if current_selection:
		current_selection.set_selected(true)

func _get_global_mouse_pos() -> Vector2:
	# Keep it simple for 2D
	return get_parent().get_global_mouse_position()
