extends SceneTree

const StatBlockScript = preload("res://scripts/core/stats/StatBlock.gd")
const StatModifierScript = preload("res://scripts/core/stats/StatModifier.gd")
const SeededRandomSourceScript = preload("res://scripts/core/random/SeededRandomSource.gd")
const AbilityDefinitionScript = preload("res://scripts/core/abilities/AbilityDefinition.gd")
const AbilityInstanceScript = preload("res://scripts/core/abilities/AbilityInstance.gd")
const AbilityTargetingScript = preload("res://scripts/core/abilities/AbilityTargeting.gd")
const AutomaticResolutionScript = preload("res://scripts/core/abilities/AutomaticResolution.gd")
const AccuracyResolutionScript = preload("res://scripts/core/abilities/AccuracyVsEvasionResolution.gd")
const DamageOutcomeEffectScript = preload("res://scripts/core/abilities/DamageOutcomeEffect.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_test_stat_modifiers_have_explicit_order()
	_test_stat_contracts_reject_ambiguous_state()
	_test_seeded_random_sources_repeat_sequences()
	_test_shared_definitions_create_independent_runtime_state()
	_test_definition_rejects_abstract_requirements()
	_test_targeting_uses_explicit_axial_range()
	_test_automatic_resolution_always_hits()
	_test_accuracy_resolution_requires_stats_and_randomness()
	_finish()

func _test_stat_modifiers_have_explicit_order() -> void:
	var stats = StatBlockScript.new()
	_expect(stats.set_base_value(&"power", 10.0).is_success(), "A valid base stat must be accepted.")
	var flat = StatModifierScript.new()
	flat.modifier_id = &"weapon"
	flat.stat_id = &"power"
	flat.operation = StatModifierScript.Operation.FLAT
	flat.value = 5.0
	var multiplier = StatModifierScript.new()
	multiplier.modifier_id = &"buff"
	multiplier.stat_id = &"power"
	multiplier.operation = StatModifierScript.Operation.MULTIPLIER
	multiplier.value = 2.0
	_expect(stats.add_modifier(flat).is_success(), "A valid flat modifier must be accepted.")
	_expect(stats.add_modifier(multiplier).is_success(), "A valid multiplier must be accepted.")
	var value_result: ActionResult = stats.value(&"power")
	_expect(value_result.is_success() and is_equal_approx(value_result.value, 30.0), "Stats must add flat values before applying multipliers.")

func _test_stat_contracts_reject_ambiguous_state() -> void:
	var stats = StatBlockScript.new()
	stats.set_base_value(&"power", 10.0)
	var modifier = StatModifierScript.new()
	modifier.modifier_id = &"same_source"
	modifier.stat_id = &"power"
	modifier.operation = StatModifierScript.Operation.FLAT
	modifier.value = 1.0
	stats.add_modifier(modifier)
	_expect(not stats.add_modifier(modifier).is_success(), "Duplicate modifier IDs must fail explicitly.")
	_expect(not stats.value(&"missing").is_success(), "Reading an undefined stat must fail explicitly.")

func _test_seeded_random_sources_repeat_sequences() -> void:
	var first = SeededRandomSourceScript.new(12345)
	var second = SeededRandomSourceScript.new(12345)
	for index in range(5):
		var first_result: ActionResult = first.next_float()
		var second_result: ActionResult = second.next_float()
		_expect(first_result.is_success(), "A configured seeded source must produce a value at draw %d." % index)
		_expect(second_result.is_success(), "A second configured source must produce a value at draw %d." % index)
		_expect(first_result.value == second_result.value, "Equal seeds must produce equal values at draw %d." % index)

func _test_shared_definitions_create_independent_runtime_state() -> void:
	var definition = _ability_definition(AutomaticResolutionScript.new())
	definition.uses_charges = true
	definition.maximum_charges = 2
	definition.cooldown_turns = 2
	var first_result: ActionResult = AbilityInstanceScript.create(definition)
	var second_result: ActionResult = AbilityInstanceScript.create(definition)
	_expect(first_result.is_success() and second_result.is_success(), "A valid definition must create runtime instances.")
	var first = first_result.value
	var second = second_result.value
	first.commit_use()
	_expect(first.remaining_charges == 1, "Using one instance must consume its charge.")
	_expect(second.remaining_charges == 2, "Instances sharing a definition must not share charges.")
	_expect(not first.availability().value, "A committed cooldown must make the instance unavailable.")
	first.advance_turn()
	first.advance_turn()
	_expect(first.availability().value, "Advancing the configured cooldown must restore availability.")

func _test_definition_rejects_abstract_requirements() -> void:
	var definition = _ability_definition(AutomaticResolutionScript.new())
	var requirements: Array[Requirement] = [Requirement.new()]
	definition.requirements = requirements
	var result: ActionResult = AbilityInstanceScript.create(definition)
	_expect(not result.is_success(), "Ability definitions must reject requirements without a concrete contract.")

func _test_targeting_uses_explicit_axial_range() -> void:
	var source := _entity("Source", Vector2i.ZERO)
	var target := _entity("Target", Vector2i(2, 0))
	var targeting = AbilityTargetingScript.new()
	targeting.target_kind = AbilityTargetingScript.TargetKind.UNIT
	targeting.minimum_range = 1
	targeting.maximum_range = 2
	var map_service := MapService.new()
	var terrain := TerrainType.new()
	map_service.set_tile(source.grid_position, terrain)
	map_service.set_tile(target.grid_position, terrain)
	var context := GameContext.new(map_service)
	var in_range := targeting.validate_target(source, MapActionTarget.new(target.grid_position, target), context)
	_expect(in_range.is_success() and in_range.value, "A unit at the configured maximum axial range must be valid.")
	target.grid_position = Vector2i(1, 0)
	var off_map := targeting.validate_target(source, MapActionTarget.new(target.grid_position, target), context)
	_expect(off_map.is_success() and not off_map.value, "An in-range coordinate missing from the map must be invalid.")
	target.grid_position = Vector2i(3, 0)
	var out_of_range := targeting.validate_target(source, MapActionTarget.new(target.grid_position, target), context)
	_expect(out_of_range.is_success() and not out_of_range.value, "A unit beyond maximum axial range must be invalid.")
	source.free()
	target.free()

func _test_automatic_resolution_always_hits() -> void:
	var definition = _ability_definition(AutomaticResolutionScript.new())
	definition.base_power = 17.0
	var source := _entity("Source", Vector2i.ZERO)
	var target := _entity("Target", Vector2i(1, 0))
	var action_target := MapActionTarget.new(target.grid_position, target)
	var result: ActionResult = definition.resolution.resolve(definition, source, action_target, GameContext.new())
	_expect(result.is_success(), "Automatic resolution must resolve without random services.")
	if result.is_success():
		var outcomes: Array = result.value
		_expect(outcomes.size() == 1 and outcomes[0].is_successful, "Automatic resolution must produce one successful outcome.")
		_expect(outcomes[0].magnitude == 17.0, "Automatic resolution must carry definition base power into its outcome.")
	source.free()
	target.free()

func _test_accuracy_resolution_requires_stats_and_randomness() -> void:
	var resolution = AccuracyResolutionScript.new()
	resolution.accuracy_stat_id = &"accuracy"
	resolution.evasion_stat_id = &"evasion"
	resolution.base_hit_chance = 0.5
	resolution.stat_difference_factor = 0.01
	resolution.minimum_hit_chance = 0.0
	resolution.maximum_hit_chance = 1.0
	var definition = _ability_definition(resolution)
	var source := _entity_with_stats("Source", Vector2i.ZERO, {&"accuracy": 100.0})
	var target := _entity_with_stats("Target", Vector2i(1, 0), {&"evasion": 0.0})
	var action_target := MapActionTarget.new(target.grid_position, target)
	var missing_random := resolution.resolve(definition, source, action_target, GameContext.new())
	_expect(not missing_random.is_success(), "Probabilistic resolution must reject a missing random source.")
	var hit_context := GameContext.new(null, null, SeededRandomSourceScript.new(7))
	var hit_result := resolution.resolve(definition, source, action_target, hit_context)
	_expect(hit_result.is_success() and hit_result.value[0].is_successful, "Explicit high accuracy must resolve as a hit.")
	var target_without_stats := _entity("NoStats", Vector2i(1, 0))
	var missing_stats := resolution.resolve(definition, source, MapActionTarget.new(target_without_stats.grid_position, target_without_stats), hit_context)
	_expect(not missing_stats.is_success(), "Accuracy resolution must reject targets without the configured stats.")
	source.free()
	target.free()
	target_without_stats.free()

func _ability_definition(resolution) -> AbilityDefinition:
	var definition = AbilityDefinitionScript.new()
	definition.ability_id = &"test_attack"
	definition.display_name = "Test Attack"
	definition.icon = preload("res://assets/ui/action-attack.svg")
	definition.targeting = AbilityTargetingScript.new()
	definition.targeting.target_kind = AbilityTargetingScript.TargetKind.UNIT
	definition.targeting.minimum_range = 1
	definition.targeting.maximum_range = 3
	definition.base_power = 10.0
	definition.resolution = resolution
	var effects: Array[OutcomeEffect] = [DamageOutcomeEffectScript.new()]
	definition.outcome_effects = effects
	return definition

func _entity(entity_name: String, position: Vector2i) -> GameEntity:
	var entity := GameEntity.new()
	entity.name = entity_name
	entity.grid_position = position
	return entity

func _entity_with_stats(entity_name: String, position: Vector2i, values: Dictionary) -> GameEntity:
	var entity := _entity(entity_name, position)
	var stats := StatsComponent.new()
	entity.add_child(stats)
	entity.register_component(stats)
	stats.configure(values)
	return entity

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("ABILITY FOUNDATION TESTS PASSED")
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
