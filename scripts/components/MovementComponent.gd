class_name MovementComponent
extends EntityComponent

## Manages movement range and grid positioning.

@export_range(0, 1000, 1) var move_range: int = 3
@export var movement_speed: float = 4.0 # For visual lerping (future)

signal movement_finished(final_pos: Vector2i)

var _move_validator: Callable

const MOVE_ICON := preload("res://assets/ui/action-move.svg")

func set_move_validator(validator: Callable) -> void:
	if not validator.is_valid():
		push_error("MovementComponent requires a valid move validator.")
		return
	_move_validator = validator

func get_action_descriptors(_context: GameContext) -> Array[ActionDescriptor]:
	var descriptor := ActionDescriptor.new(
		&"move",
		"Move",
		MOVE_ICON,
		ActionDescriptor.TargetingMode.HEX,
		MoveActionBehavior.new(self)
	)
	return [descriptor]

func has_move_validator() -> bool:
	return _move_validator.is_valid()

func get_candidate_coordinates() -> ActionResult:
	var entity := get_entity() as GameEntity
	if not entity:
		return ActionResult.failure("MovementComponent requires a GameEntity parent to enumerate candidates.")
	if move_range < 0:
		return ActionResult.failure("MovementComponent move_range must be non-negative.")
	return ActionResult.success(HexCoordinates.within_range(entity.grid_position, move_range))

func can_move_to(new_position: Vector2i) -> bool:
	var entity: GameEntity = get_entity() as GameEntity
	if not entity:
		push_error("MovementComponent requires a GameEntity parent.")
		return false
	if not _move_validator.is_valid():
		push_error("MovementComponent for %s requires an explicit move validator before validating movement." % entity.name)
		return false
	var validation_result = _move_validator.call(entity, new_position)
	if typeof(validation_result) != TYPE_BOOL:
		push_error("MovementComponent move validator for %s must return bool." % entity.name)
		return false
	return validation_result

func is_within_move_range(new_position: Vector2i, context: GameContext) -> bool:
	var entity := get_entity() as GameEntity
	if not entity:
		push_error("MovementComponent requires a GameEntity parent.")
		return false
	if not context or not context.map_service:
		push_error("MovementComponent requires GameContext.map_service for range validation.")
		return false
	return context.map_service.get_distance(entity.grid_position, new_position) <= move_range

func is_valid_action_target(target: Variant, context: GameContext) -> bool:
	return (
		target is MapActionTarget
		and not target.entity
		and can_move_to(target.grid_position)
		and is_within_move_range(target.grid_position, context)
	)

## Teleport to a grid position immediately (Logical Move)
func move_to(new_position: Vector2i) -> void:
	var entity: GameEntity = get_entity()
	if not entity:
		push_error("MovementComponent requires a GameEntity parent.")
		return

	if not can_move_to(new_position):
		return

	var old_position: Vector2i = entity.grid_position
	if not entity.move_to_grid_position(new_position):
		return

	entity.send_message("moved", { "from": old_position, "to": new_position })
	movement_finished.emit(new_position)
