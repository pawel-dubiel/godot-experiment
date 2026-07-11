extends SceneTree

const CoordinateOverlayScript = preload("res://scripts/CoordinateOverlay.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/TestLevel.tscn")
	var level: Node = scene.instantiate()
	root.add_child(level)
	await process_frame
	var overlay = CoordinateOverlayScript.new()
	overlay.tile_map = level.get_node("HexGridView")
	overlay.camera = level.get_node("Camera2D")
	overlay.map_service = level.get_node("MapService")
	overlay.viewport_margin = Vector2.ZERO
	level.add_child(overlay)
	await process_frame
	_assert_sparse_axial_bounds_do_not_trigger_cropping(overlay)

	for scenario in [
		{"position": Vector2(400, 300), "zoom": 1.0},
		{"position": Vector2(2400, 1800), "zoom": 0.5},
		{"position": Vector2(-300, 700), "zoom": 2.0},
	]:
		overlay.camera.position = scenario.position
		overlay.camera.zoom = Vector2.ONE * scenario.zoom
		_assert_viewport_corners_contained(overlay)

	level.queue_free()
	await process_frame
	if _failures.is_empty():
		print("COORDINATE OVERLAY BOUNDS TESTS PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)

func _assert_sparse_axial_bounds_do_not_trigger_cropping(overlay: Node2D) -> void:
	overlay.max_visible_candidate_cells = 10_000
	var map_bounds: Rect2i = overlay.map_service.model.get_bounds()
	_expect(map_bounds.size.x * map_bounds.size.y > overlay.max_visible_candidate_cells, "The regression fixture requires sparse axial bounds larger than the real tile count.")
	var limited_range: Rect2i = overlay._limit_candidate_cells(map_bounds)
	_expect(limited_range == map_bounds, "Sparse axial bounds containing at most the candidate limit must not be cropped.")

func _assert_viewport_corners_contained(overlay: Node2D) -> void:
	var visible_range: Rect2i = overlay._get_visible_map_range()
	var viewport_rect: Rect2 = overlay.get_viewport_rect()
	var visible_size: Vector2 = viewport_rect.size / overlay.camera.zoom
	var half_size := visible_size * 0.5
	var world_corners := [
		overlay.camera.global_position - half_size,
		overlay.camera.global_position + Vector2(half_size.x, -half_size.y),
		overlay.camera.global_position + half_size,
		overlay.camera.global_position + Vector2(-half_size.x, half_size.y),
	]
	for world_corner in world_corners:
		var axial_corner: Vector2i = overlay.tile_map.local_to_axial(overlay.tile_map.to_local(world_corner))
		_expect(visible_range.has_point(axial_corner), "Visible axial range %s must contain converted viewport corner %s." % [visible_range, axial_corner])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
