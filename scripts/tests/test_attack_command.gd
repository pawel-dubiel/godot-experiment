extends SceneTree

func _init():
	print("Running Attack Command Test")
	
	# Load script classes manually
	var MapServiceInfo = load("res://scripts/systems/MapService.gd")
	var AttackCommandInfo = load("res://scripts/core/commands/AttackCommand.gd")
	var HealthComponentInfo = load("res://scripts/components/HealthComponent.gd")
	var GameContextInfo = load("res://scripts/core/GameContext.gd")
	
	if not MapServiceInfo or not AttackCommandInfo:
		print("Error: Could not load script classes.")
		quit()
		return

	# 1. Setup Mock Environment
	var map_service = MapServiceInfo.new()
	var context = GameContextInfo.new(map_service, null)
	
	# 2. Setup Units (Mocked as Nodes with properties)
	var attacker = Node.new()
	attacker.name = "Attacker"
	# Manually adding grid_position property since our Requirement expects it
	attacker.set_meta("grid_position", Vector2i(0, 0))
	# Adding a script to allow get("grid_position") to work if it wasn't meta
	# But for now, let's fix RangeRequirement to use get_meta or just a standard property.
	# The Requirement used source.get("grid_position"). In Godot, get() works on properties.
	# So we need a script with that property.
	var unit_script = GDScript.new()
	unit_script.source_code = "extends Node\nvar grid_position: Vector2i = Vector2i(0,0)"
	unit_script.reload()
	attacker.set_script(unit_script)
	
	var target = Node.new()
	target.name = "Target"
	target.set_script(unit_script)
	target.grid_position = Vector2i(1, 0) # Distance 1
	
	# Add Health to Target
	var health = HealthComponentInfo.new()
	target.add_child(health)
	# We need to simulate _ready or set values manually
	health.max_hp = 100
	health.current_hp = 100
	
	root.add_child(attacker)
	root.add_child(target)
	
	# 3. Create Command (Attack 10 dmg, range 1)
	print("--- Creating Command ---")
	var cmd = AttackCommandInfo.new(attacker, target, 10, 1)
	
	# 4. Validate (Should pass, distance is 1)
	print("--- Validating (Expect Success) ---")
	if cmd.validate(context):
		print("Validation Passed!")
	else:
		print("Validation Failed!")
		
	# 5. Execute
	print("--- Executing ---")
	cmd.execute(context)
	
	print("Target HP: %d" % health.current_hp)
	
	# 6. Test Fail Condition (Out of Range)
	print("--- Testing Range Fail ---")
	target.grid_position = Vector2i(5, 0) # Distance 5
	if not cmd.validate(context):
		print("Validation Correctly Failed (Out of Range)")
	else:
		print("Error: Validation Passed but should have failed!")

	print("--- Test Complete ---")
	quit()
