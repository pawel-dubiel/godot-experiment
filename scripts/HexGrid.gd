extends TileMapLayer
class_name HexGridView

@export var map_service: MapService

const HEX_WIDTH = 90
const HEX_HEIGHT = 104
const TILE_SOURCE_ID = 0

func _ready() -> void:
	z_index = -1
	add_to_group("grid_view")
	_setup_tileset()
	if map_service:
		map_service.map_updated.connect(_on_map_updated)
		map_service.tile_changed.connect(_on_tile_changed)

func _setup_tileset() -> void:
	var ts = TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	ts.tile_size = Vector2i(HEX_WIDTH, HEX_HEIGHT)
	
	var source = TileSetAtlasSource.new()
	var tex = load("res://assets/hex.svg")
	source.texture = tex
	source.texture_region_size = Vector2i(HEX_WIDTH, HEX_HEIGHT)
	source.create_tile(Vector2i(0, 0))
	
	ts.add_source(source, TILE_SOURCE_ID)
	self.tile_set = ts

func _on_map_updated() -> void:
	clear()
	var all_coords = map_service.model.get_all_coords()
	for coord in all_coords:
		var tile = map_service.get_tile(coord)
		if tile:
			_draw_tile(coord, tile.terrain)

func _on_tile_changed(coord: Vector2i, terrain: TerrainType) -> void:
	_draw_tile(coord, terrain)

func _draw_tile(coord: Vector2i, terrain: TerrainType) -> void:
	# Here we map the logical TerrainType to the visual Atlas Coords
	set_cell(coord, TILE_SOURCE_ID, terrain.atlas_coords)
