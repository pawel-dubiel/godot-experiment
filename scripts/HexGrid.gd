extends TileMapLayer
class_name HexGrid

# Configuration constants
# These define the shape of a Regular Hexagon in "World Space".
# They are independent of screen resolution.
# Ratio: Width / Height should be approx sqrt(3)/2 (0.866) for a regular hex.
# 90 / 104 = 0.8653 (0.07% error), providing a clean integer loop for tiling.
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
