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
