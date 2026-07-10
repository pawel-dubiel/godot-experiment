class_name AbilityComponent
extends EntityComponent

@export var ability_definitions: Array[AbilityDefinition] = []

var _instances: Array[AbilityInstance] = []
var _instances_by_id: Dictionary = {}
var _configured := false
var _contract_error := ""

func _ready() -> void:
	if _configured:
		return
	var result := configure(ability_definitions)
	if not result.is_success():
		push_error(result.error)

func configure(definitions: Array[AbilityDefinition]) -> ActionResult:
	if definitions.is_empty():
		_contract_error = "AbilityComponent requires at least one AbilityDefinition."
		return ActionResult.failure(_contract_error)
	var configured_instances: Array[AbilityInstance] = []
	var configured_by_id: Dictionary = {}
	for definition in definitions:
		var instance_result := AbilityInstance.create(definition)
		if not instance_result.is_success():
			_contract_error = instance_result.error
			return instance_result
		if configured_by_id.has(definition.ability_id):
			_contract_error = "AbilityComponent contains duplicate ability ID '%s'." % definition.ability_id
			return ActionResult.failure(_contract_error)
		var instance: AbilityInstance = instance_result.value
		configured_instances.append(instance)
		configured_by_id[definition.ability_id] = instance
	ability_definitions.assign(definitions)
	_instances = configured_instances
	_instances_by_id = configured_by_id
	_configured = true
	_contract_error = ""
	return ActionResult.success(true)

func validate_action_provider_contract() -> String:
	if not _contract_error.is_empty():
		return _contract_error
	if not _configured:
		return "AbilityComponent has not been configured."
	return ""

func get_action_descriptors(_context: GameContext) -> Array[ActionDescriptor]:
	var descriptors: Array[ActionDescriptor] = []
	for instance in _instances:
		var definition := instance.definition
		descriptors.append(ActionDescriptor.new(
			definition.ability_id,
			definition.display_name,
			definition.icon,
			_targeting_mode(definition.targeting),
			AbilityActionBehavior.new(self, instance)
		))
	return descriptors

func get_ability_instance(ability_id: StringName) -> ActionResult:
	if not _configured:
		return ActionResult.failure("AbilityComponent must be configured before querying abilities.")
	if not _instances_by_id.has(ability_id):
		return ActionResult.failure("AbilityComponent does not contain ability '%s'." % ability_id)
	return ActionResult.success(_instances_by_id[ability_id])

func advance_turn() -> ActionResult:
	if not _configured:
		return ActionResult.failure("AbilityComponent must be configured before advancing cooldowns.")
	for instance in _instances:
		var result := instance.advance_turn()
		if not result.is_success():
			return result
	return ActionResult.success(true)

func _targeting_mode(targeting: AbilityTargeting) -> ActionDescriptor.TargetingMode:
	match targeting.target_kind:
		AbilityTargeting.TargetKind.UNIT, AbilityTargeting.TargetKind.SELF:
			return ActionDescriptor.TargetingMode.UNIT
		AbilityTargeting.TargetKind.EMPTY_HEX, AbilityTargeting.TargetKind.ANY_HEX:
			return ActionDescriptor.TargetingMode.HEX
		_:
			push_error("AbilityComponent encountered an unknown target kind.")
			return ActionDescriptor.TargetingMode.NONE
