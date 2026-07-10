class_name ActionBar
extends CanvasLayer

signal action_selected(action_id: StringName)

const COLOR_PANEL := Color("17201d")
const COLOR_PANEL_EDGE := Color("5f6c55")
const COLOR_TEXT := Color("f2ead7")
const COLOR_MUTED := Color("a8ad9e")
const COLOR_BRASS := Color("e8c56a")
const COLOR_GREEN := Color("76946a")
const COLOR_ERROR := Color("e06a50")

var _panel: PanelContainer
var _unit_label: Label
var _hint_label: Label
var _actions_row: HBoxContainer
var _feedback_label: Label
var _context: GameContext
var _action_buttons: Array[Button] = []

func _ready() -> void:
	layer = 50
	_build_interface()
	visible = false

func present(unit_name: String, actions: Array[ActionDescriptor], armed_action_id: StringName, context: GameContext) -> void:
	if not context:
		push_error("ActionBar.present requires a GameContext.")
		return
	_context = context
	_clear_action_buttons()
	_unit_label.text = unit_name.to_upper()
	_hint_label.text = "CHOOSE A COMMAND" if armed_action_id.is_empty() else "TARGETING · RIGHT-CLICK A HIGHLIGHTED HEX"

	for index in actions.size():
		var descriptor := actions[index]
		var contract_error := descriptor.validate_contract()
		if not contract_error.is_empty():
			push_error("ActionBar cannot present invalid descriptor: %s" % contract_error)
			return
		var button := _create_action_button(descriptor, index + 1, descriptor.action_id == armed_action_id)
		_actions_row.add_child(button)
		_action_buttons.append(button)

	_feedback_label.text = ""
	visible = true

func clear() -> void:
	_context = null
	_clear_action_buttons()
	visible = false

func show_feedback(message: String, is_error := false) -> void:
	if not visible:
		return
	_feedback_label.text = message
	_feedback_label.modulate = COLOR_ERROR if is_error else COLOR_MUTED

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode < KEY_1 or event.keycode > KEY_9:
		return
	var action_index: int = int(event.keycode) - int(KEY_1)
	if action_index < 0 or action_index >= _action_buttons.size():
		return
	var button := _action_buttons[action_index]
	if button.disabled:
		show_feedback(button.tooltip_text)
		return
	button.pressed.emit()
	get_viewport().set_input_as_handled()

func _build_interface() -> void:
	_panel = PanelContainer.new()
	_panel.name = "CommandConsole"
	_panel.anchor_left = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -360.0
	_panel.offset_top = -150.0
	_panel.offset_right = 360.0
	_panel.offset_bottom = -18.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	_unit_label = Label.new()
	_unit_label.add_theme_color_override("font_color", COLOR_BRASS)
	_unit_label.add_theme_font_size_override("font_size", 17)
	_unit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_unit_label)
	_hint_label = Label.new()
	_hint_label.add_theme_color_override("font_color", COLOR_MUTED)
	_hint_label.add_theme_font_size_override("font_size", 11)
	header.add_child(_hint_label)

	var divider := HSeparator.new()
	divider.modulate = COLOR_PANEL_EDGE
	layout.add_child(divider)

	_actions_row = HBoxContainer.new()
	_actions_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_actions_row.add_theme_constant_override("separation", 10)
	_actions_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_actions_row)

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 12)
	_feedback_label.add_theme_color_override("font_color", COLOR_MUTED)
	layout.add_child(_feedback_label)

func _create_action_button(descriptor: ActionDescriptor, shortcut_number: int, armed: bool) -> Button:
	var button := Button.new()
	button.name = "Action_%s" % descriptor.action_id
	button.custom_minimum_size = Vector2(118, 70)
	button.text = "[%d]  %s" % [shortcut_number, descriptor.display_name.to_upper()]
	button.icon = descriptor.icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.toggle_mode = true
	button.button_pressed = armed
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_PANEL)
	button.add_theme_stylebox_override("normal", _button_style(Color("24302b"), COLOR_PANEL_EDGE, 1))
	button.add_theme_stylebox_override("hover", _button_style(Color("304038"), COLOR_BRASS, 2))
	button.add_theme_stylebox_override("pressed", _button_style(COLOR_BRASS, COLOR_BRASS, 2))
	button.add_theme_stylebox_override("disabled", _button_style(Color("1b2420"), Color("39433b"), 1))

	var availability := descriptor.availability(_context)
	if not availability.is_success():
		push_error(availability.error)
		button.disabled = true
		button.tooltip_text = availability.error
		return button
	button.disabled = not availability.value
	if not availability.value:
		var reason := descriptor.get_unavailable_reason(_context)
		if not reason.is_success():
			push_error(reason.error)
			button.tooltip_text = reason.error
			return button
		if reason.value.strip_edges().is_empty():
			push_error("Unavailable action %s requires a player-facing reason." % descriptor.action_id)
			return button
		button.tooltip_text = reason.value
	else:
		button.tooltip_text = "%s · choose target" % descriptor.display_name
	button.pressed.connect(func(): action_selected.emit(descriptor.action_id))
	return button

func _clear_action_buttons() -> void:
	_action_buttons.clear()
	if not _actions_row:
		return
	for child in _actions_row.get_children():
		_actions_row.remove_child(child)
		child.queue_free()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_PANEL_EDGE
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 12
	return style

func _button_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 11
	style.content_margin_right = 11
	return style
