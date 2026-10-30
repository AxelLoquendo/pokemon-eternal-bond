@tool
extends ScriptCommand
class_name ScriptCmdSetFlag

@export var flag_id: GameFlags.Id = GameFlags.Id.NONE
@export var value: bool = true


func execute(context: ScriptExecutionContext) -> bool:
	context.set_flag(flag_id, value)
	return true


func get_display_text() -> String:
	return "%s %s" % ["setflag" if value else "clearflag", GameFlags.to_key(flag_id)]
