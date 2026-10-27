class_name GameSession
extends Node2D
## Player + MapFactory (estilo Studio, sin party/pause).

@export var start_data: GameStartData

@onready var player: Node2D = $Player
@onready var map_factory: MapFactory = $MapFactory

var play_seconds: float = 0.0


func _ready() -> void:
	add_to_group(&"game_session")
	_ensure_message_ui()

	if SessionBoot.start_data != null:
		start_data = SessionBoot.start_data
		SessionBoot.start_data = null

	play_seconds = SessionBoot.loaded_play_seconds
	SessionBoot.loaded_play_seconds = 0.0

	if start_data == null:
		push_error("GameSession: falta GameStartData")
		return
	if map_factory == null:
		push_error("GameSession: falta nodo MapFactory")
		return
	if player == null:
		push_error("GameSession: falta nodo Player")
		return

	_apply_player_data()

	if not map_factory.cluster_loaded.is_connected(_on_cluster_loaded):
		map_factory.cluster_loaded.connect(_on_cluster_loaded)
	if not map_factory.current_changed.is_connected(_on_current_changed):
		map_factory.current_changed.connect(_on_current_changed)

	map_factory.load_cluster(
		start_data.start_map_id,
		start_data.start_position,
		player
	)

	var controller: CharacterController = _player_controller()
	if controller != null and not controller.movement_finished.is_connected(_on_player_step_finished):
		controller.movement_finished.connect(_on_player_step_finished)

	if FadeScreen and FadeScreen.has_method("is_covered") and FadeScreen.is_covered():
		await FadeScreen.fade_in(0.4)
	elif FadeScreen and FadeScreen.has_method("fade_in"):
		await FadeScreen.fade_in(0.4)


func _process(delta: float) -> void:
	if MessageService and MessageService.has_method("is_active") and MessageService.is_active():
		return
	play_seconds += delta


func _player_controller() -> CharacterController:
	if player == null:
		return null
	var c: CharacterController = player.get_node_or_null("Controller/CharacterController") as CharacterController
	if c != null:
		return c
	return player.get_node_or_null("CharacterController") as CharacterController


func _apply_player_data() -> void:
	if player == null or start_data == null:
		return
	if start_data.player_data != null and player.get("character") != null:
		player.set("character", start_data.player_data)
	if NewGameState and player.has_method("_apply_ow_texture"):
		var path: String = NewGameState.ow_texture_path()
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex:
				player.call("_apply_ow_texture", tex)


func _on_player_step_finished() -> void:
	map_factory.update_current_from_player(player)
	MapEventResolver.try_step(player, map_factory)


func _on_cluster_loaded(mapa: Map) -> void:
	_apply_day_night(mapa)


func _on_current_changed(mapa: Map) -> void:
	_apply_day_night(mapa)


func _apply_day_night(mapa: Map) -> void:
	if not DayNightManager:
		return
	if mapa == null or mapa.attributes == null:
		DayNightManager.set_outdoor(true)
		return
	DayNightManager.set_outdoor(not mapa.attributes.is_indoor)


func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	var script_path: String = "res://Scripts/Core/Message/message_ui.gd"
	if not ResourceLoader.exists(script_path):
		return
	var ui: Node = (load(script_path) as Script).new()
	ui.name = "MessageUI"
	add_child(ui)
