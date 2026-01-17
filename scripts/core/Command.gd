class_name Command
extends RefCounted

## Base class for all game actions.
## Commands represent an INTENT to do something.

signal executed()
signal failed(reason: String)

var source: Node
var target: Node

# Advanced Rule System
var requirements: Array[Requirement] = []
var effects: Array[Effect] = []

func _init(p_source: Node = null, p_target: Node = null) -> void:
	source = p_source
	target = p_target

## Returns true if the command is valid and can be executed.
## Iterates through all requirements.
func validate(context: GameContext) -> bool:
	for req in requirements:
		if not req.check(context, source, target):
			# In a real system, we might want to return the specific reason
			return false
	return true

## Executes the command logic.
## Applies all effects.
func execute(context: GameContext) -> void:
	if not validate(context):
		failed.emit("Validation failed")
		return
		
	# Apply all configured effects
	for effect in effects:
		effect.apply(context, source, target)
		
	executed.emit()
