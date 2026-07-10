extends SceneTree

const MapActionTargetScript = preload("res://scripts/actions/MapActionTarget.gd")
const MoveCommandScript = preload("res://scripts/core/commands/MoveCommand.gd")
const AbilityComponentScript = preload("res://scripts/components/AbilityComponent.gd")
const AutomaticResolutionScript = preload("res://scripts/core/abilities/AutomaticResolution.gd")
const AbilityTargetingScript = preload("res://scripts/core/abilities/AbilityTargeting.gd")
const DamageOutcomeEffectScript = preload("res://scripts/core/abilities/DamageOutcomeEffect.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_test_movement_provider_contract()
	_test_units_expose_different_and_multiple_abilities()
	_test_ability_commands_apply_resolved_damage()
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
	var match_result: ActionResult = descriptor.matches_context(empty_hex, context)
	_expect(match_result.is_success() and match_result.value == true, "Movement must be contextual on an empty hex in range.")
	var candidate_result: ActionResult = descriptor.get_candidate_coordinates(context)
	var movement_candidates: Array[Vector2i] = candidate_result.value
	_expect(movement_candidates.size() == 37, "Move range 3 must enumerate exactly 37 axial candidates.")
	movement.move_range = -1
	var invalid_descriptor: ActionDescriptor = movement.get_action_descriptors(context)[0]
	var invalid_result: ActionResult = invalid_descriptor.get_candidate_coordinates(context)
	_expect(not invalid_result.is_success(), "Negative movement range must abort candidate enumeration with an explicit error.")

func _test_units_expose_different_and_multiple_abilities() -> void:
	var rifle := _ability(&"rifle", "Rifle", 10.0, 3)
	rifle.uses_charges = true
	rifle.maximum_charges = 2
	var grenade := _ability(&"grenade", "Grenade", 20.0, 4)
	var soldier := GameEntity.new()
	var soldier_abilities = AbilityComponentScript.new()
	soldier.add_child(soldier_abilities)
	var soldier_definitions: Array[AbilityDefinition] = [rifle, grenade]
	_expect(soldier_abilities.configure(soldier_definitions).is_success(), "A unit must accept an explicit set of ability definitions.")
	var soldier_actions: Array = soldier_abilities.get_action_descriptors(GameContext.new(MapService.new()))
	_expect(soldier_actions.size() == 2, "A unit must expose every attached ability.")
	_expect(soldier_actions[0].action_id == &"rifle" and soldier_actions[1].action_id == &"grenade", "Ability action order must follow authored definition order.")
	var duplicate_definitions: Array[AbilityDefinition] = [rifle, rifle]
	_expect(not soldier_abilities.configure(duplicate_definitions).is_success(), "Duplicate ability IDs must reject reconfiguration.")
	_expect(not soldier_abilities.validate_action_provider_contract().is_empty(), "A rejected reconfiguration must leave the provider in an explicit error state.")
	_expect(soldier_abilities.configure(soldier_definitions).is_success(), "An explicit valid configuration must clear the provider error state.")

	var tank := GameEntity.new()
	var tank_abilities = AbilityComponentScript.new()
	tank.add_child(tank_abilities)
	var tank_definitions: Array[AbilityDefinition] = [rifle]
	tank_abilities.configure(tank_definitions)
	var soldier_instance: AbilityInstance = soldier_abilities.get_ability_instance(&"rifle").value
	var tank_instance: AbilityInstance = tank_abilities.get_ability_instance(&"rifle").value
	soldier_instance.commit_use()
	_expect(tank_instance.remaining_charges == 2, "Two units using one definition must retain independent runtime state.")
	soldier.free()
	tank.free()

func _test_ability_commands_apply_resolved_damage() -> void:
	var attacker := GameEntity.new()
	attacker.name = "Attacker"
	attacker.grid_position = Vector2i.ZERO
	var abilities = AbilityComponentScript.new()
	attacker.add_child(abilities)
	var definitions: Array[AbilityDefinition] = [_ability(&"rifle", "Rifle", 12.0, 3)]
	abilities.configure(definitions)
	var target := GameEntity.new()
	target.name = "Target"
	target.grid_position = Vector2i(1, 0)
	var health := HealthComponent.new()
	target.add_child(health)
	health._enter_tree()
	health._ready()
	health.current_hp = 100
	var map_service := MapService.new()
	var terrain := TerrainType.new()
	map_service.set_tile(attacker.grid_position, terrain)
	map_service.set_tile(target.grid_position, terrain)
	var context := GameContext.new(map_service)
	var descriptor: ActionDescriptor = abilities.get_action_descriptors(context)[0]
	var action_target := MapActionTargetScript.new(target.grid_position, target)
	var command_result := descriptor.create_command(action_target, context)
	_expect(command_result.is_success(), "A valid ability target must create a command.")
	if command_result.is_success():
		var executed := CommandExecutor.new().execute(command_result.value, context)
		_expect(executed, "A valid ability command must execute through CommandExecutor.")
		_expect(health.current_hp == 88, "Resolved damage magnitude must be applied by the outcome effect.")
	attacker.free()
	target.free()

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

func _ability(id: StringName, label: String, power: float, maximum_range: int) -> AbilityDefinition:
	var definition := AbilityDefinition.new()
	definition.ability_id = id
	definition.display_name = label
	definition.icon = preload("res://assets/ui/action-attack.svg")
	definition.targeting = AbilityTargetingScript.new()
	definition.targeting.target_kind = AbilityTargetingScript.TargetKind.UNIT
	definition.targeting.minimum_range = 1
	definition.targeting.maximum_range = maximum_range
	definition.base_power = power
	definition.resolution = AutomaticResolutionScript.new()
	var effects: Array[OutcomeEffect] = [DamageOutcomeEffectScript.new()]
	definition.outcome_effects = effects
	return definition

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
