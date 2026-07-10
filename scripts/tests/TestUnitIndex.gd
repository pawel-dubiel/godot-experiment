extends SceneTree

const UnitIndexScript = preload("res://scripts/core/UnitIndex.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_test_tracks_and_removes_units()
	_test_rejects_duplicate_occupancy_without_mutation()
	_test_rejects_inconsistent_move_without_mutation()

	if _failures.is_empty():
		print("UNIT INDEX TESTS PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)

func _test_tracks_and_removes_units() -> void:
	var index = UnitIndexScript.new()
	var unit := _unit("Scout", Vector2i(2, -3))
	_expect(index.track(unit).is_success(), "A free coordinate must accept its unit.")
	_expect(index.unit_at(Vector2i(2, -3)) == unit, "Tracked units must be queryable by axial coordinate.")
	_expect(index.remove(unit).is_success(), "Removing the indexed unit must succeed.")
	_expect(index.unit_at(Vector2i(2, -3)) == null, "Removed units must leave no occupancy entry.")
	unit.free()

func _test_rejects_duplicate_occupancy_without_mutation() -> void:
	var index = UnitIndexScript.new()
	var first := _unit("First", Vector2i(1, 1))
	var second := _unit("Second", Vector2i(1, 1))
	index.track(first)
	var result: ActionResult = index.track(second)
	_expect(not result.is_success(), "Duplicate occupancy must return an explicit error.")
	_expect(index.unit_at(Vector2i(1, 1)) == first, "Rejected duplicate occupancy must not replace the indexed unit.")
	first.free()
	second.free()

func _test_rejects_inconsistent_move_without_mutation() -> void:
	var index = UnitIndexScript.new()
	var moving := _unit("Moving", Vector2i(3, 0))
	var other := _unit("Other", Vector2i(4, 0))
	index.track(moving)
	index.track(other)
	var result: ActionResult = index.move(moving, Vector2i(9, 9), Vector2i(5, 0))
	_expect(not result.is_success(), "Moving from a coordinate not owned by the unit must fail explicitly.")
	_expect(index.unit_at(Vector2i(3, 0)) == moving, "A rejected move must preserve the original occupancy.")
	_expect(index.unit_at(Vector2i(5, 0)) == null, "A rejected move must not create destination occupancy.")
	moving.free()
	other.free()

func _unit(unit_name: String, position: Vector2i) -> GameEntity:
	var unit := GameEntity.new()
	unit.name = unit_name
	unit.grid_position = position
	return unit

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
