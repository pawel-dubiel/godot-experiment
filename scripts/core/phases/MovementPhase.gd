class_name MovementPhase
extends GamePhase

## Phase where units can move.
## This conceptual phase would typically unlock movement capabilities
## or listen for MoveCommands.

func on_enter(turn_manager: Node) -> void:
	print(">>> Movement Phase Started")
	# In a real implementation, you might:
	# 1. Reset unit movement points
	# 2. Enable selection of friendly units
	pass

func on_exit(turn_manager: Node) -> void:
	print("<<< Movement Phase Ended")
	# Disable selection or lock movement
	pass
