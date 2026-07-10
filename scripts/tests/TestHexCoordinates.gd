extends SceneTree

const HexCoordinatesScript = preload("res://scripts/core/hex/HexCoordinates.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_test_six_axial_neighbors()
	_test_distance_contract()
	_test_axial_range_cardinality()

	if _failures.is_empty():
		print("HEX COORDINATE TESTS PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)

func _test_six_axial_neighbors() -> void:
	var neighbors: Array[Vector2i] = HexCoordinatesScript.neighbors(Vector2i.ZERO)
	var expected: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-1, 0),
		Vector2i(0, -1),
		Vector2i(1, -1),
	]
	_expect(neighbors == expected, "Axial neighbors must use the six canonical q/r directions; got %s." % [neighbors])
	_expect(HexCoordinatesScript.neighbors(Vector2i(4, -2))[2] == Vector2i(3, -1), "Neighbor directions must translate from any axial origin.")

func _test_distance_contract() -> void:
	_expect(HexCoordinatesScript.distance(Vector2i.ZERO, Vector2i.ZERO) == 0, "A coordinate must have zero distance from itself.")
	_expect(HexCoordinatesScript.distance(Vector2i.ZERO, Vector2i(1, 0)) == 1, "Axial neighbors must be one cell apart.")
	_expect(HexCoordinatesScript.distance(Vector2i.ZERO, Vector2i(3, 2)) == 5, "Axial distance must use the implied cube axis.")
	_expect(HexCoordinatesScript.distance(Vector2i(3, 2), Vector2i.ZERO) == 5, "Axial distance must be symmetric.")

func _test_axial_range_cardinality() -> void:
	var center := Vector2i(4, -3)
	_expect(HexCoordinatesScript.within_range(center, 0) == [center], "Radius zero must contain only the center.")
	var radius_one: Array[Vector2i] = HexCoordinatesScript.within_range(center, 1)
	var radius_three: Array[Vector2i] = HexCoordinatesScript.within_range(center, 3)
	_expect(radius_one.size() == 7, "Axial radius one must contain 7 cells.")
	_expect(radius_three.size() == 37, "Axial radius three must contain 37 cells.")
	var unique := {}
	for coordinate in radius_three:
		unique[coordinate] = true
		_expect(HexCoordinatesScript.distance(center, coordinate) <= 3, "Every generated candidate must be within the requested radius.")
	_expect(unique.size() == radius_three.size(), "Axial range generation must not return duplicates.")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
