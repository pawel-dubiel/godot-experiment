class_name GameController
extends Node

@export var map_service_path: NodePath
var map_service: MapService

var current_selection: GameEntity

func _ready() -> void:
	if map_service_path and has_node(map_service_path):
		map_service = get_node(map_service_path)
	
	print("GameController Ready. Click Unit to Select, Right Click to Move/Attack.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_select(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_action(event.position)

func _handle_select(screen_pos: Vector2) -> void:
	var result = _raycast_from_mouse(screen_pos)
	if result.has("collider"):
		var collider = result["collider"]
		var entity = _get_game_entity(collider)
		if entity:
			current_selection = entity
			print("Selected: %s" % entity.name)
		else:
			current_selection = null
			print("Deselected")

func _handle_action(screen_pos: Vector2) -> void:
	if not current_selection:
		return
		
	var result = _raycast_from_mouse(screen_pos)
	if result.has("position"):
		var world_pos = result["position"]
		var grid_pos = Vector2i(round(world_pos.x), round(world_pos.z))
		
		# Check if we clicked an entity (Attack)
		if result.has("collider"):
			var target_entity = _get_game_entity(result["collider"])
			if target_entity and target_entity != current_selection:
				var attack_comp = current_selection.get_component(AttackComponent)
				if attack_comp:
					print("Attacking %s" % target_entity.name)
					var cmd = attack_comp.create_attack_command(target_entity)
					# Create Context
					var context = GameContext.new(map_service)
					cmd.execute(context)
					return
		
		# Otherwise Move
		var move_comp = current_selection.get_component(MovementComponent)
		if move_comp:
			print("Moving to %s" % grid_pos)
			move_comp.move_to(grid_pos)

func _raycast_from_mouse(screen_pos: Vector2) -> Dictionary:
	var camera = get_viewport().get_camera_3d()
	if not camera: 
		return {}
		
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 1000
	var space = get_viewport().find_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	return space.intersect_ray(query)

func _get_game_entity(node: Node) -> GameEntity:
	var current = node
	while current:
		if current is GameEntity:
			return current
		current = current.get_parent()
	return null
