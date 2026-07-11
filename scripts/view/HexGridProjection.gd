class_name HexGridProjection
extends RefCounted

static func axial_to_map(axial: Vector2i) -> Vector2i:
	return HexCoordinates.axial_to_odd_row(axial)

static func map_to_axial(map_coordinate: Vector2i) -> Vector2i:
	return HexCoordinates.odd_row_to_axial(map_coordinate)

static func validate_tile_set(tile_set: TileSet) -> String:
	if not tile_set:
		return "HexGridProjection requires a TileSet."
	if tile_set.tile_shape != TileSet.TILE_SHAPE_HEXAGON:
		return "HexGridProjection requires TILE_SHAPE_HEXAGON."
	if tile_set.tile_layout != TileSet.TILE_LAYOUT_STACKED:
		return "HexGridProjection odd-row mapping requires TILE_LAYOUT_STACKED."
	if tile_set.tile_offset_axis != TileSet.TILE_OFFSET_AXIS_HORIZONTAL:
		return "HexGridProjection odd-row mapping requires TILE_OFFSET_AXIS_HORIZONTAL."
	return ""
