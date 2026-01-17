extends Resource
class_name TerrainType

@export var id: StringName
@export var display_name: String
@export var is_walkable: bool = true
@export var movement_cost: int = 1
@export var color: Color = Color.WHITE # For debug or tinting
@export var atlas_coords: Vector2i = Vector2i(0, 0)
