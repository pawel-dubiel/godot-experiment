extends SceneTree

const MapInputRouterScript = preload("res://scripts/input/MapInputRouter.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_test_click_emits_selection()
	_test_drag_emits_pan_and_suppresses_selection()
	_test_progressive_drag_preserves_threshold_distance()
	_test_right_click_and_escape_are_semantic_requests()
	_test_keyboard_direction_is_normalized()
	_test_mouse_wheel_zoom_direction_and_anchor()
	_test_trackpad_vertical_scroll_zooms_and_horizontal_is_ignored()
	_test_pinch_zoom_preserves_factor_and_anchor()
	_test_keyboard_zoom_direction_and_viewport_anchor()
	_test_middle_button_drag_is_ignored()

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

func _test_mouse_wheel_zoom_direction_and_anchor() -> void:
	var router = MapInputRouterScript.new()
	var requests: Array[Dictionary] = []
	router.camera_zoom_requested.connect(func(factor, anchor): requests.append({"factor": factor, "anchor": anchor}))
	router.handle_event(_mouse_button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(31, 47)))
	router.handle_event(_mouse_button(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(53, 71)))
	_expect(requests.size() == 2, "Mouse-wheel rotation must emit one zoom request per step.")
	if requests.size() == 2:
		_expect(requests[0].factor > 1.0 and requests[0].anchor == Vector2(31, 47), "Wheel up must zoom in around the pointer.")
		_expect(requests[1].factor < 1.0 and requests[1].anchor == Vector2(53, 71), "Wheel down must zoom out around the pointer.")
	router.free()

func _test_trackpad_vertical_scroll_zooms_and_horizontal_is_ignored() -> void:
	var router = MapInputRouterScript.new()
	var requests: Array[Dictionary] = []
	router.camera_zoom_requested.connect(func(factor, anchor): requests.append({"factor": factor, "anchor": anchor}))
	var upward := _pan_gesture(Vector2(0, -1), Vector2(100, 120))
	var downward := _pan_gesture(Vector2(0, 1), Vector2(140, 160))
	var horizontal := _pan_gesture(Vector2(1, 0), Vector2(180, 200))
	router.handle_event(upward)
	router.handle_event(downward)
	var horizontal_handled: bool = router.handle_event(horizontal)
	_expect(requests.size() == 2, "Only vertical two-finger scrolling must emit zoom requests.")
	if requests.size() == 2:
		_expect(requests[0].factor > 1.0 and requests[0].anchor == upward.position, "Upward two-finger scrolling must zoom in around the pointer.")
		_expect(requests[1].factor < 1.0 and requests[1].anchor == downward.position, "Downward two-finger scrolling must zoom out around the pointer.")
	_expect(not horizontal_handled, "Horizontal two-finger movement must remain unhandled.")
	router.free()

func _test_pinch_zoom_preserves_factor_and_anchor() -> void:
	var router = MapInputRouterScript.new()
	var requests: Array[Dictionary] = []
	router.camera_zoom_requested.connect(func(factor, anchor): requests.append({"factor": factor, "anchor": anchor}))
	var pinch := InputEventMagnifyGesture.new()
	pinch.factor = 1.25
	pinch.position = Vector2(220, 180)
	router.handle_event(pinch)
	_expect(requests == [{"factor": 1.25, "anchor": Vector2(220, 180)}], "Pinch zoom must preserve its factor and pointer anchor.")
	router.free()

func _test_keyboard_zoom_direction_and_viewport_anchor() -> void:
	var router = MapInputRouterScript.new()
	var requests: Array[Dictionary] = []
	router.camera_zoom_requested.connect(func(factor, anchor): requests.append({"factor": factor, "anchor": anchor}))
	router.handle_event(_key_event(KEY_EQUAL, true))
	router.handle_event(_key_event(KEY_MINUS, false))
	var expected_anchor := Vector2(DisplayServer.window_get_size()) * 0.5
	_expect(requests.size() == 2, "The + and - keys must emit zoom requests.")
	if requests.size() == 2:
		_expect(requests[0].factor > 1.0 and requests[0].anchor == expected_anchor, "+ must zoom in around the viewport center.")
		_expect(requests[1].factor < 1.0 and requests[1].anchor == expected_anchor, "- must zoom out around the viewport center.")
	router.free()

func _test_middle_button_drag_is_ignored() -> void:
	var router = MapInputRouterScript.new()
	var pan_deltas: Array[Vector2] = []
	var zoom_requests: Array[float] = []
	router.camera_pan_requested.connect(func(delta): pan_deltas.append(delta))
	router.camera_zoom_requested.connect(func(factor, _anchor): zoom_requests.append(factor))
	var press_handled := router.handle_event(_mouse_button(MOUSE_BUTTON_MIDDLE, true, Vector2(20, 20)))
	var motion_handled := router.handle_event(_mouse_motion(Vector2(20, 0), Vector2(40, 20)))
	_expect(not press_handled and not motion_handled, "Middle-button dragging must remain unhandled.")
	_expect(pan_deltas.is_empty() and zoom_requests.is_empty(), "Middle-button dragging must not pan or zoom.")
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

func _pan_gesture(delta: Vector2, position: Vector2) -> InputEventPanGesture:
	var event := InputEventPanGesture.new()
	event.delta = delta
	event.position = position
	return event

func _key_event(keycode: Key, shift_pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.shift_pressed = shift_pressed
	event.pressed = true
	return event

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
