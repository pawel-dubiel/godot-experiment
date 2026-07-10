class_name ResolvedOutcome
extends RefCounted

enum Kind {
	HIT,
	MISS,
}

var kind: Kind
var target: MapActionTarget
var magnitude: float
var is_successful: bool:
	get:
		return kind == Kind.HIT

func _init(p_kind: Kind, p_target: MapActionTarget, p_magnitude: float) -> void:
	kind = p_kind
	target = p_target
	magnitude = p_magnitude

static func hit(target: MapActionTarget, magnitude: float) -> ResolvedOutcome:
	return ResolvedOutcome.new(Kind.HIT, target, magnitude)

static func miss(target: MapActionTarget) -> ResolvedOutcome:
	return ResolvedOutcome.new(Kind.MISS, target, 0.0)
