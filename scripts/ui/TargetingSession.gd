class_name TargetingSession
extends RefCounted

var descriptor: ActionDescriptor
var context: GameContext
var map_service: MapService
var tile_map: HexGridView
var target_provider: Callable

func _init(
	p_descriptor: ActionDescriptor,
	p_context: GameContext,
	p_map_service: MapService,
	p_tile_map: HexGridView,
	p_target_provider: Callable
) -> void:
	descriptor = p_descriptor
	context = p_context
	map_service = p_map_service
	tile_map = p_tile_map
	target_provider = p_target_provider

static func create(
	descriptor: ActionDescriptor,
	context: GameContext,
	map_service: MapService,
	tile_map: HexGridView,
	target_provider: Callable
) -> ActionResult:
	var missing: Array[String] = []
	if not descriptor:
		missing.append("descriptor")
	if not context:
		missing.append("context")
	if not map_service:
		missing.append("map_service")
	if not tile_map:
		missing.append("tile_map")
	if not target_provider.is_valid():
		missing.append("target_provider")
	if not missing.is_empty():
		return ActionResult.failure("TargetingSession requires: %s." % ", ".join(missing))
	return ActionResult.success(TargetingSession.new(descriptor, context, map_service, tile_map, target_provider))

func target_at(coordinate: Vector2i) -> ActionResult:
	var entity = target_provider.call(coordinate)
	if entity != null and not entity is GameEntity:
		return ActionResult.failure("TargetingSession target_provider must return GameEntity or null.")
	return ActionResult.success(MapActionTarget.new(coordinate, entity as GameEntity))
