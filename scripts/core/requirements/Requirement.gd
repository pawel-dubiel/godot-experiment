class_name Requirement
extends Resource

## Base Resource for command validation rules.
## Checks if a command can be performed given the source and Context.

## Returns true if the requirement is met.
func check(context: GameContext, source: Node, target: Node) -> bool:
	return true
