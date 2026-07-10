class_name UnitIndex
extends RefCounted

var _units_by_position: Dictionary = {}

func rebuild(units: Array[GameEntity]) -> ActionResult:
	var rebuilt: Dictionary = {}
	for unit in units:
		if not unit:
			return ActionResult.failure("UnitIndex.rebuild requires valid GameEntity values.")
		var existing: GameEntity = rebuilt.get(unit.grid_position) as GameEntity
		if existing and existing != unit:
			return ActionResult.failure(_occupied_position_error(unit.grid_position, existing, unit))
		rebuilt[unit.grid_position] = unit
	_units_by_position = rebuilt
	return ActionResult.success(true)

func track(unit: GameEntity) -> ActionResult:
	if not unit:
		return ActionResult.failure("UnitIndex.track requires a GameEntity.")
	var existing := unit_at(unit.grid_position)
	if existing and existing != unit:
		return ActionResult.failure(_occupied_position_error(unit.grid_position, existing, unit))
	_units_by_position[unit.grid_position] = unit
	return ActionResult.success(true)

func move(unit: GameEntity, previous_position: Vector2i, new_position: Vector2i) -> ActionResult:
	if not unit:
		return ActionResult.failure("UnitIndex.move requires a GameEntity.")
	var indexed_at_origin := unit_at(previous_position)
	if indexed_at_origin != unit:
		var indexed_name: String = String(indexed_at_origin.name) if indexed_at_origin else "nothing"
		return ActionResult.failure(
			"UnitIndex expected %s at %s, but found %s." % [unit.name, previous_position, indexed_name]
		)
	var destination_unit := unit_at(new_position)
	if destination_unit and destination_unit != unit:
		return ActionResult.failure(_occupied_position_error(new_position, destination_unit, unit))
	_units_by_position.erase(previous_position)
	_units_by_position[new_position] = unit
	return ActionResult.success(true)

func remove(unit: GameEntity) -> ActionResult:
	if not unit:
		return ActionResult.failure("UnitIndex.remove requires a GameEntity.")
	var indexed := unit_at(unit.grid_position)
	if indexed != unit:
		var indexed_name: String = String(indexed.name) if indexed else "nothing"
		return ActionResult.failure(
			"UnitIndex cannot remove %s from %s because it contains %s." % [unit.name, unit.grid_position, indexed_name]
		)
	_units_by_position.erase(unit.grid_position)
	return ActionResult.success(true)

func unit_at(position: Vector2i) -> GameEntity:
	return _units_by_position.get(position) as GameEntity

func _occupied_position_error(position: Vector2i, existing: GameEntity, incoming: GameEntity) -> String:
	return "Grid position %s is occupied by %s; cannot index %s." % [position, existing.name, incoming.name]
