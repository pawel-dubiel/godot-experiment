class_name HealEffect
extends Effect

## Heals the target's HealthComponent.

@export var amount: int = 10

func apply(context: GameContext, source: Node, target: Node) -> void:
	var health_comp: HealthComponent
	
	# Optimization: Fast Lookup Only (Fail Fast)
	if target.has_method("get_component"):
		health_comp = target.get_component(HealthComponent)
	else:
		push_warning("HealEffect: Target '%s' is not a Unit (missing get_component). Optimization required." % target.name)
		return
			
	if health_comp:
		health_comp.heal(amount)
		print("Effect: %s healed %s for %d" % [source.name, target.name, amount])
	else:
		print("Effect: Target %s has no HealthComponent" % target.name)
