extends RefCounted
class_name MapModel

# The "Database": Dictionary<Vector2i, TileInstance>
var _tiles: Dictionary = {}

func set_tile(coord: Vector2i, terrain: TerrainType) -> void:
	var tile = TileInstance.new(coord, terrain)
	_tiles[coord] = tile

func get_tile(coord: Vector2i) -> TileInstance:
	return _tiles.get(coord)

func has_tile(coord: Vector2i) -> bool:
	return _tiles.has(coord)

func get_all_coords() -> Array:
	return _tiles.keys()
