@tool
extends ScriptCommand
class_name ScriptCmdSpecials

@export var special_id: ScriptSpecials.Id = ScriptSpecials.Id.NONE
@export var silent: bool = false


func execute(context: ScriptExecutionContext) -> bool:
	match special_id:
		ScriptSpecials.Id.SAVE_GAME:
			return _save_game(context)
		ScriptSpecials.Id.HEAL_PARTY:
			return _heal_party(context)
		_:
			push_warning("specials: no implementado %s" % special_id)
			return true


func _save_game(context: ScriptExecutionContext) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return true
	var session: Node = tree.get_first_node_in_group(&"game_session")
	if session == null:
		session = tree.current_scene
	var ok: bool = SaveService.save_game(session)
	if silent:
		return true
	if ok:
		MusicManager.reproducir_efecto_musical(SFXGame.MusicEffectID.ME_GUI_SAVE_GAME)
		var n: String = NewGameState.player_name
		if n.is_empty():
			n = "Jugador"
		if not MessageService.message_finished.is_connected(context.complete_async):
			MessageService.message_finished.connect(context.complete_async, CONNECT_ONE_SHOT)
		MessageService.show_texts(["%s guardó la partida." % n])
		context.is_waiting = true
		return false
	if not MessageService.message_finished.is_connected(context.complete_async):
		MessageService.message_finished.connect(context.complete_async, CONNECT_ONE_SHOT)
	MessageService.show_texts(["No se pudo guardar la partida."])
	context.is_waiting = true
	return false


func _heal_party(_context: ScriptExecutionContext) -> bool:
	# Overworld-only por ahora: solo feedback
	push_warning("specials HEAL_PARTY: party aún no existe; no-op")
	return true


func get_display_text() -> String:
	return "specials %s" % ScriptSpecials.Id.keys()[special_id]
