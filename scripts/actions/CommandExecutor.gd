class_name CommandExecutor
extends Node

func execute(command: Command, context: GameContext) -> bool:
	if not command:
		push_error("CommandExecutor requires a Command.")
		return false
	if not context:
		push_error("CommandExecutor requires a GameContext.")
		return false
	if not command.validate(context):
		return false

	var outcome := {"executed": false, "failed": false}
	command.executed.connect(func(): outcome.executed = true, CONNECT_ONE_SHOT)
	command.failed.connect(func(_reason: String): outcome.failed = true, CONNECT_ONE_SHOT)
	command.execute(context)
	return outcome.executed and not outcome.failed
