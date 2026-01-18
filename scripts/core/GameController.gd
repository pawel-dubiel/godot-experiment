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
	# In 2D, screen_pos IS the world position relative to CanvasLayer (mostly).
	# But we want global position in world (accounting for camera).
	var global_mouse_pos = _get_global_mouse_pos()
	
	# Simple distance check for entities
	# In a real game, use Physics2D raycast or Area2D input_event.
	# For prototype, iterate "units" group or check distance.
	var best_candidate: GameEntity = null
	var min_dist = 25.0 # Tolerance
	
	for node in get_tree().get_nodes_in_group("units"):
		if node is GameEntity:
			var dist = node.global_position.distance_to(global_mouse_pos)
			if dist < min_dist:
				min_dist = dist
				best_candidate = node
	
	if best_candidate:
		current_selection = best_candidate
		print("Selected: %s" % best_candidate.name)
	else:
		current_selection = null
		print("Deselected")

func _handle_action(screen_pos: Vector2) -> void:
	if not current_selection:
		return
		
	var global_mouse_pos = _get_global_mouse_pos()
	
	# Check for attack target
	var target_entity: GameEntity = null
	var min_dist = 25.0
	for node in get_tree().get_nodes_in_group("units"):
		if node is GameEntity and node != current_selection:
			var dist = node.global_position.distance_to(global_mouse_pos)
			if dist < min_dist:
				min_dist = dist
				target_entity = node
	
	if target_entity:
		var attack_comp = current_selection.get_component(AttackComponent)
		if attack_comp:
			print("Attacking %s" % target_entity.name)
			var cmd = attack_comp.create_attack_command(target_entity)
			var context = GameContext.new(map_service)
			cmd.execute(context)
			return

	# Move
	if map_service and map_service.model:
		# We need to convert world pos to grid pos.
		# Ideally MapService or TileMap layer helps.
		# For now, let's assume we can get it from the TileMap if we can find it, 
		# or use a helper if we implement it.
		
		# HACK: If we don't have reference to TileMapLayer, we can't easily convert world->map.
		# Let's hope MapService has a helper or we search for the TileMap.
		var tile_map = get_tree().get_first_node_in_group("grid_view") as TileMapLayer
		if tile_map:
			var local_pos = tile_map.to_local(global_mouse_pos)
			var grid_pos = tile_map.local_to_map(local_pos)
			
			var move_comp = current_selection.get_component(MovementComponent)
			if move_comp:
				move_comp.move_to(grid_pos)
		else:
			print("Error: No TileMapLayer found in group 'grid_view'")

func _get_global_mouse_pos() -> Vector2:
	# Keep it simple for 2D
	return get_parent().get_global_mouse_position()



func _get_game_entity(node: Node) -> GameEntity:
	var current = node
	while current:
		if current is GameEntity:
			return current
		current = current.get_parent()
	return null
