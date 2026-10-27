extends CanvasLayer
## Solo UI del menú de pausa. El guardado lo hace SaveService.

signal closed

enum Option {
	POKEDEX,
	POKEMON,
	BAG,
	PROFILE,
	SAVE,
	OPTIONS,
}

@onready var scroll: ScrollContainer = $Control/Container/ScrollContainer
@onready var vbox: VBoxContainer = $Control/Container/ScrollContainer/VBoxContainer

var _buttons: Array[TextureRect] = []
var _index: int = 0
var _busy: bool = false
var _session: Node = null

const COL_ON := Color(1, 1, 1, 1)
const COL_OFF := Color(0.65, 0.65, 0.65, 1)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_buttons = [
		vbox.get_node("Pokedex") as TextureRect,
		vbox.get_node("Pokemon") as TextureRect,
		vbox.get_node("Mochila") as TextureRect,
		vbox.get_node("Perfil") as TextureRect,
		vbox.get_node("Guardar") as TextureRect,
		vbox.get_node("Opciones") as TextureRect,
	]
	_refresh()


func is_open() -> bool:
	return visible


func open_menu(session: Node = null) -> void:
	_session = session
	_index = 0
	_busy = false
	visible = true
	get_tree().paused = true
	_refresh()


func close_menu() -> void:
	visible = false
	get_tree().paused = false
	_session = null
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _busy:
		return
	if event.is_action_pressed("buttonStart") or event.is_action_pressed("buttonB") \
			or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_menu()
		return
	if event.is_action_pressed("Up") or event.is_action_pressed("ui_up"):
		_move(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Down") or event.is_action_pressed("ui_down"):
		_move(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirm()


func _move(dir: int) -> void:
	var n: int = _buttons.size()
	if n == 0:
		return
	_index = (_index + dir + n) % n
	_refresh()
	_ensure_visible()


func _refresh() -> void:
	for i: int in _buttons.size():
		var btn: TextureRect = _buttons[i]
		if btn == null:
			continue
		btn.modulate = COL_ON if i == _index else COL_OFF


func _ensure_visible() -> void:
	if scroll == null or _index < 0 or _index >= _buttons.size():
		return
	var btn: TextureRect = _buttons[_index]
	if btn == null:
		return
	# Centrar el ítem en el viewport del scroll
	var btn_y: float = btn.position.y
	var btn_h: float = btn.size.y
	var view_h: float = scroll.size.y
	var target: float = btn_y - (view_h - btn_h) * 0.5
	scroll.scroll_vertical = int(maxi(0, target))


func _confirm() -> void:
	match _index as Option:
		Option.POKEDEX:
			_stub("Pokédex")
		Option.POKEMON:
			_stub("Pokémon")
		Option.BAG:
			_stub("Mochila")
		Option.PROFILE:
			_stub("Perfil")
		Option.SAVE:
			_do_save()
		Option.OPTIONS:
			_stub("Opciones")


func _stub(label: String) -> void:
	push_warning("StartMenu: %s aún no implementado" % label)


func _do_save() -> void:
	_busy = true
	var session: Node = _session
	if session == null:
		session = get_tree().get_first_node_in_group(&"game_session")
	if session == null:
		push_error("StartMenu: no hay GameSession")
		_busy = false
		return
	var ok: bool = SaveService.save_game(session)
	_busy = false
	if ok:
		close_menu()
		if MessageService:
			MessageService.show_text("¡Partida guardada!")
	else:
		if MessageService:
			MessageService.show_text("No se pudo guardar.")
