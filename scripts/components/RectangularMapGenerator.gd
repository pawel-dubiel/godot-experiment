extends Node
class_name RectangularMapGenerator

@export var width: int = 20
@export var height: int = 20
@export var map_service: MapService
@export var default_terrain: TerrainType

func _ready() -> void:
	# Wait one frame to ensure dependencies are ready if initialized in same scene
	await get_tree().process_frame
	if map_service and default_terrain:
		generate()

func generate() -> void:
	print("MapGenerator: Generating %dx%d map data..." % [width, height])
	
	var tiles = {}
	for x in range(width):
		for y in range(height):
			tiles[Vector2i(x, y)] = default_terrain
			
	map_service.initialize_map(tiles)
	print("MapGenerator: Done.")