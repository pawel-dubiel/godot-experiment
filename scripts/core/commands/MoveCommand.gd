class_name MoveCommand
extends Command

var destination: Vector2i
var movement_component: MovementComponent

func _init(p_source: GameEntity, p_destination: Vector2i, p_movement_component: MovementComponent) -> void:
	super(p_source, null)
	destination = p_destination
	movement_component = p_movement_component

func validate(_context: GameContext) -> bool:
	if not source is GameEntity:
		push_error("MoveCommand requires a GameEntity source.")
		return false
	if not movement_component:
		push_error("MoveCommand requires a MovementComponent.")
		return false
	if movement_component.get_entity() != source:
		push_error("MoveCommand MovementComponent must belong to its source entity.")
		return false
	return movement_component.can_move_to(destination) and movement_component.is_within_move_range(destination, _context)

func execute(context: GameContext) -> void:
	if not validate(context):
		failed.emit("Movement validation failed")
		return
	movement_component.move_to(destination)
	executed.emit()
