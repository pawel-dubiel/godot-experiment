class_name Command
extends RefCounted

## Base class for all game actions.
## Commands represent an INTENT to do something.

signal executed()
signal failed(reason: String)

var source: Node
var target: Node

func _init(p_source: Node = null, p_target: Node = null) -> void:
	source = p_source
	target = p_target

## Returns true if the command is valid and can be executed.
func validate() -> bool:
	return true

## Executes the command logic.
func execute() -> void:
	executed.emit()
