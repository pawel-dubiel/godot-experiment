class_name MovementComponent
extends EntityComponent

## Manages movement range and grid positioning.

@export var move_range: int = 3
@export var movement_speed: float = 4.0 # For visual lerping (future)

signal movement_finished(final_pos: Vector2i)

## Teleport to a grid position immediately (Logical Move)
func move_to(new_position: Vector2i) -> void:
	var entity: GameEntity = get_entity()
	if entity:
		var old_position: Vector2i = entity.grid_position
		
		# Update logical position
		entity.grid_position = new_position
		
		# Update visual position (assuming MapService.grid_to_world is available via Context or we just set generic world pos)
		# For now, simplistic mapping: x, 0, y
		# In a real game, we'd look up the MapService Global or SceneTree to convert.
		entity.position = Vector3(new_position.x, 0, new_position.y) 
		
		entity.send_message("moved", { "from": old_position, "to": new_position })
		movement_finished.emit(new_position)
