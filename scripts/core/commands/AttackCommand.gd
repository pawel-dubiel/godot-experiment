class_name AttackCommand
extends Command

## Standard Command for attacking a target.
## This is a convenience class that pre-configures a standard attack.

func _init(p_source: Node, p_target: Node, damage: int = 10, range_val: int = 1) -> void:
	super._init(p_source, p_target)
	
	# Add standard Rules
	var range_req = RangeRequirement.new()
	range_req.max_range = range_val
	requirements.append(range_req)
	
	# Add standard Effects
	var dmg_effect = DamageEffect.new()
	dmg_effect.amount = damage
	effects.append(dmg_effect)
