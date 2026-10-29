@tool
extends ScriptCommand
class_name ScriptCmdText
## Muestra texto vía MessageService. Asíncrono.

@export_multiline var message: String = ""
@export var messages: Array[String] = []
@export var speaker_name: String = ""
@export var speaker_id: StringName = &""
@export var choices: Array[String] = []
@export var choice_variable: String = "last_choice"
@export var hide_speaker: bool = false


func execute(context: ScriptExecutionContext) -> bool:
	var pages: Array[String] = []
	for m: String in messages:
		if not m.is_empty():
			pages.append(MessageTextFormatter.expand(m, context))
	if pages.is_empty() and not message.is_empty():
		pages.append(MessageTextFormatter.expand(message, context))
	if pages.is_empty():
		return true

	var speaker: String = ""
	if hide_speaker:
		speaker = ""
	elif not speaker_name.strip_edges().is_empty():
		# Nombre explícito en el .txt o en el comando
		speaker = speaker_name.strip_edges()
	elif speaker_id != &"":
		var node: Node = context.find_character_by_id(speaker_id)
		speaker = _display_name(node)
	else:
		# Sin argumento → CharacterGame / NPCData del NPC del contexto
		speaker = _display_name(context.npc)

	if not MessageService.message_finished.is_connected(context.complete_async):
		MessageService.message_finished.connect(context.complete_async, CONNECT_ONE_SHOT)

	if not choices.is_empty():
		if not MessageService.choice_selected.is_connected(_on_choice.bind(context)):
			MessageService.choice_selected.connect(_on_choice.bind(context), CONNECT_ONE_SHOT)

	MessageService.show_texts(pages, speaker, choices)
	context.is_waiting = true
	return false

func _on_choice(index: int, context: ScriptExecutionContext) -> void:
	context.set_variable(choice_variable, str(index))


func _display_name(node: Node) -> String:
	if node == null:
		return ""
	# NPC / Player: resource CharacterGame / NPCData / PlayerData
	if "character" in node:
		var ch: Variant = node.get("character")
		if ch != null and ch is Resource and "name" in ch:
			var n: String = str(ch.get("name")).strip_edges()
			if not n.is_empty():
				return n
	if node.has_method("get_display_name"):
		var n2: String = str(node.call("get_display_name")).strip_edges()
		if not n2.is_empty():
			return n2
	# Compat por si algún nodo usa "data" en lugar de "character"
	if "data" in node:
		var data: Variant = node.get("data")
		if data != null and data is Resource and "name" in data:
			var n3: String = str(data.get("name")).strip_edges()
			if not n3.is_empty():
				return n3

	return ""


func get_display_text() -> String:
	var preview: String = message if not message.is_empty() else (messages[0] if not messages.is_empty() else "")
	if preview.length() > 28:
		preview = preview.substr(0, 28) + "..."
	return "text: %s" % preview
