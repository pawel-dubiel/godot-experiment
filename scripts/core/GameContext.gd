class_name GameContext
extends RefCounted

## Service Locator / Context object passed to Commands.
## Holds references to global systems (Map, Turns, etc) to avoid "God Objects" or global singletons.

var map_service: MapService
var turn_manager: TurnManager
# Add other services here as needed (e.g. FactionManager, FXManager)

func _init(p_map_service: MapService = null, p_turn_manager: TurnManager = null) -> void:
	map_service = p_map_service
	turn_manager = p_turn_manager
