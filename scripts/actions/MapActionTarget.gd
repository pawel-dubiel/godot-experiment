class_name MapActionTarget
extends RefCounted

var grid_position: Vector2i
var entity: GameEntity

func _init(p_grid_position: Vector2i, p_entity: GameEntity) -> void:
	grid_position = p_grid_position
	entity = p_entity
