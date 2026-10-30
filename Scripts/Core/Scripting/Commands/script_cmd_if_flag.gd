@tool
extends ScriptCommand
class_name ScriptCmdIfFlag
## ifflag FLAG_NAME [== true|false] label

@export var flag_id: GameFlags.Id = GameFlags.Id.NONE
@export var expected: bool = true
@export var target_label: String = ""


func execute(context: ScriptExecutionContext) -> bool:
	var actual: bool = context.get_flag(flag_id, false)
	if actual == expected and context.runner != null:
		context.runner.jump_to_label(target_label)
	return true
