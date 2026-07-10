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
