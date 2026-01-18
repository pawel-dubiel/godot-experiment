class_name HealEffect
extends Effect

## Heals the target's HealthComponent.

@export var amount: int = 10

func apply(context: GameContext, source: Node, target: Node) -> void:
	# Optimization: Fast Lookup Only (Fail Fast)
	if target is GameEntity:
		target.send_message("healed", { "amount": amount, "source": source })
		print("Effect: %s sent 'healed' (%d) to %s" % [source.name, amount, target.name])
	else:
		push_warning("HealEffect: Target '%s' is not a GameEntity (missing send_message). Optimization required." % target.name)
		return
