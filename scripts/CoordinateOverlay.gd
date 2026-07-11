extends Node2D

@export var debug_enabled := false:
	set(value):
		if debug_enabled == value:
			return
		debug_enabled = value
		if is_node_ready():
			_sync_debug_state()

@export var tile_map: HexGridView
@export var camera: Camera2D
@export var map_service: MapService
@export var viewport_margin := Vector2(200, 200)
@export var max_cached_labels := 2500
@export var max_visible_candidate_cells := 10000

var font: Font
var _coordinate_draw_entries: Array[Dictionary] = []
var _label_limit_warning_shown := false
var _candidate_limit_warning_shown := false

func _ready() -> void:
	font = ThemeDB.fallback_font
	_connect_invalidation_sources()
	_sync_debug_state()

func _connect_invalidation_sources() -> void:
	if camera and camera.has_signal("view_changed"):
		camera.connect("view_changed", _mark_overlay_dirty)

	if map_service:
		map_service.map_updated.connect(_mark_overlay_dirty)
		map_service.tile_changed.connect(_on_tile_changed)

	get_viewport().size_changed.connect(_mark_overlay_dirty)

func _sync_debug_state() -> void:
	visible = debug_enabled
	_coordinate_draw_entries.clear()
	_label_limit_warning_shown = false
	_candidate_limit_warning_shown = false

	if debug_enabled:
		_mark_overlay_dirty()
	else:
		queue_redraw()

func _require_debug_dependencies() -> bool:
	var missing: Array[String] = []
	if not tile_map:
		missing.append("tile_map")
	if not camera:
		missing.append("camera")
	if not map_service:
		missing.append("map_service")
	elif not map_service.model:
		missing.append("map_service.model")

	if missing.size() > 0:
		var missing_text = ", ".join(PackedStringArray(missing))
		push_error("CoordinateOverlay debug mode requires: %s." % missing_text)
		return false

	if not camera.has_signal("view_changed"):
		push_error("CoordinateOverlay debug mode requires a camera that emits view_changed.")
		return false

	return true

func _mark_overlay_dirty() -> void:
	if not debug_enabled:
		return

	if not _require_debug_dependencies():
		_coordinate_draw_entries.clear()
		queue_redraw()
		return

	_rebuild_coordinate_cache()
	queue_redraw()

func _on_tile_changed(_coord: Vector2i, _terrain: TerrainType) -> void:
	_mark_overlay_dirty()

func _draw() -> void:
	if not debug_enabled:
		return

	for entry in _coordinate_draw_entries:
		draw_string(font, entry["position"], entry["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)

func _get_visible_map_range() -> Rect2i:
	var viewport_rect = get_viewport_rect()
	var cam_pos = camera.global_position
	var zoom = camera.zoom
	
	# Determine visible world area with a margin buffer
	var visible_size = viewport_rect.size / zoom
	var top_left_world = cam_pos - visible_size / 2 - viewport_margin
	var bottom_right_world = cam_pos + visible_size / 2 + viewport_margin
	var world_corners := [
		top_left_world,
		Vector2(bottom_right_world.x, top_left_world.y),
		bottom_right_world,
		Vector2(top_left_world.x, bottom_right_world.y),
	]
	var first_axial := tile_map.local_to_axial(tile_map.to_local(world_corners[0]))
	var x_start := first_axial.x
	var x_end := first_axial.x
	var y_start := first_axial.y
	var y_end := first_axial.y
	for world_corner in world_corners:
		var axial_corner := tile_map.local_to_axial(tile_map.to_local(world_corner))
		x_start = mini(x_start, axial_corner.x)
		x_end = maxi(x_end, axial_corner.x)
		y_start = mini(y_start, axial_corner.y)
		y_end = maxi(y_end, axial_corner.y)

	return Rect2i(x_start, y_start, x_end - x_start + 1, y_end - y_start + 1)

func _get_limited_visible_map_range() -> Rect2i:
	var visible_range = _get_visible_map_range()
	var map_bounds = map_service.model.get_bounds()
	if map_bounds.size.x <= 0 or map_bounds.size.y <= 0:
		return Rect2i()

	var bounded_range = visible_range.intersection(map_bounds)
	if bounded_range.size.x <= 0 or bounded_range.size.y <= 0:
		return Rect2i()

	return _limit_candidate_cells(bounded_range)

func _limit_candidate_cells(range_rect: Rect2i) -> Rect2i:
	if max_visible_candidate_cells <= 0:
		push_error("CoordinateOverlay requires max_visible_candidate_cells to be greater than zero.")
		return Rect2i()

	var candidate_count = range_rect.size.x * range_rect.size.y
	if candidate_count <= max_visible_candidate_cells:
		return range_rect
	if not _range_exceeds_existing_cell_limit(range_rect):
		return range_rect

	if not _candidate_limit_warning_shown:
		push_warning("CoordinateOverlay reached max_visible_candidate_cells (%d); visible range is cropped around the camera." % max_visible_candidate_cells)
		_candidate_limit_warning_shown = true

	var target_width: int = min(range_rect.size.x, max(1, int(floor(sqrt(float(max_visible_candidate_cells))))))
	var target_height: int = min(range_rect.size.y, max(1, int(floor(float(max_visible_candidate_cells) / float(target_width)))))
	var half_width := int(float(target_width) / 2.0)
	var half_height := int(float(target_height) / 2.0)
	var camera_cell = tile_map.local_to_axial(tile_map.to_local(camera.global_position))
	var start_x = clampi(camera_cell.x - half_width, range_rect.position.x, range_rect.end.x - target_width)
	var start_y = clampi(camera_cell.y - half_height, range_rect.position.y, range_rect.end.y - target_height)
	return Rect2i(Vector2i(start_x, start_y), Vector2i(target_width, target_height))

func _range_exceeds_existing_cell_limit(range_rect: Rect2i) -> bool:
	var existing_cell_count := 0
	for coordinate_value in map_service.model.get_all_coords():
		var coordinate: Vector2i = coordinate_value
		if not range_rect.has_point(coordinate):
			continue
		existing_cell_count += 1
		if existing_cell_count > max_visible_candidate_cells:
			return true
	return false

func _rebuild_coordinate_cache() -> void:
	_coordinate_draw_entries.clear()

	var range_rect = _get_limited_visible_map_range()
	for x in range(range_rect.position.x, range_rect.end.x):
		for y in range(range_rect.position.y, range_rect.end.y):
			var coords = Vector2i(x, y)

			if map_service.model.has_tile(coords):
				if _coordinate_draw_entries.size() >= max_cached_labels:
					if not _label_limit_warning_shown:
						push_warning("CoordinateOverlay reached max_cached_labels (%d); remaining visible labels are skipped." % max_cached_labels)
						_label_limit_warning_shown = true
					return

				var world_pos = tile_map.to_global(tile_map.axial_to_local(coords))
				# Center the text
				var text_pos = world_pos + Vector2(-20, 5)
				_coordinate_draw_entries.append({
					"position": text_pos,
					"text": str(coords),
				})
