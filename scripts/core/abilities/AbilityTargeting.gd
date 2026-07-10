class_name AbilityTargeting
extends Resource

enum TargetKind {
	UNIT,
	EMPTY_HEX,
	ANY_HEX,
	SELF,
}

@export var target_kind: TargetKind = TargetKind.UNIT
@export_range(0, 1000, 1) var minimum_range: int = 1
@export_range(0, 1000, 1) var maximum_range: int = 1

func validate_contract() -> String:
	if target_kind not in [TargetKind.UNIT, TargetKind.EMPTY_HEX, TargetKind.ANY_HEX, TargetKind.SELF]:
		return "AbilityTargeting target_kind is invalid."
	if minimum_range < 0:
		return "AbilityTargeting minimum_range must be non-negative."
	if maximum_range < minimum_range:
		return "AbilityTargeting maximum_range must be at least minimum_range."
	return ""

func candidate_coordinates(source: GameEntity, context: GameContext) -> ActionResult:
	var dependency_error := _validate_dependencies(source, context)
	if not dependency_error.is_empty():
		return ActionResult.failure(dependency_error)
	var candidates: Array[Vector2i] = []
	for coordinate in HexCoordinates.within_range(source.grid_position, maximum_range):
		var distance := HexCoordinates.distance(source.grid_position, coordinate)
		if distance < minimum_range or not context.map_service.model.has_tile(coordinate):
			continue
		candidates.append(coordinate)
	return ActionResult.success(candidates)

func validate_target(source: GameEntity, target: MapActionTarget, context: GameContext) -> ActionResult:
	var dependency_error := _validate_dependencies(source, context)
	if not dependency_error.is_empty():
		return ActionResult.failure(dependency_error)
	if not target:
		return ActionResult.failure("AbilityTargeting requires a MapActionTarget.")
	if not context.map_service.model.has_tile(target.grid_position):
		return ActionResult.success(false)
	var distance := HexCoordinates.distance(source.grid_position, target.grid_position)
	if distance < minimum_range or distance > maximum_range:
		return ActionResult.success(false)
	match target_kind:
		TargetKind.UNIT:
			return ActionResult.success(target.entity != null and target.entity != source)
		TargetKind.EMPTY_HEX:
			return ActionResult.success(target.entity == null)
		TargetKind.ANY_HEX:
			return ActionResult.success(true)
		TargetKind.SELF:
			return ActionResult.success(target.entity == source)
		_:
			return ActionResult.failure("AbilityTargeting encountered an unknown target kind.")

func _validate_dependencies(source: GameEntity, context: GameContext) -> String:
	if not source:
		return "AbilityTargeting requires a GameEntity source."
	if not context or not context.map_service:
		return "AbilityTargeting requires GameContext.map_service."
	return validate_contract()
