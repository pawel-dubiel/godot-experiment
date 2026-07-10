class_name CameraControl
extends Camera2D

signal view_changed

@export var min_zoom := 0.2
@export var max_zoom := 5.0
@export_range(50.0, 2000.0, 10.0) var keyboard_pan_speed := 700.0

func pan_screen_delta(screen_delta: Vector2) -> void:
	position -= screen_delta / zoom
	view_changed.emit()

func pan_direction(direction: Vector2, delta: float) -> void:
	if direction.is_zero_approx():
		return
	position += direction * keyboard_pan_speed * delta / zoom
	view_changed.emit()

func zoom_at(factor: float, screen_anchor: Vector2) -> void:
	if factor <= 0.0:
		push_error("CameraControl zoom factor must be greater than zero.")
		return
	var world_anchor_before := get_canvas_transform().affine_inverse() * screen_anchor
	var new_zoom = zoom * factor
	new_zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

	if new_zoom != zoom:
		zoom = new_zoom
		var world_anchor_after := get_canvas_transform().affine_inverse() * screen_anchor
		global_position += world_anchor_before - world_anchor_after
		view_changed.emit()
