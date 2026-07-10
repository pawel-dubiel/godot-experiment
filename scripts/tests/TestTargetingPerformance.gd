extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/TestLevel.tscn")
	var level: Node = scene.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	var controller: GameController = level.get_node("GameController")
	var soldier: GameEntity = level.get_node("Soldier")
	var action_bar: ActionBar = level.get_node("ActionBar")
	var overlay: TargetingOverlay = level.get_node("TargetingOverlay")
	controller._set_current_selection(soldier)

	var started := Time.get_ticks_usec()
	action_bar.action_selected.emit(&"move")
	var elapsed_usec := Time.get_ticks_usec() - started
	var cached_candidates: int = overlay._valid_axial_cells.size()
	_expect(cached_candidates > 0 and cached_candidates <= 37, "Move targeting must cache no more than its 37 radius-3 candidates; got %d." % cached_candidates)
	_expect(elapsed_usec < 10_000, "Move targeting must rebuild within 10 ms on the 100x100 level; took %d microseconds." % elapsed_usec)

	level.queue_free()
	await process_frame
	if _failures.is_empty():
		print("TARGETING PERFORMANCE TEST PASSED candidates=%d elapsed_usec=%d" % [cached_candidates, elapsed_usec])
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
