class_name GameSession
extends Node2D
## Raíz de partida: Player + mapa de inicio.

@export var start_data: GameStartData

@onready var player: Node2D = $Player
@onready var map_root: Node2D = $MapRoot

const TILE: float = 16.0
const GAME_START_SCENE: String = "res://Escenas/Overworld/Game/game_start.tscn"

var current_map: Node2D = null
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

	_apply_player_data()
	await _load_start_map()
	_place_player(start_data.start_position)
	_connect_player_step()

	if FadeScreen and FadeScreen.has_method("is_covered") and FadeScreen.is_covered():
		await FadeScreen.fade_in(0.4)
	elif FadeScreen and FadeScreen.has_method("fade_in"):
		await FadeScreen.fade_in(0.4)


func _process(delta: float) -> void:
	if MessageService and MessageService.has_method("is_active") and MessageService.is_active():
		return
	play_seconds += delta


func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	# Si tienes MessageUI como script instanciable:
	if ClassDB.class_exists("MessageUI") or ResourceLoader.exists("res://Scripts/Core/Message/message_ui.gd"):
		var ui_script: Script = load("res://Scripts/Core/Message/message_ui.gd") as Script
		if ui_script:
			var ui: Node = ui_script.new()
			ui.name = "MessageUI"
			add_child(ui)


func _apply_player_data() -> void:
	if player == null or start_data == null:
		return
	if start_data.player_data != null and "character" in player:
		player.character = start_data.player_data
	# Forzar OW Kael/Kaida según NewGameState (por si PlayerData aún no guarda sprite)
	var path: String = NewGameState.ow_texture_path()
	if player.has_method("_apply_ow_texture") and ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			player.call("_apply_ow_texture", tex)
	# O si el player expone animated_sprite + character.ow_sprite vía ObjectEvent, déjalo en PlayerData.


func _load_start_map() -> void:
	if map_root == null:
		map_root = Node2D.new()
		map_root.name = "MapRoot"
		add_child(map_root)
		move_child(map_root, 0)

	for c in map_root.get_children():
		c.queue_free()
	await get_tree().process_frame

	var path: String = MapSection.path_for(start_data.start_map_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("GameSession: mapa inválido %s" % path)
		return

	var packed: PackedScene = load(path) as PackedScene
	current_map = packed.instantiate() as Node2D
	map_root.add_child(current_map)


func _place_player(tile: Vector2i) -> void:
	if player == null:
		return
	# Si el mapa tiene un nodo EventObject / YSort, reparenta ahí
	var events: Node = null
	if current_map:
		events = current_map.get_node_or_null("EventObject")
		if events == null:
			events = current_map.get_node_or_null("Events")
	if events:
		player.reparent(events)
	player.global_position = Vector2(tile) * TILE
	var controller: Node = player.get_node_or_null("Controller/CharacterController")
	if controller and controller.has_method("teleport_to"):
		controller.call("teleport_to", player.global_position)


func _connect_player_step() -> void:
	var controller: Node = player.get_node_or_null("Controller/CharacterController")
	if controller == null:
		return
	if controller.has_signal("movement_finished"):
		if not controller.movement_finished.is_connected(_on_player_step_finished):
			controller.movement_finished.connect(_on_player_step_finished)


func _on_player_step_finished() -> void:
	# Cuando MapFactory / MapEventResolver estén listos:
	# map_factory.update_current_from_player(player)
	# MapEventResolver.try_step(player, map_factory)
	pass
