class_name HealthComponent
extends UnitComponent

## Manages Health Points (HP) and death state.

signal health_changed(new_hp: int, max_hp: int)
signal died()
signal healed(amount: int)
signal damaged(amount: int)

@export var max_hp: int = 100
@export var current_hp: int = 100

func _ready() -> void:
	current_hp = max_hp

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
		print("%s died!" % get_unit().name)

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
