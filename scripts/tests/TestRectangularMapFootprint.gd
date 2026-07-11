extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	_test_generator_fills_exact_offset_rectangle()
	if _failures.is_empty():
		print("RECTANGULAR MAP FOOTPRINT TESTS PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)

func _test_generator_fills_exact_offset_rectangle() -> void:
	var map_service := MapService.new()
	var generator := RectangularMapGenerator.new()
	generator.width = 4
	generator.height = 3
	generator.map_service = map_service
	generator.default_terrain = TerrainType.new()
	generator.generate()

	var rendered_cells: Dictionary = {}
	for axial_value in map_service.model.get_all_coords():
		var axial: Vector2i = axial_value
		rendered_cells[HexGridProjection.axial_to_map(axial)] = true

	var expected_cells: Dictionary = {}
	for row in range(generator.height):
		for column in range(generator.width):
			expected_cells[Vector2i(column, row)] = true

	_expect(rendered_cells == expected_cells, "A 4x3 generated map must project to exactly columns 0-3 and rows 0-2; got %s." % [rendered_cells.keys()])
	_expect(map_service.model.get_all_coords().size() == 12, "A 4x3 footprint must contain exactly 12 whole cells.")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
