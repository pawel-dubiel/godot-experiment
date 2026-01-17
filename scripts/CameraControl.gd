extends Camera2D

@export var min_zoom := 0.2
@export var max_zoom := 5.0
@export var zoom_factor := 1.1 # For discrete steps (Wheel, Keyboard)
@export var gesture_sensitivity := 0.05 # For continuous gestures (Trackpad)

func _ready() -> void:
	position = Vector2(900, 780)

func _unhandled_input(event: InputEvent) -> void:
	# 1. Discrete Mouse Wheel (Standard Mouse)
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			apply_zoom(zoom_factor)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			apply_zoom(1.0 / zoom_factor)
	
	# 2. Trackpad Pinch (Mac/Laptop)
	if event is InputEventMagnifyGesture:
		# Apply sensitivity to the pinch gesture
		var factor = 1.0 + (event.factor - 1.0) * gesture_sensitivity * 10.0
		apply_zoom(factor)
	
	# 3. Trackpad Two-Finger Scroll (Mac)
	if event is InputEventPanGesture:
		# Use a very small factor based on delta.y to make it smooth
		# delta.y is usually small per frame
		var factor = 1.0 + (-event.delta.y * gesture_sensitivity)
		apply_zoom(factor)

	# 4. Keyboard (+/-)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL: # +
			apply_zoom(zoom_factor)
		elif event.keycode == KEY_MINUS: # -
			apply_zoom(1.0 / zoom_factor)
	
	# Panning (Middle/Right Click)
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			position -= event.relative / zoom

func apply_zoom(factor: float) -> void:
	var new_zoom = zoom * factor
	new_zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	
	if new_zoom != zoom:
		zoom = new_zoom