extends Node

const MovementComponent = preload("res://scripts/components/MovementComponent.gd")
const AttackComponent = preload("res://scripts/components/AttackComponent.gd")
const HealthComponent = preload("res://scripts/components/HealthComponent.gd")
const GameContext = preload("res://scripts/core/GameContext.gd")

func _ready() -> void:
	print("Starting Verification...")
	
	# Instantiate TestLevel
	var test_level_res = load("res://scenes/TestLevel.tscn")
	if not test_level_res:
		print("ERROR: TestLevel.tscn not found.")
		return
		
	var test_level = test_level_res.instantiate()
	add_child(test_level)
	
	print("TestLevel Tree:")
	test_level.print_tree_pretty()
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	
	var soldier = test_level.get_node("Soldier")
	var tank = test_level.get_node("Tank")
	var map_service = test_level.get_node("MapService")
	
	if not soldier or not tank:
		print("ERROR: Units not found in TestLevel.")
		return

	print("Soldier found at %s" % soldier.global_position)
	print("Tank found at %s" % tank.global_position)
	
	# --- Test Movement ---
	print("\n[TEST] Soldier Movement")
	var move_comp = soldier.get_component(MovementComponent)
	if not move_comp:
		print("ERROR: Soldier missing MovementComponent")
		return
		
	var target_pos = Vector2i(3, 0) # Close to tank at 4,0
	move_comp.move_to(target_pos)
	
	await get_tree().process_frame
	
	if soldier.grid_position != target_pos:
		print("FAILURE: Soldier grid_position is %s, expected %s" % [soldier.grid_position, target_pos])
	else:
		print("SUCCESS: Soldier moved to %s" % target_pos)

	# --- Test Attack ---
	print("\n[TEST] Soldier Attack")
	var attack_comp = soldier.get_component(AttackComponent)
	var tank_health = tank.get_component(HealthComponent)
	
	if not attack_comp or not tank_health:
		print("ERROR: Missing Attack or Health components")
		return
	
	var start_hp = tank_health.current_hp
	print("Tank Start HP: %d" % start_hp)
	
	var cmd = attack_comp.create_attack_command(tank)
	var context = GameContext.new(map_service)
	
	cmd.execute(context)
	
	var new_hp = tank_health.current_hp
	print("Tank HP after 1 attack: %d" % new_hp)
	
	if new_hp >= start_hp:
		print("FAILURE: Tank did not take damage.")
	else:
		print("SUCCESS: Tank took damage (%d -> %d)" % [start_hp, new_hp])
		
	# --- Test Kill ---
	print("\n[TEST] Kill Tank")
	var attacks = 0
	while tank_health.is_alive() and attacks < 100:
		cmd.execute(context)
		attacks += 1
	
	if not tank_health.is_alive():
		print("SUCCESS: Tank destroyed after %d more attacks." % attacks)
	else:
		print("FAILURE: Tank is still alive after %d attacks." % attacks)
		
	print("\nVerification Scenario Complete.")
	get_tree().quit()
