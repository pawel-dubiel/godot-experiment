extends SceneTree

const MapInputRouterScript = preload("res://scripts/input/MapInputRouter.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_test_click_emits_selection()
	_test_drag_emits_pan_and_suppresses_selection()
	_test_progressive_drag_preserves_threshold_distance()
	_test_right_click_and_escape_are_semantic_requests()
	_test_keyboard_direction_is_normalized()

	if _failures.is_empty():
		print("MAP INPUT ROUTER TESTS PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)

func _test_click_emits_selection() -> void:
	var router = MapInputRouterScript.new()
	var selected_positions: Array[Vector2] = []
	router.selection_requested.connect(func(position): selected_positions.append(position))
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, true, Vector2(10, 10)))
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, false, Vector2(13, 12)))
	_expect(selected_positions == [Vector2(13, 12)], "A sub-threshold left release must emit one selection request.")
	router.free()

func _test_drag_emits_pan_and_suppresses_selection() -> void:
	var router = MapInputRouterScript.new()
	router.drag_threshold_pixels = 8.0
	var selections: Array[Vector2] = []
	var pan_deltas: Array[Vector2] = []
	router.selection_requested.connect(func(position): selections.append(position))
	router.camera_pan_requested.connect(func(delta): pan_deltas.append(delta))
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, true, Vector2(20, 20)))
	router.handle_event(_mouse_motion(Vector2(10, 0), Vector2(30, 20)))
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, false, Vector2(30, 20)))
	_expect(selections.is_empty(), "A threshold-crossing drag must suppress selection on release.")
	_expect(pan_deltas == [Vector2(10, 0)], "A threshold-crossing drag must emit its screen delta once.")
	router.free()

func _test_progressive_drag_preserves_threshold_distance() -> void:
	var router = MapInputRouterScript.new()
	router.drag_threshold_pixels = 8.0
	var pan_deltas: Array[Vector2] = []
	router.camera_pan_requested.connect(func(delta): pan_deltas.append(delta))
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, true, Vector2.ZERO))
	router.handle_event(_mouse_motion(Vector2(3, 0), Vector2(3, 0)))
	router.handle_event(_mouse_motion(Vector2(3, 0), Vector2(6, 0)))
	router.handle_event(_mouse_motion(Vector2(3, 0), Vector2(9, 0)))
	_expect(pan_deltas == [Vector2(9, 0)], "Crossing the drag threshold gradually must preserve the full pointer displacement.")
	router.free()

func _test_right_click_and_escape_are_semantic_requests() -> void:
	var router = MapInputRouterScript.new()
	var contextual_positions: Array[Vector2] = []
	var cancellations: Array[bool] = []
	router.context_action_requested.connect(func(position): contextual_positions.append(position))
	router.targeting_cancel_requested.connect(func(): cancellations.append(true))
	router.handle_event(_mouse_button(MOUSE_BUTTON_RIGHT, true, Vector2(40, 50)))
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	router.handle_event(escape)
	_expect(contextual_positions == [Vector2(40, 50)], "Right-click must emit one contextual action request.")
	_expect(cancellations.size() == 1, "Escape must emit one targeting cancellation request.")
	router.free()

func _test_keyboard_direction_is_normalized() -> void:
	var router = MapInputRouterScript.new()
	var direction: Vector2 = router.compose_keyboard_direction(1.0, 0.0, 1.0, 0.0)
	_expect(is_equal_approx(direction.length(), 1.0), "Diagonal keyboard camera movement must be normalized.")
	_expect(direction.x < 0.0 and direction.y < 0.0, "Left and up strengths must produce an up-left direction.")
	router.free()

func _mouse_button(button: MouseButton, pressed: bool, position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = position
	return event

func _mouse_motion(relative: Vector2, position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.position = position
	return event

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
