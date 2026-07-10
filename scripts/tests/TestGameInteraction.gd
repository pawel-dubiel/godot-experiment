extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/TestLevel.tscn")
	_expect(scene != null, "TestLevel must load.")
	if not scene:
		_finish()
		return

	var level := scene.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame

	var controller: GameController = level.get_node("GameController")
	var router: MapInputRouter = level.get_node("MapInputRouter")
	var action_bar: ActionBar = level.get_node("ActionBar")
	var overlay: TargetingOverlay = level.get_node("TargetingOverlay")
	var tile_map: HexGridView = level.get_node("HexGridView")
	var soldier: GameEntity = level.get_node("Soldier")
	var tank: GameEntity = level.get_node("Tank")
	var camera: CameraControl = level.get_node("Camera2D")

	var soldier_screen := soldier.get_global_transform_with_canvas() * Vector2.ZERO
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, true, soldier_screen))
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, false, soldier_screen))
	_expect(controller.current_selection == soldier, "A routed left-click must select the clicked unit.")
	_expect(action_bar.visible, "Selecting a unit must reveal its action bar.")

	action_bar.action_selected.emit(&"move")
	_expect(controller.armed_action != null and controller.armed_action.action_id == &"move", "Choosing Move must enter targeting mode.")
	_expect(overlay.visible, "Targeting mode must show valid-target feedback.")
	await process_frame
	var camera_position_before := camera.position
	router.camera_direction_requested.emit(Vector2.RIGHT, 0.1)
	_expect(camera.position != camera_position_before, "Camera navigation must remain available during targeting.")
	_expect(controller.armed_action != null, "Camera navigation must preserve the armed action.")
	router.handle_event(_escape_key())
	_expect(controller.armed_action == null, "Escape must cancel the armed action.")
	_expect(controller.current_selection == soldier, "Cancelling targeting must preserve selection.")

	action_bar.action_selected.emit(&"move")
	var tank_screen := tank.get_global_transform_with_canvas() * Vector2.ZERO
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, true, tank_screen))
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, false, tank_screen))
	_expect(controller.current_selection == tank, "Selecting another unit must update selection.")
	_expect(controller.armed_action == null, "Changing selection must cancel the armed action.")
	soldier_screen = soldier.get_global_transform_with_canvas() * Vector2.ZERO
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, true, soldier_screen))
	router.handle_event(_mouse_button(MOUSE_BUTTON_LEFT, false, soldier_screen))
	_expect(controller.current_selection == soldier, "The original unit must remain selectable after targeting cancellation.")

	action_bar.action_selected.emit(&"move")
	router.handle_event(_mouse_button(MOUSE_BUTTON_RIGHT, true, tank_screen))
	_expect(controller.armed_action == null, "Right-clicking an invalid explicit target must cancel targeting.")
	_expect(controller.current_selection == soldier, "Invalid explicit-target cancellation must preserve selection.")

	var destination := Vector2i(6, 2)
	var destination_center := tile_map.get_global_transform_with_canvas() * tile_map.axial_to_local(destination)
	var destination_screen := soldier_screen.lerp(destination_center, 0.55)
	var clicked_world := tile_map.get_canvas_transform().affine_inverse() * destination_screen
	var clicked_cell := tile_map.local_to_axial(tile_map.to_local(clicked_world))
	_expect(clicked_cell == destination, "The boundary test point must be inside the destination cell.")
	router.handle_event(_mouse_button(MOUSE_BUTTON_RIGHT, true, destination_screen))
	_expect(soldier.grid_position == destination, "Context actions must use exact cell occupancy rather than tolerant adjacent-unit picking.")
	_expect(controller.current_selection == soldier, "Command execution must preserve a valid selected unit.")

	soldier.queue_free()
	await process_frame
	_expect(controller.current_selection == null, "Removing the selected entity must clear selection explicitly.")
	_expect(not action_bar.visible, "Removing the selected entity must clear the action interface.")

	level.queue_free()
	await process_frame
	_finish()

func _mouse_button(button: MouseButton, pressed: bool, position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = position
	return event

func _escape_key() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	return event

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("GAME INTERACTION TESTS PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
