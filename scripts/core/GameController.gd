class_name GameController
extends Node

@export var map_service: MapService
@export var tile_map: TileMapLayer
@export var units_root: Node
@export var input_router: MapInputRouter
@export var camera_control: CameraControl
@export var action_catalog: ActionCatalog
@export var contextual_action_resolver: ContextualActionResolver
@export var command_executor: CommandExecutor
@export var action_bar: ActionBar
@export var targeting_overlay: TargetingOverlay
@export var selection_pick_radius := 45.0

var current_selection: GameEntity
var armed_action: ActionDescriptor

var _available_actions: Array[ActionDescriptor] = []
var _units_by_grid_position: Dictionary = {}
var _tracked_unit_ids: Dictionary = {}
var _context: GameContext

func _ready() -> void:
	if not _resolve_dependencies():
		return
	_context = GameContext.new(map_service)
	_connect_interaction_boundaries()
	call_deferred("_rebuild_unit_index")

func _resolve_dependencies() -> bool:
	var missing: Array[String] = []
	if not map_service:
		missing.append("map_service")
	if not tile_map:
		missing.append("tile_map")
	if not units_root:
		missing.append("units_root")
	if not input_router:
		missing.append("input_router")
	if not camera_control:
		missing.append("camera_control")
	if not action_catalog:
		missing.append("action_catalog")
	if not contextual_action_resolver:
		missing.append("contextual_action_resolver")
	if not command_executor:
		missing.append("command_executor")
	if not action_bar:
		missing.append("action_bar")
	if not targeting_overlay:
		missing.append("targeting_overlay")
	if not missing.is_empty():
		push_error("GameController requires explicit dependencies: %s." % ", ".join(missing))
		return false
	return true

func _connect_interaction_boundaries() -> void:
	input_router.selection_requested.connect(_handle_select)
	input_router.context_action_requested.connect(_handle_context_action)
	input_router.targeting_cancel_requested.connect(_cancel_targeting)
	input_router.camera_pan_requested.connect(camera_control.pan_screen_delta)
	input_router.camera_direction_requested.connect(camera_control.pan_direction)
	input_router.camera_zoom_requested.connect(camera_control.zoom_at)
	action_bar.action_selected.connect(_handle_action_selected)

func _handle_select(screen_position: Vector2) -> void:
	_cancel_targeting()
	var world_position := _screen_to_world(screen_position)
	var grid_position := _get_grid_position_for_world_position(world_position)
	var selected_entity := _get_unit_near_world_position(world_position, grid_position)
	_set_current_selection(selected_entity)

func _handle_context_action(screen_position: Vector2) -> void:
	if not current_selection:
		return
	var target := _get_action_target(screen_position)
	if armed_action:
		var valid_target := armed_action.is_valid_target(target, _context)
		if not armed_action.last_contract_error.is_empty():
			action_bar.show_feedback(armed_action.last_contract_error, true)
			return
		if not valid_target:
			_cancel_targeting()
			action_bar.show_feedback("Action cancelled · target unavailable")
			return
		_execute_action(armed_action, target)
		return

	var resolution := contextual_action_resolver.resolve(_available_actions, target, _context)
	match resolution.status:
		&"resolved":
			_execute_action(resolution.action, target)
		&"unavailable":
			action_bar.show_feedback(resolution.reason)
		&"error":
			action_bar.show_feedback(resolution.reason, true)
		_:
			push_error("ContextualActionResolver returned unknown status '%s'." % resolution.status)

func _handle_action_selected(action_id: StringName) -> void:
	if not current_selection:
		push_error("GameController cannot arm action %s without a current selection." % action_id)
		return
	var descriptor := _find_available_action(action_id)
	if not descriptor:
		push_error("Selected unit %s does not provide action '%s'." % [current_selection.name, action_id])
		return
	var available := descriptor.is_available(_context)
	if not descriptor.last_contract_error.is_empty():
		action_bar.show_feedback(descriptor.last_contract_error, true)
		return
	if not available:
		action_bar.show_feedback(descriptor.get_unavailable_reason(_context), true)
		return
	if descriptor.targeting_mode == ActionDescriptor.TargetingMode.NONE:
		_execute_action(descriptor, null)
		return

	armed_action = descriptor
	if not targeting_overlay.present(descriptor, _context, map_service, tile_map, Callable(self, "_get_unit_at_grid_position")):
		armed_action = null
		action_bar.show_feedback("%s targeting contract failed." % descriptor.display_name, true)
		return
	_refresh_action_bar()

func _execute_action(descriptor: ActionDescriptor, target: Variant) -> void:
	var command := descriptor.create_command(target, _context)
	if not descriptor.last_contract_error.is_empty():
		action_bar.show_feedback(descriptor.last_contract_error, true)
		return
	if not command:
		action_bar.show_feedback("%s could not create its command." % descriptor.display_name, true)
		return
	if not command_executor.execute(command, _context):
		action_bar.show_feedback("%s is no longer valid." % descriptor.display_name)
		return

	_cancel_targeting()
	_refresh_actions()
	action_bar.show_feedback("%s executed" % descriptor.display_name)

func _cancel_targeting() -> void:
	if not armed_action:
		return
	armed_action = null
	targeting_overlay.clear()
	_refresh_action_bar()

func _set_current_selection(next_selection: GameEntity) -> void:
	if current_selection == next_selection:
		_refresh_actions()
		return
	if current_selection and is_instance_valid(current_selection):
		current_selection.set_selected(false)
	current_selection = next_selection
	if current_selection:
		current_selection.set_selected(true)
	_refresh_actions()

func _refresh_actions() -> void:
	_available_actions.clear()
	if not current_selection:
		action_bar.clear()
		return
	var catalog_result := action_catalog.collect(current_selection, _context)
	if catalog_result.status == &"error":
		action_bar.clear()
		return
	if catalog_result.status != &"ok":
		push_error("ActionCatalog returned unknown status '%s'." % catalog_result.status)
		action_bar.clear()
		return
	_available_actions.assign(catalog_result.actions)
	_refresh_action_bar()

func _refresh_action_bar() -> void:
	if not current_selection:
		action_bar.clear()
		return
	var armed_id := armed_action.action_id if armed_action else StringName()
	action_bar.present(current_selection.name, _available_actions, armed_id, _context)

func _find_available_action(action_id: StringName) -> ActionDescriptor:
	for descriptor in _available_actions:
		if descriptor.action_id == action_id:
			return descriptor
	return null

func _get_action_target(screen_position: Vector2) -> MapActionTarget:
	var world_position := _screen_to_world(screen_position)
	var grid_position := _get_grid_position_for_world_position(world_position)
	return MapActionTarget.new(grid_position, _get_unit_at_grid_position(grid_position))

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return tile_map.get_canvas_transform().affine_inverse() * screen_position

func _get_grid_position_for_world_position(world_position: Vector2) -> Vector2i:
	return tile_map.local_to_map(tile_map.to_local(world_position))

func _rebuild_unit_index() -> void:
	if not units_root:
		push_error("GameController cannot build unit index without units_root.")
		return
	_units_by_grid_position.clear()
	for node in units_root.get_children():
		if node is GameEntity and _track_unit(node):
			_index_unit(node)

func _track_unit(unit: GameEntity) -> bool:
	var unit_id := unit.get_instance_id()
	if _tracked_unit_ids.has(unit_id):
		return true
	if not unit.set_tile_map(tile_map):
		return false
	var movement_component := unit.get_component(MovementComponent) as MovementComponent
	if movement_component:
		movement_component.set_move_validator(Callable(self, "_can_unit_move_to_grid_position"))
	_tracked_unit_ids[unit_id] = true
	unit.subscribe("moved", _on_unit_moved.bind(unit))
	unit.tree_exiting.connect(_on_unit_tree_exiting.bind(unit), CONNECT_ONE_SHOT)
	return true

func _on_unit_tree_exiting(unit: GameEntity) -> void:
	_tracked_unit_ids.erase(unit.get_instance_id())
	if _units_by_grid_position.get(unit.grid_position) == unit:
		_units_by_grid_position.erase(unit.grid_position)
	if current_selection != unit:
		return
	armed_action = null
	current_selection = null
	_available_actions.clear()
	targeting_overlay.clear()
	action_bar.clear()

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

func _can_unit_move_to_grid_position(unit: GameEntity, grid_position: Vector2i) -> bool:
	if not map_service.model.has_tile(grid_position):
		return false
	var occupying_unit := _get_unit_at_grid_position(grid_position)
	return not occupying_unit or occupying_unit == unit

func _get_unit_at_grid_position(grid_position: Vector2i) -> GameEntity:
	return _units_by_grid_position.get(grid_position) as GameEntity

func _get_unit_near_world_position(world_position: Vector2, center_grid_position: Vector2i) -> GameEntity:
	var nearest_unit: GameEntity
	var nearest_distance := selection_pick_radius
	for grid_position in _get_candidate_grid_positions(center_grid_position):
		var unit := _get_unit_at_grid_position(grid_position)
		if not unit:
			continue
		var distance := unit.global_position.distance_to(world_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_unit = unit
	return nearest_unit

func _get_candidate_grid_positions(center_grid_position: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = [center_grid_position]
	for grid_position in HexCoordinates.neighbors(center_grid_position):
		positions.append(grid_position)
	return positions
