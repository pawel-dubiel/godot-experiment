extends SceneTree

const MapActionTargetScript = preload("res://scripts/actions/MapActionTarget.gd")
const MoveCommandScript = preload("res://scripts/core/commands/MoveCommand.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_test_movement_provider_contract()
	_test_attack_provider_contract()
	_test_move_command_uses_movement_validation()

	if _failures.is_empty():
		print("UNIT ACTION PROVIDER TESTS PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)

func _test_movement_provider_contract() -> void:
	var entity := GameEntity.new()
	var movement := MovementComponent.new()
	entity.add_child(movement)
	movement.set_move_validator(func(_unit, _destination): return true)
	var context := GameContext.new(MapService.new())
	var descriptors: Array = movement.get_action_descriptors(context)
	_expect(descriptors.size() == 1, "MovementComponent must expose exactly one action descriptor.")
	if descriptors.is_empty():
		return
	var descriptor: ActionDescriptor = descriptors[0]
	_expect(descriptor.action_id == &"move", "Movement action ID must be stable.")
	_expect(descriptor.icon != null, "Movement action must provide an explicit icon.")
	_expect(descriptor.targeting_mode == ActionDescriptor.TargetingMode.HEX, "Movement must target a hex.")
	var empty_hex = MapActionTargetScript.new(Vector2i(1, 1), null)
	_expect(descriptor.matches_context(empty_hex, context), "Movement must be contextual on an empty hex in range.")
	var movement_candidates: Array[Vector2i] = descriptor.get_candidate_coordinates(context)
	_expect(movement_candidates.size() == 37, "Move range 3 must enumerate exactly 37 axial candidates.")
	movement.move_range = -1
	var invalid_descriptor: ActionDescriptor = movement.get_action_descriptors(context)[0]
	_expect(invalid_descriptor.get_candidate_coordinates(context).is_empty(), "Negative movement range must abort candidate enumeration.")
	_expect(not invalid_descriptor.last_contract_error.is_empty(), "Negative movement range must propagate an explicit descriptor contract error.")

func _test_attack_provider_contract() -> void:
	var attacker := GameEntity.new()
	var attack := AttackComponent.new()
	attacker.add_child(attack)
	var target := GameEntity.new()
	target.grid_position = Vector2i(1, 0)
	var context := GameContext.new(MapService.new())
	var descriptors: Array = attack.get_action_descriptors(GameContext.new())
	_expect(descriptors.size() == 1, "AttackComponent must expose exactly one action descriptor.")
	if descriptors.is_empty():
		return
	var descriptor: ActionDescriptor = descriptors[0]
	_expect(descriptor.action_id == &"attack", "Attack action ID must be stable.")
	_expect(descriptor.icon != null, "Attack action must provide an explicit icon.")
	_expect(descriptor.targeting_mode == ActionDescriptor.TargetingMode.UNIT, "Attack must target a unit.")
	var occupied_hex = MapActionTargetScript.new(Vector2i(3, 4), target)
	_expect(descriptor.matches_context(occupied_hex, context), "Attack must be contextual on another unit in range.")
	var attack_candidates: Array[Vector2i] = descriptor.get_candidate_coordinates(context)
	_expect(attack_candidates.size() == 7, "Attack range 1 must enumerate exactly 7 axial candidates.")

func _test_move_command_uses_movement_validation() -> void:
	var entity := GameEntity.new()
	var movement := MovementComponent.new()
	entity.add_child(movement)
	movement.set_move_validator(func(_unit, _destination): return true)
	var context := GameContext.new(MapService.new())
	var allowed = MoveCommandScript.new(entity, Vector2i(1, 2), movement)
	var blocked = MoveCommandScript.new(entity, Vector2i(8, 8), movement)
	_expect(allowed.validate(context), "MoveCommand must accept a destination allowed by MovementComponent.")
	_expect(not blocked.validate(context), "MoveCommand must reject a destination blocked by MovementComponent.")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
