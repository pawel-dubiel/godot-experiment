extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/TestLevel.tscn")
	_expect(scene != null, "TestLevel must load for the large-map smoke test.")
	if not scene:
		_finish()
		return

	var started_at := Time.get_ticks_msec()
	var level := scene.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	await process_frame

	var map_service: MapService = level.get_node("MapService")
	var generated_cells := map_service.model.get_all_coords().size()
	var generated_bounds := map_service.model.get_bounds()
	var elapsed_ms := Time.get_ticks_msec() - started_at

	_expect(generated_cells == 10_000, "The standard test level must generate exactly 10,000 cells; got %d." % generated_cells)
	_expect(generated_bounds == Rect2i(Vector2i.ZERO, Vector2i(100, 100)), "The standard test level must have 100x100 bounds; got %s." % generated_bounds)
	_expect(elapsed_ms < 5_000, "The 100x100 test level must initialize within 5 seconds; took %d ms." % elapsed_ms)

	level.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("LARGE MAP TEST PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
