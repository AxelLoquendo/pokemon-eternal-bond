extends CanvasLayer
## Start menu en grid 2×3 (escena actual).

signal closed

enum Option {
	POKEDEX,
	POKEMON,
	BAG,
	PROFILE,
	SAVE,
	OPTIONS,
}

const COLS: int = 2
const COL_ON: Color = Color(1, 1, 1, 1)
const COL_OFF: Color = Color(0.65, 0.65, 0.65, 1)

@onready var grid: GridContainer = $Control/GridContainer

var _buttons: Array[TextureRect] = []
var _index: int = 0
var _busy: bool = false
var _session: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_buttons = [
		grid.get_node("Pokedex") as TextureRect,
		grid.get_node("Pokemon") as TextureRect,
		grid.get_node("Mochila") as TextureRect,
		grid.get_node("Perfil") as TextureRect,
		grid.get_node("Guardar") as TextureRect,
		grid.get_node("Opciones") as TextureRect,
	]
	_refresh()

func is_open() -> bool:
	return visible

func open_menu(session: Node = null) -> void:
	_session = session
	_index = 0
	_busy = false
	visible = true
	_lock_player(true)   # NO get_tree().paused = true
	_refresh()
	_se(SFXGame.SoundEffectID.SE_GUI_MENU_OPEN)

func close_menu() -> void:
	if visible:
		_se(SFXGame.SoundEffectID.SE_GUI_MENU_CLOSE)
	visible = false
	_lock_player(false)
	_session = null
	closed.emit()

func _lock_player(locked: bool) -> void:
	var p: Node = get_tree().get_first_node_in_group(&"Player")
	if p == null:
		return
	if p.has_method("set_script_locked"):
		p.call("set_script_locked", locked)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _busy:
		return

	if event.is_action_pressed("buttonStart") or event.is_action_pressed("buttonB") \
			or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_se(SFXGame.SoundEffectID.SE_GUI_SEL_CANCEL)
		close_menu()
		return

	if event.is_action_pressed("Left") or event.is_action_pressed("ui_left"):
		_move_h(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Right") or event.is_action_pressed("ui_right"):
		_move_h(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Up") or event.is_action_pressed("ui_up"):
		_move_v(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Down") or event.is_action_pressed("ui_down"):
		_move_v(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirm()


func _move_h(dir: int) -> void:
	var col: int = _index % COLS
	var row: int = _index / COLS
	col = (col + dir + COLS) % COLS
	_index = row * COLS + col
	_index = clampi(_index, 0, _buttons.size() - 1)
	_refresh()
	_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)


func _move_v(dir: int) -> void:
	var n: int = _buttons.size()
	var rows: int = (n + COLS - 1) / COLS
	var col: int = _index % COLS
	var row: int = _index / COLS
	row = (row + dir + rows) % rows
	var next: int = row * COLS + col
	if next >= n:
		next = n - 1
	_index = next
	_refresh()
	_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)


func _refresh() -> void:
	for i: int in _buttons.size():
		var btn: TextureRect = _buttons[i]
		if btn == null:
			continue
		btn.modulate = COL_ON if i == _index else COL_OFF


func _confirm() -> void:
	match _index as Option:
		Option.POKEDEX, Option.POKEMON, Option.BAG, Option.PROFILE, Option.OPTIONS:
			_se(SFXGame.SoundEffectID.SE_GUI_SEL_BUZZER)
			_stub(["Pokédex", "Pokémon", "Mochila", "Perfil", "", "Opciones"][_index])
		Option.SAVE:
			_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
			await _save_flow()


func _stub(label: String) -> void:
	push_warning("StartMenu: %s aún no implementado" % label)


func _save_flow() -> void:
	_busy = true
	visible = false

	MessageService.show_texts(
		["¿Quieres guardar la partida?"],
		"",
		["SÍ", "NO"]
	)
	await MessageService.message_finished
	if MessageService.get_last_choice() != 0:
		_se(SFXGame.SoundEffectID.SE_GUI_SEL_CANCEL)
		_busy = false
		visible = true
		_refresh()
		return

	if SaveService.has_save():
		MessageService.show_texts(
			["Ya hay una partida guardada.\n¿Quieres sobrescribirla?"],
			"",
			["SÍ", "NO"]
		)
		await MessageService.message_finished
		if MessageService.get_last_choice() != 0:
			_se(SFXGame.SoundEffectID.SE_GUI_SEL_CANCEL)
			_busy = false
			visible = true
			_refresh()
			return

	var session: Node = _session
	if session == null:
		session = get_tree().get_first_node_in_group(&"game_session")
	if session == null:
		session = get_tree().current_scene

	var ok: bool = SaveService.save_game(session)
	if ok:
		MusicManager.reproducir_efecto_musical(SFXGame.MusicEffectID.ME_GUI_SAVE_GAME)
		var n: String = NewGameState.player_name
		if n.is_empty():
			n = "Jugador"
		MessageService.show_texts(["%s guardó la partida." % n])
	else:
		MessageService.show_texts(["No se pudo guardar la partida."])
	await MessageService.message_finished

	_busy = false
	visible = true
	_refresh()


func _se(id: SFXGame.SoundEffectID) -> void:
	if MusicManager and MusicManager.has_method("reproducir_se"):
		MusicManager.reproducir_se(id)
