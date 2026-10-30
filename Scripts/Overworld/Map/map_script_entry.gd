@tool
extends Resource
class_name MapScriptEntry

enum Trigger {
	ON_TRANSITION,
	ON_LOAD,
	ON_FRAME,
}

@export var trigger: Trigger = Trigger.ON_LOAD
@export_file("*.txt") var script_file: String = ""
## Nombre del enum GameFlags.Id (ej. INTRO_DONE). Vacío = siempre.
@export var condition_flag: String = ""
@export var expected_value: bool = true


func condition_matches() -> bool:
	if condition_flag.strip_edges().is_empty():
		return true
	var id: GameFlags.Id = GameFlags.from_token(condition_flag)
	var valor: bool = bool(ScriptExecutionContext.global_flags.get(int(id), false))
	return valor == expected_value
