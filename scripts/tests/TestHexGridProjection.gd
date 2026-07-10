extends SceneTree

const HexGridProjectionScript = preload("res://scripts/view/HexGridProjection.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_adapter_round_trip()
	await _test_rendered_projection()

	if _failures.is_empty():
		print("HEX GRID PROJECTION TESTS PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)

func _test_adapter_round_trip() -> void:
	for q in range(-6, 7):
		for r in range(-6, 7):
			var axial := Vector2i(q, r)
			var map_coordinate: Vector2i = HexGridProjectionScript.axial_to_map(axial)
			_expect(HexGridProjectionScript.map_to_axial(map_coordinate) == axial, "Axial/map projection must round-trip %s." % axial)
	_expect(HexGridProjectionScript.axial_to_map(Vector2i(0, 2)) == Vector2i(1, 2), "Even row 2 must apply odd-row offset conversion.")
	_expect(HexGridProjectionScript.map_to_axial(Vector2i(1, 2)) == Vector2i(0, 2), "Even row 2 must convert back to axial.")
	_expect(HexGridProjectionScript.axial_to_map(Vector2i(0, -1)) == Vector2i(-1, -1), "Negative odd rows must use mathematical parity.")
	_expect(HexGridProjectionScript.map_to_axial(Vector2i(-1, -1)) == Vector2i(0, -1), "Negative odd rows must round-trip to axial.")
	var incompatible := TileSet.new()
	incompatible.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	incompatible.tile_layout = TileSet.TILE_LAYOUT_STAIRS_RIGHT
	incompatible.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	_expect(not HexGridProjectionScript.validate_tile_set(incompatible).is_empty(), "The odd-row adapter must reject an incompatible Godot tile layout.")

func _test_rendered_projection() -> void:
	var scene: PackedScene = load("res://scenes/TestLevel.tscn")
	var level: Node = scene.instantiate()
	root.add_child(level)
	await process_frame
	var grid: HexGridView = level.get_node("HexGridView")
	_expect(grid.axial_to_local(Vector2i(0, 0)) == Vector2(45, 52), "Axial origin must retain its rendered center.")
	_expect(grid.axial_to_local(Vector2i(1, 0)) == Vector2(135, 52), "The +q basis must retain its rendered center.")
	_expect(grid.axial_to_local(Vector2i(1, 1)) == Vector2(180, 130), "Combined q/r projection must retain its rendered center.")
	for axial in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(1, 1), Vector2i(-3, 2)]:
		_expect(grid.local_to_axial(grid.axial_to_local(axial)) == axial, "Local/view projection must round-trip axial coordinate %s." % axial)
	for q in range(-4, 5):
		for r in range(-4, 5):
			var axial := Vector2i(q, r)
			var rendered_neighbors: Array[Vector2i] = []
			for map_neighbor in grid.get_surrounding_cells(HexGridProjectionScript.axial_to_map(axial)):
				rendered_neighbors.append(HexGridProjectionScript.map_to_axial(map_neighbor))
			_expect(_as_set(rendered_neighbors) == _as_set(HexCoordinates.neighbors(axial)), "Rendered and logical neighbors must agree at %s; rendered=%s." % [axial, rendered_neighbors])
			for neighbor in rendered_neighbors:
				_expect(HexCoordinates.distance(axial, neighbor) == 1, "Every rendered neighbor of %s must have logical distance 1; got %s." % [axial, neighbor])
	level.queue_free()
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _as_set(values: Array[Vector2i]) -> Dictionary:
	var result := {}
	for value in values:
		result[value] = true
	return result
