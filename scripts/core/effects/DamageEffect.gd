class_name DamageEffect
extends Effect

## Applies damage to the target's HealthComponent.

@export var amount: int = 10

func apply(context: GameContext, source: Node, target: Node) -> void:
	# Find HealthComponent on target
	# We search for a child node that is a HealthComponent
	var health_comp: HealthComponent
	
	for child in target.get_children():
		if child is HealthComponent:
			health_comp = child
			break
			
	if health_comp:
		health_comp.take_damage(amount)
		print("Effect: %s dealt %d damage to %s" % [source.name, amount, target.name])
	else:
		print("Effect: Target %s has no HealthComponent" % target.name)
