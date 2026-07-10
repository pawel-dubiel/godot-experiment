class_name HexGridProjection
extends RefCounted

static func axial_to_map(axial: Vector2i) -> Vector2i:
	var row := axial.y
	var column_offset := _odd_row_column_offset(row)
	return Vector2i(axial.x + column_offset, row)

static func map_to_axial(map_coordinate: Vector2i) -> Vector2i:
	var row := map_coordinate.y
	var column_offset := _odd_row_column_offset(row)
	return Vector2i(map_coordinate.x - column_offset, row)

static func _odd_row_column_offset(row: int) -> int:
	# posmod keeps odd/even classification mathematical for negative rows.
	return floori(float(row - posmod(row, 2)) / 2.0)

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
