class_name MovementComponent
extends EntityComponent

## Manages movement range and grid positioning.

@export var move_range: int = 3
@export var movement_speed: float = 4.0 # For visual lerping (future)

signal movement_finished(final_pos: Vector2i)

var _move_validator: Callable

func set_move_validator(validator: Callable) -> void:
	if not validator.is_valid():
		push_error("MovementComponent requires a valid move validator.")
		return
	_move_validator = validator

## Teleport to a grid position immediately (Logical Move)
func move_to(new_position: Vector2i) -> void:
	var entity: GameEntity = get_entity()
	if not entity:
		push_error("MovementComponent requires a GameEntity parent.")
		return

	if not _move_validator.is_valid():
		push_error("MovementComponent for %s requires an explicit move validator before moving." % entity.name)
		return

	var validation_result = _move_validator.call(entity, new_position)
	if typeof(validation_result) != TYPE_BOOL:
		push_error("MovementComponent move validator for %s must return bool." % entity.name)
		return
	if not validation_result:
		return

	var old_position: Vector2i = entity.grid_position
	if not entity.move_to_grid_position(new_position):
		return

	entity.send_message("moved", { "from": old_position, "to": new_position })
	movement_finished.emit(new_position)
