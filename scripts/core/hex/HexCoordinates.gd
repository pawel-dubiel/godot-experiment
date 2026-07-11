class_name HexCoordinates
extends RefCounted

const DIRECTIONS := [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, -1),
]

static func neighbors(axial: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in DIRECTIONS:
		result.append(axial + direction)
	return result

static func distance(a: Vector2i, b: Vector2i) -> int:
	var delta_q := b.x - a.x
	var delta_r := b.y - a.y
	var delta_s := -delta_q - delta_r
	return maxi(abs(delta_q), maxi(abs(delta_r), abs(delta_s)))

static func axial_to_odd_row(axial: Vector2i) -> Vector2i:
	var row := axial.y
	return Vector2i(axial.x + _odd_row_column_offset(row), row)

static func odd_row_to_axial(offset: Vector2i) -> Vector2i:
	var row := offset.y
	return Vector2i(offset.x - _odd_row_column_offset(row), row)

static func odd_row_rectangle(width: int, height: int) -> Array[Vector2i]:
	if width <= 0 or height <= 0:
		push_error("HexCoordinates.odd_row_rectangle requires positive width and height.")
		return []
	var result: Array[Vector2i] = []
	result.resize(width * height)
	var index := 0
	for row in range(height):
		for column in range(width):
			result[index] = odd_row_to_axial(Vector2i(column, row))
			index += 1
	return result

static func within_range(center: Vector2i, radius: int) -> Array[Vector2i]:
	if radius < 0:
		push_error("HexCoordinates.within_range requires a non-negative radius.")
		return []
	var result: Array[Vector2i] = []
	for delta_q in range(-radius, radius + 1):
		var min_delta_r := maxi(-radius, -delta_q - radius)
		var max_delta_r := mini(radius, -delta_q + radius)
		for delta_r in range(min_delta_r, max_delta_r + 1):
			result.append(center + Vector2i(delta_q, delta_r))
	return result

static func _odd_row_column_offset(row: int) -> int:
	# posmod preserves mathematical parity for rows below the origin.
	return floori(float(row - posmod(row, 2)) / 2.0)
