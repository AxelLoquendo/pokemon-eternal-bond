class_name GameSession
extends Node2D

@export var start_data: GameStartData

@onready var player: Node2D = $Player
@onready var map_factory: MapFactory = $MapFactory

var play_seconds: float = 0.0
var _start_menu: CanvasLayer = null
var _signpost: CanvasLayer = null


func _ready() -> void:
	add_to_group(&"game_session")
	_ensure_message_ui()
	_ensure_signpost()

	if SessionBoot.start_data != null:
		start_data = SessionBoot.start_data
		SessionBoot.start_data = null

	play_seconds = SessionBoot.loaded_play_seconds
	SessionBoot.loaded_play_seconds = 0.0

	if start_data == null:
		push_error("GameSession: falta GameStartData")
		return
	if map_factory == null or player == null:
		push_error("GameSession: falta MapFactory o Player")
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
	if _start_menu and _start_menu.has_method("is_open") and _start_menu.is_open():
		return
	play_seconds += delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("buttonStart"):
		if MessageService and MessageService.has_method("is_active") and MessageService.is_active():
			return
		_ensure_start_menu()
		if _start_menu and _start_menu.has_method("is_open") and not _start_menu.is_open():
			_start_menu.open_menu(self)
			get_viewport().set_input_as_handled()


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
	if start_data.player_data != null:
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
	if _signpost and _signpost.has_method("try_show_for_map"):
		_signpost.try_show_for_map(mapa)


func _on_current_changed(mapa: Map) -> void:
	_apply_day_night(mapa)
	if _signpost and _signpost.has_method("try_show_for_map"):
		_signpost.try_show_for_map(mapa)


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
	var path: String = "res://Scripts/Core/Message/message_ui.gd"
	if not ResourceLoader.exists(path):
		return
	var ui: Node = (load(path) as Script).new()
	ui.name = "MessageUI"
	add_child(ui)


func _ensure_start_menu() -> void:
	if _start_menu != null:
		return
	var packed: PackedScene = load("res://Escenas/UI/Start_Menu/start_menu.tscn") as PackedScene
	if packed == null:
		return
	_start_menu = packed.instantiate() as CanvasLayer
	_start_menu.name = "StartMenu"
	add_child(_start_menu)


func _ensure_signpost() -> void:
	if _signpost != null:
		return
	var path: String = "res://Scripts/Core/UI/Location/location_signpost.gd"
	if not ResourceLoader.exists(path):
		return
	_signpost = (load(path) as Script).new() as CanvasLayer
	_signpost.name = "LocationSignpost"
	add_child(_signpost)
