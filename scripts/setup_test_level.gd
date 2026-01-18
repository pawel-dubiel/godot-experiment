extends SceneTree

func _init():
	print("Generating Test Level...")
	
	# Create Directory for Level
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("scenes"):
		dir.make_dir_recursive("scenes")
	
	create_test_level()
	
	print("Test Level Generation Complete.")
	quit()

func create_test_level():
	var root = Node3D.new()
	root.name = "TestLevel"
	
	# 1. Camera
	var cam_pivot = Node3D.new()
	cam_pivot.name = "CameraPivot"
	cam_pivot.position = Vector3(5, 0, 5) # Centered roughly
	root.add_child(cam_pivot)
	
	var cam = Camera3D.new()
	cam.name = "Camera3D"
	cam.position = Vector3(0, 10, 10)
	cam.rotation_degrees = Vector3(-45, 0, 0)
	cam_pivot.add_child(cam)
	
	# 2. Lighting
	var light = DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.rotation_degrees = Vector3(-60, -30, 0)
	light.shadow_enabled = true
	root.add_child(light)
	
	# 3. Floor (Visual)
	var floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var plane = PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	root.add_child(floor_mesh)
	
	# 4. Systems
	# MapService (Autoload usually, but adding here as node for simplicity unless configured otherwise)
	# Wait, MapService is not Autoload in this project yet? Check implementation.
	# Assuming we need a MapService Instance.
	var map_service_script = load("res://scripts/systems/MapService.gd")
	var map_service = map_service_script.new()
	map_service.name = "MapService"
	root.add_child(map_service)
	
	# 5. Units
	var soldier_scene = load("res://scenes/units/Soldier.tscn")
	var tank_scene = load("res://scenes/units/Tank.tscn")
	
	if soldier_scene and tank_scene:
		var soldier = soldier_scene.instantiate()
		soldier.name = "PlayerSoldier"
		soldier.grid_position = Vector2i(2, 2)
		soldier.position = Vector3(2, 0, 2)
		root.add_child(soldier)
		
		var tank = tank_scene.instantiate()
		tank.name = "EnemyTank"
		tank.grid_position = Vector2i(5, 2)
		tank.position = Vector3(5, 0, 2)
		root.add_child(tank)
	else:
		print("Error: Could not load unit scenes!")

	# 6. GameController (Input)
	# We will create this script next.
	# var controller_script = load("res://scripts/scenes/TestLevelController.gd")
	# root.set_script(controller_script) 
	
	save_scene(root, "res://scenes/TestLevel.tscn")

func save_scene(node: Node, path: String):
	var scene = PackedScene.new()
	# Recursively set owner for all children to root so they are packed
	set_owner_recursive(node, node)
	
	var result = scene.pack(node)
	if result == OK:
		var error = ResourceSaver.save(scene, path)
		if error == OK:
			print("Saved: " + path)
		else:
			print("Error saving " + path + ": " + str(error))
	else:
		print("Error packing scene " + path + ": " + str(result))

func set_owner_recursive(node: Node, new_owner: Node):
	if node != new_owner:
		node.owner = new_owner
	for child in node.get_children():
		set_owner_recursive(child, new_owner)
