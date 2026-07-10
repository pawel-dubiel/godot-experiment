extends TileMapLayer
class_name HexGridView

@export var map_service: MapService

const HEX_WIDTH = 90
const HEX_HEIGHT = 104
const TILE_SOURCE_ID = 0

func _ready() -> void:
	z_index = -1
	add_to_group("grid_view")
	if not _setup_tileset():
		return
	if not _resolve_dependencies():
		return

	map_service.map_updated.connect(_on_map_updated)
	map_service.tile_changed.connect(_on_tile_changed)

func _resolve_dependencies() -> bool:
	if not map_service:
		push_error("HexGridView requires map_service.")
		return false
	return true

func _setup_tileset() -> bool:
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
	var projection_error := HexGridProjection.validate_tile_set(ts)
	if not projection_error.is_empty():
		push_error(projection_error)
		return false
	return true

func axial_to_local(axial: Vector2i) -> Vector2:
	return map_to_local(HexGridProjection.axial_to_map(axial))

func local_to_axial(local_position: Vector2) -> Vector2i:
	return HexGridProjection.map_to_axial(local_to_map(local_position))

func _on_map_updated() -> void:
	clear()
	var all_coords = map_service.model.get_all_coords()
	for coord in all_coords:
		var tile = map_service.get_tile(coord)
		if tile:
			_draw_tile(coord, tile.terrain)

func _on_tile_changed(coord: Vector2i, terrain: TerrainType) -> void:
	_draw_tile(coord, terrain)

func _draw_tile(axial: Vector2i, terrain: TerrainType) -> void:
	# Here we map the logical TerrainType to the visual Atlas Coords
	set_cell(HexGridProjection.axial_to_map(axial), TILE_SOURCE_ID, terrain.atlas_coords)
