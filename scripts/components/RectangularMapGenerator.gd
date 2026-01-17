extends Node
class_name RectangularMapGenerator

@export var width: int = 20
@export var height: int = 20
@export var tile_map_layer: TileMapLayer
@export var tile_source_id: int = 0
@export var tile_atlas_coords: Vector2i = Vector2i(0, 0)

func _ready() -> void:
	if tile_map_layer:
		generate()

func generate() -> void:
	if not tile_map_layer:
		push_warning("MapGenerator: No target TileMapLayer assigned.")
		return
		
	print("MapGenerator: Generating %dx%d map..." % [width, height])
	for x in range(width):
		for y in range(height):
			tile_map_layer.set_cell(Vector2i(x, y), tile_source_id, tile_atlas_coords)
	print("MapGenerator: Done.")
