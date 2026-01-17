extends RefCounted
class_name TileInstance

var coordinate: Vector2i
var terrain: TerrainType

func _init(coord: Vector2i, type: TerrainType):
	coordinate = coord
	terrain = type
