class_name DamageEffect
extends Effect

## Applies damage to the target's HealthComponent.

@export var amount: int = 10

func apply(context: GameContext, source: Node, target: Node) -> void:
	# Find HealthComponent on target
	var health_comp: HealthComponent
	
	# Optimization: Fast Lookup Only (Fail Fast)
	if target.has_method("get_component"):
		health_comp = target.get_component(HealthComponent)
	else:
		push_warning("DamageEffect: Target '%s' is not a Unit (missing get_component). Optimization required." % target.name)
		return
			
	if health_comp:
		health_comp.take_damage(amount)
		print("Effect: %s dealt %d damage to %s" % [source.name, amount, target.name])
	else:
		print("Effect: Target %s has no HealthComponent" % target.name)
