extends Node2D

@export var tile_map: TileMapLayer
@export var camera: Camera2D

var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font

func _process(_delta: float) -> void:
	# Continuous redraw is required as camera moves
	queue_redraw()

func _draw() -> void:
	if not tile_map or not camera:
		return
		
	var visible_range = _get_visible_map_range()
	_draw_coordinates(visible_range)

func _get_visible_map_range() -> Rect2i:
	var viewport_rect = get_viewport_rect()
	var cam_pos = camera.global_position
	var zoom = camera.zoom
	
	# Determine visible world area with a margin buffer
	var buffer = Vector2(200, 200)
	var visible_size = viewport_rect.size / zoom
	var top_left_world = cam_pos - visible_size / 2 - buffer
	var bottom_right_world = cam_pos + visible_size / 2 + buffer
	
	var min_map = tile_map.local_to_map(tile_map.to_local(top_left_world))
	var max_map = tile_map.local_to_map(tile_map.to_local(bottom_right_world))
	
	var x_start = min(min_map.x, max_map.x)
	var x_end = max(min_map.x, max_map.x)
	var y_start = min(min_map.y, max_map.y)
	var y_end = max(min_map.y, max_map.y)
	
	# Safety cap for performance
	if (x_end - x_start) > 300: x_end = x_start + 300
	if (y_end - y_start) > 300: y_end = y_start + 300
	
	return Rect2i(x_start, y_start, x_end - x_start + 1, y_end - y_start + 1)

func _draw_coordinates(range_rect: Rect2i) -> void:
	for x in range(range_rect.position.x, range_rect.end.x):
		for y in range(range_rect.position.y, range_rect.end.y):
			var coords = Vector2i(x, y)
			
			# Only draw if a cell exists (is not empty)
			if tile_map.get_cell_source_id(coords) != -1:
				var world_pos = tile_map.to_global(tile_map.map_to_local(coords))
				# Center the text
				var text_pos = world_pos + Vector2(-20, 5)
				draw_string(font, text_pos, str(coords), HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
