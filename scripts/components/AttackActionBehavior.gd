class_name AttackActionBehavior
extends ActionBehavior

var _attack: AttackComponent

func _init(attack: AttackComponent) -> void:
	if not attack:
		push_error("AttackActionBehavior requires an AttackComponent.")
		return
	_attack = attack

func availability(_context: GameContext) -> ActionResult:
	return ActionResult.success(true)

func get_unavailable_reason(_context: GameContext) -> ActionResult:
	return ActionResult.success("")

func get_candidate_coordinates(_context: GameContext) -> ActionResult:
	return _attack.get_candidate_coordinates()

func matches_context(target: Variant, context: GameContext) -> ActionResult:
	return ActionResult.success(_attack.is_valid_action_target(target, context))

func validate_target(target: Variant, context: GameContext) -> ActionResult:
	return ActionResult.success(_attack.is_valid_action_target(target, context))

func create_command(target: Variant, _context: GameContext) -> ActionResult:
	if not target is MapActionTarget or not target.entity:
		return ActionResult.failure("Attack action requires a MapActionTarget containing an entity.")
	return ActionResult.success(_attack.create_attack_command(target.entity))
