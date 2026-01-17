class_name TurnManager
extends Node

## Manages the flow of turn phases.

signal phase_changed(new_phase: GamePhase)
signal turn_ended(turn_number: int)

@export var phases: Array[GamePhase] = []

var current_phase_index: int = 0
var current_turn: int = 1
var active_phase: GamePhase

func _ready() -> void:
	if phases.size() > 0:
		start_phase(0)

func start_phase(index: int) -> void:
	if index < 0 or index >= phases.size():
		end_turn()
		return

	if active_phase:
		active_phase.on_exit(self)

	current_phase_index = index
	active_phase = phases[current_phase_index]
	
	print("Starting phase: %s" % active_phase.phase_name)
	active_phase.on_enter(self)
	phase_changed.emit(active_phase)

func advance_phase() -> void:
	start_phase(current_phase_index + 1)

func end_turn() -> void:
	print("Turn %d ended" % current_turn)
	turn_ended.emit(current_turn)
	current_turn += 1
	start_phase(0)

func _process(delta: float) -> void:
	if active_phase:
		active_phase.process_phase(delta)
