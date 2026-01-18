extends SceneTree

func _init():
	print("Generating Content Prefabs...")
	
	# Create Directory for Units
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("scenes/units"):
		dir.make_dir_recursive("scenes/units")
	
	# Load scripts by path to avoid cache issues
	var AttackCompScript = load("res://scripts/components/AttackComponent.gd")
	var HealthCompScript = load("res://scripts/components/HealthComponent.gd")
	var MoveCompScript = load("res://scripts/components/MovementComponent.gd")
	var GameEntityScript = load("res://scripts/core/GameEntity.gd")
	
	create_soldier(GameEntityScript, HealthCompScript, AttackCompScript, MoveCompScript)
	create_tank(GameEntityScript, HealthCompScript, AttackCompScript, MoveCompScript)
	
	print("Content Generation Complete.")
	quit()

func create_soldier(EntityScript, HealthScript, AttackScript, MoveScript):
	var soldier = EntityScript.new()
	soldier.name = "Soldier"
	
	# 1. Health
	var health = HealthScript.new()
	health.name = "HealthComponent"
	health.max_hp = 50
	health.current_hp = 50
	soldier.add_child(health)
	health.owner = soldier # Important for packing
	
	# 2. Attack
	var attack = AttackScript.new()
	attack.name = "AttackComponent"
	attack.attack_damage = 10
	attack.attack_range = 1
	soldier.add_child(attack)
	attack.owner = soldier
	
	# 3. Movement
	var move = MoveScript.new()
	move.name = "MovementComponent"
	move.move_range = 3
	soldier.add_child(move)
	move.owner = soldier
	
	# 4. Visuals (Placeholder Mesh)
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Visuals"
	mesh_inst.mesh = CapsuleMesh.new()
	soldier.add_child(mesh_inst)
	mesh_inst.owner = soldier
	
	save_scene(soldier, "res://scenes/units/Soldier.tscn")

func create_tank(EntityScript, HealthScript, AttackScript, MoveScript):
	var tank = EntityScript.new()
	tank.name = "Tank"
	
	# 1. Health
	var health = HealthScript.new()
	health.name = "HealthComponent"
	health.max_hp = 200
	health.current_hp = 200
	tank.add_child(health)
	health.owner = tank
	
	# 2. Attack
	var attack = AttackScript.new()
	attack.name = "AttackComponent"
	attack.attack_damage = 50
	attack.attack_range = 3 # Can shoot further
	tank.add_child(attack)
	attack.owner = tank
	
	# 3. Movement
	var move = MoveScript.new()
	move.name = "MovementComponent"
	move.move_range = 2 # Slower
	tank.add_child(move)
	move.owner = tank
	
	# 4. Visuals (Placeholder Mesh)
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Visuals"
	var box = BoxMesh.new()
	box.size = Vector3(1.5, 1.5, 1.5)
	mesh_inst.mesh = box
	tank.add_child(mesh_inst)
	mesh_inst.owner = tank
	
	save_scene(tank, "res://scenes/units/Tank.tscn")

func save_scene(node: Node, path: String):
	var scene = PackedScene.new()
	var result = scene.pack(node)
	if result == OK:
		var error = ResourceSaver.save(scene, path)
		if error == OK:
			print("Saved: " + path)
		else:
			print("Error saving " + path + ": " + str(error))
	else:
		print("Error packing scene " + path + ": " + str(result))
