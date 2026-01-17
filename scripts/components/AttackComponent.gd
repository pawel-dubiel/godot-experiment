class_name AttackComponent
extends UnitComponent

## Component that enables a unit to attack.
## Acts as a CommandProvider.

@export var attack_damage: int = 10
@export var attack_range: int = 1

## Returns a list of available commands for this unit.
## In a full UI implementation, the UI would call this when the unit is selected.
func get_available_commands(context: GameContext) -> Array[Command]:
	var commands: Array[Command] = []
	
	# Logic to find targets would usually happen in the UI (User clicks target),
	# so here we might just return a "prototype" command or nothing if no targets are valid.
	# But for AI or context-menus, we might want to return valid AttackCommands.
	
	# For this architecture, let's assume the UI drives target selection, 
	# so this component is mostly a data container for Damage/Range 
	# and a factory for AttackCommands.
	
	return commands

## Factory method to create an attack command against a specific target
func create_attack_command(target: Node) -> AttackCommand:
	var cmd = AttackCommand.new(get_unit(), target, attack_damage, attack_range)
	return cmd
