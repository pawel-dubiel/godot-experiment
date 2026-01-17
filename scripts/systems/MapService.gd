extends Node
class_name MapService

signal map_updated
signal tile_changed(coord: Vector2i, terrain: TerrainType)

var model: MapModel

func _init() -> void:
	model = MapModel.new()

func set_tile(coord: Vector2i, terrain: TerrainType) -> void:
	model.set_tile(coord, terrain)
	tile_changed.emit(coord, terrain)

func get_tile(coord: Vector2i) -> TileInstance:
	return model.get_tile(coord)

# Bulk operation for performance
func initialize_map(new_tiles: Dictionary) -> void:
	for coord in new_tiles:
		model.set_tile(coord, new_tiles[coord])
	map_updated.emit()

## Calculates distance between two hex coordinates (Cube/Axial distance).
func get_distance(a: Vector2i, b: Vector2i) -> int:
	# Using Axial coordinates (q, r) conversion to Cube (x, y, z)
	# q = x, r = y
	# s = -q - r
	var aq = a.x
	var ar = a.y
	var as_ = -aq - ar
	
	var bq = b.x
	var br = b.y
	var bs = -bq - br
	
	return int((abs(aq - bq) + abs(ar - br) + abs(as_ - bs)) / 2)
