extends Node
class_name RectangularMapGenerator

@export var width: int = 200
@export var height: int = 200
@export var map_service: MapService
@export var default_terrain: TerrainType

func _ready() -> void:
	# Wait one frame to ensure dependencies are ready if initialized in same scene
	await get_tree().process_frame
	generate()

func _resolve_dependencies() -> bool:
	if not map_service:
		push_error("RectangularMapGenerator requires map_service.")
		return false
	if not default_terrain:
		push_error("RectangularMapGenerator requires default_terrain.")
		return false
	if width <= 0 or height <= 0:
		push_error("RectangularMapGenerator requires positive width and height.")
		return false
	return true

func generate() -> void:
	if not _resolve_dependencies():
		return

	print("MapGenerator: Generating %dx%d map data..." % [width, height])
	
	var tiles = {}
	for axial in HexCoordinates.odd_row_rectangle(width, height):
		tiles[axial] = default_terrain
			
	map_service.initialize_map(tiles)
	print("MapGenerator: Done.")
