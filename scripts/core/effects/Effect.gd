class_name Effect
extends Resource

## Base Resource for command consequences.
## Applies changes to the game state (source, target, environment).

## Executes the effect logic.
func apply(context: GameContext, source: Node, target: Node) -> void:
	pass
