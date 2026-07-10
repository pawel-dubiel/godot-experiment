class_name TargetingOverlay
extends Node2D

const VALID_FILL := Color(0.35, 0.64, 0.38, 0.28)
const VALID_EDGE := Color(0.62, 0.84, 0.55, 0.9)
const BLOCKED_EDGE := Color(0.9, 0.34, 0.25, 0.9)

@export_range(8.0, 80.0, 1.0) var hex_radius := 42.0

var _descriptor: ActionDescriptor
var _context: GameContext
var _map_service: MapService
var _tile_map: TileMapLayer
var _target_provider: Callable
var _valid_cells: Dictionary = {}
var _last_hovered_cell := Vector2i(2147483647, 2147483647)

func _ready() -> void:
	z_index = 20
	z_as_relative = false
	visible = false

func present(descriptor: ActionDescriptor, context: GameContext, map_service: MapService, tile_map: TileMapLayer, target_provider: Callable) -> bool:
	if not descriptor:
		push_error("TargetingOverlay.present requires an ActionDescriptor.")
		return false
	if not context or not map_service or not tile_map or not target_provider.is_valid():
		push_error("TargetingOverlay.present requires context, map_service, tile_map, and target_provider.")
		return false
	_descriptor = descriptor
	_context = context
	_map_service = map_service
	_tile_map = tile_map
	_target_provider = target_provider
	_last_hovered_cell = Vector2i(2147483647, 2147483647)
	if not _rebuild_valid_cell_cache():
		clear()
		return false
	visible = true
	queue_redraw()
	return true

func clear() -> void:
	_descriptor = null
	_context = null
	_map_service = null
	_tile_map = null
	_target_provider = Callable()
	_valid_cells.clear()
	_last_hovered_cell = Vector2i(2147483647, 2147483647)
	visible = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	queue_redraw()

func _process(_delta: float) -> void:
	if not visible:
		return
	var hovered_cell := _tile_map.local_to_map(_tile_map.to_local(get_global_mouse_position()))
	if hovered_cell != _last_hovered_cell:
		_last_hovered_cell = hovered_cell
		_update_cursor_shape()
		queue_redraw()

func _update_cursor_shape() -> void:
	if not _map_service.model.has_tile(_last_hovered_cell):
		Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN)
		return
	var cursor := Input.CURSOR_POINTING_HAND if _valid_cells.has(_last_hovered_cell) else Input.CURSOR_FORBIDDEN
	Input.set_default_cursor_shape(cursor)

func _rebuild_valid_cell_cache() -> bool:
	_valid_cells.clear()
	for coord_value in _map_service.model.get_all_coords():
		var coord: Vector2i = coord_value
		var target := MapActionTarget.new(coord, _target_provider.call(coord))
		var valid := _descriptor.is_valid_target(target, _context)
		if not _descriptor.last_contract_error.is_empty():
			return false
		if valid:
			_valid_cells[coord] = true
	return true

func _draw() -> void:
	if not visible or not _descriptor:
		return
	for coord_value in _valid_cells.keys():
		var coord: Vector2i = coord_value
		var center := _tile_map.map_to_local(coord)
		var points := _hex_points(center)
		draw_colored_polygon(points, VALID_FILL)
		draw_polyline(PackedVector2Array(Array(points) + [points[0]]), VALID_EDGE, 2.0, true)

	if _map_service.model.has_tile(_last_hovered_cell):
		var edge := VALID_EDGE if _valid_cells.has(_last_hovered_cell) else BLOCKED_EDGE
		var hovered_points := _hex_points(_tile_map.map_to_local(_last_hovered_cell))
		draw_polyline(PackedVector2Array(Array(hovered_points) + [hovered_points[0]]), edge, 4.0, true)

func _hex_points(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(6):
		var angle := deg_to_rad(60.0 * index)
		points.append(center + Vector2(cos(angle), sin(angle)) * hex_radius)
	return points
