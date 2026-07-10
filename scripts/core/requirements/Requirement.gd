class_name Requirement
extends Resource

## Base Resource for command validation rules.
## Checks if a command can be performed given the source and Context.

## Returns true if the requirement is met.
func validate_contract() -> String:
	return "Requirement.validate_contract() must be implemented."

func check(_context: GameContext, _source: Node, _target: Node) -> bool:
	push_error("Requirement.check() must be implemented.")
	return false
