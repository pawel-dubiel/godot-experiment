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
		
		# Visual Update
		var tile_map = get_tree().get_first_node_in_group("grid_view") as TileMapLayer
		if tile_map:
			var local_pos = tile_map.map_to_local(new_position)
			
			# Calculate Orientation
			var prev_world_pos = entity.position
			var diff = local_pos - prev_world_pos
			if diff.length_squared() > 0.1:
				var angle = diff.angle() # Radians, -PI to PI. 0 is Right.
				var deg = rad_to_deg(angle)
				# Snap to nearest 60 degrees.
				# 0 -> 0, 60 -> 1, 120 -> 2...
				# deg can be negative (e.g. -60 is Top Right -> 5)
				if deg < 0: deg += 360
				
				var orient_index = int(round(deg / 60.0)) % 6
				entity.orientation = orient_index
			
			entity.position = local_pos
		else:
			# Fallback if no map view found (e.g. headless test without scene tree fully ready? or just logic test)
			# Stick to grid coords for debug
			entity.position = Vector2(new_position.x * 64, new_position.y * 64)

		entity.send_message("moved", { "from": old_position, "to": new_position })
		movement_finished.emit(new_position)
