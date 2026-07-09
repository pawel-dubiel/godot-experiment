extends RefCounted
class_name MapModel

# The "Database": Dictionary<Vector2i, TileInstance>
var _tiles: Dictionary = {}
var _bounds := Rect2i()
var _has_tiles := false

func set_tile(coord: Vector2i, terrain: TerrainType) -> void:
	var tile = TileInstance.new(coord, terrain)
	_tiles[coord] = tile
	_include_coord_in_bounds(coord)

func get_tile(coord: Vector2i) -> TileInstance:
	return _tiles.get(coord)

func has_tile(coord: Vector2i) -> bool:
	return _tiles.has(coord)

func get_bounds() -> Rect2i:
	return _bounds

func get_all_coords() -> Array:
	return _tiles.keys()

func clear() -> void:
	_tiles.clear()
	_bounds = Rect2i()
	_has_tiles = false

func _include_coord_in_bounds(coord: Vector2i) -> void:
	if not _has_tiles:
		_bounds = Rect2i(coord, Vector2i.ONE)
		_has_tiles = true
		return

	var min_x = min(_bounds.position.x, coord.x)
	var min_y = min(_bounds.position.y, coord.y)
	var max_x = max(_bounds.end.x - 1, coord.x)
	var max_y = max(_bounds.end.y - 1, coord.y)
	_bounds = Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))
