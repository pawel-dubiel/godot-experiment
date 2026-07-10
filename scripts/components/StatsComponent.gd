class_name StatsComponent
extends EntityComponent

@export var base_stats: Dictionary = {}

var stat_block := StatBlock.new()
var _configured := false

func _ready() -> void:
	if _configured:
		return
	var result := configure(base_stats)
	if not result.is_success():
		push_error(result.error)

func configure(values: Dictionary) -> ActionResult:
	var configured_block := StatBlock.new()
	for stat_key in values:
		if not stat_key is StringName and not stat_key is String:
			return ActionResult.failure("StatsComponent base stat keys must be StringName or String.")
		var raw_value = values[stat_key]
		if typeof(raw_value) != TYPE_INT and typeof(raw_value) != TYPE_FLOAT:
			return ActionResult.failure("StatsComponent base stat '%s' must be numeric." % stat_key)
		var result := configured_block.set_base_value(StringName(stat_key), float(raw_value))
		if not result.is_success():
			return result
	stat_block = configured_block
	_configured = true
	return ActionResult.success(true)

func stat_value(stat_id: StringName) -> ActionResult:
	if not _configured:
		return ActionResult.failure("StatsComponent must be configured before reading stats.")
	return stat_block.value(stat_id)
