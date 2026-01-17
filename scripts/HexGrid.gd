extends TileMapLayer
class_name HexGrid

# Configuration constants - easier to change in one place
const HEX_WIDTH = 90
const HEX_HEIGHT = 104
const TILE_SOURCE_ID = 0

func _ready() -> void:
	_setup_tileset()

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
