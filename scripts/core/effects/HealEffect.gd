class_name HealEffect
extends Effect

## Heals the target's HealthComponent.

@export var amount: int = 10

func apply(context: GameContext, source: Node, target: Node) -> void:
	var health_comp: HealthComponent
	
	for child in target.get_children():
		if child is HealthComponent:
			health_comp = child
			break
			
	if health_comp:
		health_comp.heal(amount)
		print("Effect: %s healed %s for %d" % [source.name, target.name, amount])
	else:
		print("Effect: Target %s has no HealthComponent" % target.name)
