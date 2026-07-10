class_name RangeRequirement
extends Requirement

## Checks if the target is within a certain distance of the source.
## Requires both source and target to have a position on the map.

@export var min_range: int = 1
@export var max_range: int = 1

func validate_contract() -> String:
	if min_range < 0:
		return "RangeRequirement min_range must be non-negative."
	if max_range < min_range:
		return "RangeRequirement max_range must be at least min_range."
	return ""

func check(context: GameContext, source: Node, target: Node) -> bool:
	var contract_error := validate_contract()
	if not contract_error.is_empty():
		push_error(contract_error)
		return false
	if not context or not context.map_service:
		push_error("RangeRequirement requires GameContext.map_service.")
		return false
	if not source is GameEntity or not target is GameEntity:
		push_error("RangeRequirement requires GameEntity source and target.")
		return false

	var distance := context.map_service.get_distance(source.grid_position, target.grid_position)
	return distance >= min_range and distance <= max_range
