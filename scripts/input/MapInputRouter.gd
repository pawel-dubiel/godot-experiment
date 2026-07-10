class_name MapInputRouter
extends Node

signal selection_requested(screen_position: Vector2)
signal context_action_requested(screen_position: Vector2)
signal targeting_cancel_requested
signal camera_pan_requested(screen_delta: Vector2)
signal camera_direction_requested(direction: Vector2, delta: float)
signal camera_zoom_requested(factor: float, screen_anchor: Vector2)

@export_range(1.0, 64.0, 1.0) var drag_threshold_pixels := 8.0
@export_range(1.001, 2.0, 0.001) var wheel_zoom_factor := 1.1
@export_range(1.001, 2.0, 0.001) var trackpad_zoom_factor := 1.08

var _left_pressed := false
var _dragging := false
var _press_position := Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if handle_event(event):
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _text_entry_has_focus():
		return
	var direction := compose_keyboard_direction(
		Input.get_action_strength(&"camera_left"),
		Input.get_action_strength(&"camera_right"),
		Input.get_action_strength(&"camera_up"),
		Input.get_action_strength(&"camera_down")
	)
	if not direction.is_zero_approx():
		camera_direction_requested.emit(direction, delta)

func handle_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return _handle_mouse_button(event)
	if event is InputEventMouseMotion:
		return _handle_mouse_motion(event)
	if event is InputEventMagnifyGesture:
		camera_zoom_requested.emit(event.factor, event.position)
		return true
	if event is InputEventPanGesture:
		return _handle_trackpad_scroll(event)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed(&"camera_zoom_in"):
			camera_zoom_requested.emit(wheel_zoom_factor, _window_center())
			return true
		if event.is_action_pressed(&"camera_zoom_out"):
			camera_zoom_requested.emit(1.0 / wheel_zoom_factor, _window_center())
			return true
		if event.keycode == KEY_ESCAPE:
			targeting_cancel_requested.emit()
			return true
	return false

func compose_keyboard_direction(left: float, right: float, up: float, down: float) -> Vector2:
	var direction := Vector2(right - left, down - up)
	return direction.normalized() if direction.length_squared() > 1.0 else direction

func _handle_trackpad_scroll(event: InputEventPanGesture) -> bool:
	if is_zero_approx(event.delta.y) or absf(event.delta.y) <= absf(event.delta.x):
		return false
	var factor := pow(trackpad_zoom_factor, -event.delta.y)
	camera_zoom_requested.emit(factor, event.position)
	return true

func _window_center() -> Vector2:
	return Vector2(DisplayServer.window_get_size()) * 0.5

func _handle_mouse_button(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_left_pressed = true
			_dragging = false
			_press_position = event.position
		else:
			if not _left_pressed:
				return false
			if not _dragging:
				selection_requested.emit(event.position)
			_left_pressed = false
			_dragging = false
		return true

	if not event.pressed:
		return false
	if event.button_index == MOUSE_BUTTON_RIGHT:
		context_action_requested.emit(event.position)
		return true
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		camera_zoom_requested.emit(wheel_zoom_factor, event.position)
		return true
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		camera_zoom_requested.emit(1.0 / wheel_zoom_factor, event.position)
		return true
	return false

func _handle_mouse_motion(event: InputEventMouseMotion) -> bool:
	if not _left_pressed:
		return false
	var started_dragging := false
	if not _dragging and event.position.distance_to(_press_position) >= drag_threshold_pixels:
		_dragging = true
		started_dragging = true
	if _dragging:
		var pan_delta := event.position - _press_position if started_dragging else event.relative
		camera_pan_requested.emit(pan_delta)
	return true

func _text_entry_has_focus() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit
