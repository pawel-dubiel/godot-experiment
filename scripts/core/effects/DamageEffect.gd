class_name DamageEffect
extends Effect

## Applies damage to the target's HealthComponent.

@export var amount: int = 10

func apply(context: GameContext, source: Node, target: Node) -> void:
	# Optimization: Fast Lookup Only (Fail Fast)
	if target is GameEntity:
		target.send_message("incoming_damage", { "amount": amount, "source": source })
		print("Effect: %s sent 'incoming_damage' (%d) to %s" % [source.name, amount, target.name])
	else:
		push_warning("DamageEffect: Target '%s' is not a GameEntity (missing send_message). Optimization required." % target.name)
		return
