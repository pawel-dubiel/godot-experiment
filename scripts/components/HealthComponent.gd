class_name HealthComponent
extends EntityComponent

## Manages Health Points (HP) and death state.

signal health_changed(new_hp: int, max_hp: int)
signal died()
signal healed(amount: int)
signal damaged(amount: int)

@export var max_hp: int = 100
@export var current_hp: int = 100

func _ready() -> void:
	current_hp = max_hp
	
	# Subscribe to messages if parent is a GameEntity
	var parent = get_parent()
	if parent is GameEntity:
		parent.subscribe("incoming_damage", _on_incoming_damage)
		parent.subscribe("healed", _on_healed)

## Message Handler for 'incoming_damage'
func _on_incoming_damage(data: Dictionary) -> void:
	if data.has("amount"):
		# In the future: Armor deduction would happen here (or via a modifier pattern)
		take_damage(data["amount"])

## Message Handler for 'healed'
func _on_healed(data: Dictionary) -> void:
	if data.has("amount"):
		heal(data["amount"])

## Apply damage to the unit.
func take_damage(amount: int) -> void:
	if current_hp <= 0: return
	
	amount = max(0, amount) # No negative damage
	current_hp -= amount
	damaged.emit(amount)
	health_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		current_hp = 0
		died.emit()
		print("%s died!" % get_entity().name)

## Heal the unit.
func heal(amount: int) -> void:
	if current_hp <= 0: return # Can't heal dead units (usually)
	
	amount = max(0, amount)
	current_hp += amount
	if current_hp > max_hp:
		current_hp = max_hp
		
	healed.emit(amount)
	health_changed.emit(current_hp, max_hp)

func is_alive() -> bool:
	return current_hp > 0
