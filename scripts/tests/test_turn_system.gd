extends SceneTree

func _init():
	print("Running Turn System Test")
	
	# Load script classes manually if needed, or rely on global class_name
	# Note: running with -s might not load global classes automatically depending on Godot version/settings.
	# It's safer to load them by path for this standalone test.
	
	var TurnManagerInfo = load("res://scripts/systems/turn_system/TurnManager.gd")
	var GamePhaseInfo = load("res://scripts/core/GamePhase.gd")
	
	if not TurnManagerInfo or not GamePhaseInfo:
		print("Error: Could not load script classes.")
		quit()
		return
		
	# 1. Setup TurnManager
	var turn_manager = TurnManagerInfo.new()
	root.add_child(turn_manager)
	
	# 2. Setup Dummy Phases
	var phases: Array = []
	
	var phase1 = GamePhaseInfo.new()
	phase1.phase_name = "Phase 1: Start"
	phases.append(phase1)
	
	var phase2 = GamePhaseInfo.new()
	phase2.phase_name = "Phase 2: Action"
	phases.append(phase2)
	
	var phase3 = GamePhaseInfo.new()
	phase3.phase_name = "Phase 3: End"
	phases.append(phase3)
	
	# Use append_array to avoid type mismatch on direct assignment of untyped array
	turn_manager.phases.clear()
	turn_manager.phases.append_array(phases)
	
	# 3. Connect signals
	turn_manager.phase_changed.connect(func(p): print("Signal: Phase Changed to ", p.phase_name))
	turn_manager.turn_ended.connect(func(t): print("Signal: Turn Ended ", t))
	
	# 4. Run Test
	print("--- Starting Turn Manager ---")
	turn_manager._ready() # Should start Phase 1
	
	print("--- Advancing to Phase 2 ---")
	turn_manager.advance_phase()
	
	print("--- Advancing to Phase 3 ---")
	turn_manager.advance_phase()
	
	print("--- Advancing (End Turn) ---")
	turn_manager.advance_phase() # Should loop back to Phase 1, Turn 2
	
	print("--- Test Complete ---")
	quit()
