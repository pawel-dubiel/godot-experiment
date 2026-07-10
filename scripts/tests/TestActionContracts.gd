extends SceneTree

const ActionDescriptorScript = preload("res://scripts/actions/ActionDescriptor.gd")
const ActionCatalogScript = preload("res://scripts/actions/ActionCatalog.gd")
const ContextualActionResolverScript = preload("res://scripts/actions/ContextualActionResolver.gd")
const CommandExecutorScript = preload("res://scripts/actions/CommandExecutor.gd")

class TestCommand extends Command:
	var validation_result := true
	var fail_during_execution := false
	var validation_count := 0
	var execution_count := 0

	func validate(_context: GameContext) -> bool:
		validation_count += 1
		return validation_result

	func execute(_context: GameContext) -> void:
		execution_count += 1
		if fail_during_execution:
			failed.emit("Execution failed")
		else:
			executed.emit()

class TestProvider extends Node:
	var descriptors: Array = []

	func get_action_descriptors(_context: GameContext) -> Array:
		return descriptors

class TestEntity extends GameEntity:
	var registered_components: Array[Node] = []

	func get_registered_components() -> Array[Node]:
		return registered_components

var _failures: Array[String] = []

func _initialize() -> void:
	_test_descriptor_contract()
	_test_catalog_rejects_duplicate_ids()
	_test_catalog_rejects_missing_disabled_reason()
	_test_contextual_resolution_is_unambiguous()
	_test_malformed_matcher_is_configuration_error()
	_test_executor_validates_before_execution()
	_test_executor_reports_command_failure()

	if _failures.is_empty():
		print("ACTION CONTRACT TESTS PASSED")
		quit(0)
		return

	for failure in _failures:
		printerr(failure)
	quit(1)

func _test_descriptor_contract() -> void:
	var descriptor = _descriptor(&"move", func(_target, _context): return true)
	_expect(descriptor.validate_contract().is_empty(), "A complete descriptor must satisfy its contract.")
	_expect(descriptor.is_available(null), "The descriptor must delegate availability.")
	_expect(descriptor.matches_context(Vector2i.ZERO, null), "The descriptor must delegate contextual matching.")

func _test_catalog_rejects_duplicate_ids() -> void:
	var provider := TestProvider.new()
	provider.descriptors = [
		_descriptor(&"move", func(_target, _context): return true),
		_descriptor(&"move", func(_target, _context): return false),
	]
	var entity := TestEntity.new()
	entity.registered_components = [provider]

	var result: Dictionary = ActionCatalogScript.new().collect(entity, null)
	_expect(result.status == &"error", "Duplicate action IDs must abort catalog collection.")
	_expect("move" in result.reason, "Duplicate-ID errors must identify the conflicting action ID.")

func _test_catalog_rejects_missing_disabled_reason() -> void:
	var provider := TestProvider.new()
	provider.descriptors = [ActionDescriptorScript.new(
		&"wait",
		"Wait",
		preload("res://icon.svg"),
		ActionDescriptorScript.TargetingMode.NONE,
		func(_context): return false,
		func(_context): return "",
		func(_target, _context): return false,
		func(_target, _context): return false,
		func(_target, _context): return TestCommand.new()
	)]
	var entity := TestEntity.new()
	entity.registered_components = [provider]
	var result: Dictionary = ActionCatalogScript.new().collect(entity, null)
	_expect(result.status == &"error", "Unavailable actions without a reason must abort catalog collection.")

func _test_contextual_resolution_is_unambiguous() -> void:
	var move = _descriptor(&"move", func(target, _context): return target is Vector2i)
	var attack = _descriptor(&"attack", func(target, _context): return target is Node)
	var resolver = ContextualActionResolverScript.new()

	var resolved: Dictionary = resolver.resolve([move, attack], Vector2i(2, 3), null)
	_expect(resolved.status == &"resolved" and resolved.action == move, "Exactly one contextual match must resolve.")

	var unavailable: Dictionary = resolver.resolve([move, attack], "invalid", null)
	_expect(unavailable.status == &"unavailable", "Zero contextual matches must be unavailable.")

	var conflicting_move = _descriptor(&"teleport", func(target, _context): return target is Vector2i)
	var conflict: Dictionary = resolver.resolve([move, conflicting_move], Vector2i.ZERO, null)
	_expect(conflict.status == &"error", "Multiple contextual matches must fail explicitly.")
	_expect("move" in conflict.reason and "teleport" in conflict.reason, "Conflict errors must identify every matching action ID.")

func _test_malformed_matcher_is_configuration_error() -> void:
	var malformed = _descriptor(&"broken", func(_target, _context): return "not a bool")
	var result: Dictionary = ContextualActionResolverScript.new().resolve([malformed], Vector2i.ZERO, null)
	_expect(result.status == &"error", "Malformed action-provider return types must resolve as configuration errors.")

func _test_executor_validates_before_execution() -> void:
	var executor = CommandExecutorScript.new()
	var context := GameContext.new()
	var valid_command := TestCommand.new()
	_expect(executor.execute(valid_command, context), "A valid command must execute.")
	_expect(valid_command.validation_count == 1, "The executor must validate immediately before execution.")
	_expect(valid_command.execution_count == 1, "A valid command must execute exactly once.")

	var invalid_command := TestCommand.new()
	invalid_command.validation_result = false
	_expect(not executor.execute(invalid_command, context), "An invalid command must be rejected.")
	_expect(invalid_command.execution_count == 0, "A rejected command must not execute.")

func _test_executor_reports_command_failure() -> void:
	var command := TestCommand.new()
	command.fail_during_execution = true
	var result: bool = CommandExecutorScript.new().execute(command, GameContext.new())
	_expect(not result, "CommandExecutor must return false when Command emits failed during execution.")

func _descriptor(id: StringName, contextual_matcher: Callable):
	return ActionDescriptorScript.new(
		id,
		String(id).capitalize(),
		preload("res://icon.svg"),
		ActionDescriptorScript.TargetingMode.HEX,
		func(_context): return true,
		func(_context): return "",
		contextual_matcher,
		func(_target, _context): return true,
		func(_target, _context): return TestCommand.new()
	)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
