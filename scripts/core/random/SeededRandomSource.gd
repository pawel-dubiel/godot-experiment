class_name SeededRandomSource
extends RandomSource

var _generator := RandomNumberGenerator.new()

func _init(seed_value: int) -> void:
	_generator.seed = seed_value

func next_float() -> ActionResult:
	return ActionResult.success(_generator.randf())
