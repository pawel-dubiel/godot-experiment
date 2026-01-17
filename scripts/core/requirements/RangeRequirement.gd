class_name RangeRequirement
extends Requirement

## Checks if the target is within a certain distance of the source.
## Requires both source and target to have a position on the map.

@export var min_range: int = 1
@export var max_range: int = 1

func check(context: GameContext, source: Node, target: Node) -> bool:
	if not context.map_service:
		return false
		
	# Assuming source and target are Units (Nodes) that have a 'grid_position' property
	# or are located at a certain position known by the MapService.
	# For simplicity in this architecture, let's assume Units have a 'grid_position' property.
	
	var source_pos = source.get("grid_position")
	var target_pos = target.get("grid_position")
	
	if source_pos == null or target_pos == null:
		push_warning("RangeRequirement: Source or Target missing grid_position")
		return false

	var distance = context.map_service.get_distance(source_pos, target_pos)
	return distance >= min_range and distance <= max_range
