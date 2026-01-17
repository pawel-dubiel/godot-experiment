class_name GamePhase
extends Resource

## Base Resource for a turn phase.
## Represents a segment of a turn (e.g., Movement, Combat).

@export var phase_name: String = "Generic Phase"

## Called by the TurnManager when this phase begins.
func on_enter(turn_manager: Node) -> void:
	pass

## Called by the TurnManager when this phase ends.
func on_exit(turn_manager: Node) -> void:
	pass

## Called every frame while this phase is active.
func process_phase(delta: float) -> void:
	pass
