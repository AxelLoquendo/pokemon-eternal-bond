extends Node2D
## Menú principal con tus sprites: Continuar / Nuevo_Juego / Opciones.

enum Option { CONTINUE, NEW_GAME, OPTIONS }

@onready var btn_continue: Sprite2D = $Botones/Continuar
@onready var btn_new: Sprite2D = $Botones/Nuevo_Juego
@onready var btn_options: Sprite2D = $Botones/Opciones

## Si tienes saves más adelante, cambia esto.
var has_save: bool = false

var _index: int = 0
var _options: Array[Option] = []
var _buttons: Array[Sprite2D] = []
var _busy: bool = true

## Tintes selección (ajusta a gusto).
const COL_SELECTED := Color(1.0, 1.0, 1.0, 1.0)
const COL_IDLE := Color(0.75, 0.75, 0.75, 1.0)
const COL_DISABLED := Color(0.45, 0.45, 0.45, 0.85)


func _ready() -> void:
	has_save = SaveService.has_save()
	_build_options()
	_refresh_visual()
	if typeof(FadeScreen) != TYPE_NIL and FadeScreen.has_method("fade_in"):
		await FadeScreen.fade_in(TitleConfig.FADE_DURATION)
	else:
		modulate.a = 1.0
	_busy = false


func _build_options() -> void:
	_options.clear()
	_buttons.clear()
	# Continuar solo si hay partida (por ahora false = se puede saltar o dejar gris).
	_options.append(Option.CONTINUE)
	_buttons.append(btn_continue)
	_options.append(Option.NEW_GAME)
	_buttons.append(btn_new)
	_options.append(Option.OPTIONS)
	_buttons.append(btn_options)

	_index = 0
	if not has_save:
		# Empieza en Nueva partida
		for i: int in _options.size():
			if _options[i] == Option.NEW_GAME:
				_index = i
				break


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	var vp: Node = get_viewport()
	if event.is_action_pressed("Up") or event.is_action_pressed("ui_up"):
		_move(-1)
		if vp:
			vp.set_input_as_handled()
	elif event.is_action_pressed("Down") or event.is_action_pressed("ui_down"):
		_move(1)
		if vp:
			vp.set_input_as_handled()
	elif event.is_action_pressed("Left") or event.is_action_pressed("ui_left"):
		_move(-1)
		if vp:
			vp.set_input_as_handled()
	elif event.is_action_pressed("Right") or event.is_action_pressed("ui_right"):
		_move(1)
		if vp:
			vp.set_input_as_handled()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		if vp:
			vp.set_input_as_handled()  # ANTES de _confirm (puede cambiar de escena)
		_confirm()


func _move(dir: int) -> void:
	var n: int = _options.size()
	if n == 0:
		return
	var next: int = _index
	for _i: int in n:
		next = (next + dir + n) % n
		if _options[next] == Option.CONTINUE and not has_save:
			continue
		_index = next
		_refresh_visual()
		return


func _refresh_visual() -> void:
	for i: int in _buttons.size():
		var spr: Sprite2D = _buttons[i]
		if spr == null:
			continue
		if _options[i] == Option.CONTINUE and not has_save:
			spr.modulate = COL_DISABLED
		elif i == _index:
			spr.modulate = COL_SELECTED
		else:
			spr.modulate = COL_IDLE


func _confirm() -> void:
	if _busy:
		return
	var opt: Option = _options[_index]
	if opt == Option.CONTINUE and not has_save:
		return
	_busy = true

	match opt:
		Option.CONTINUE:
			_on_continue()
		Option.NEW_GAME:
			_on_new_game()
		Option.OPTIONS:
			_on_options()


func _on_continue() -> void:
	var save: SaveData = SaveService.load_game()
	if save == null:
		_busy = false
		return
	SessionBoot.start_data = SaveService.to_start_data(save)
	SessionBoot.loaded_play_seconds = save.play_seconds
	get_tree().change_scene_to_file("res://Escenas/Overworld/Game/game_session.tscn")


func _on_new_game() -> void:
	NewGameState.reset()
	if typeof(FadeScreen) != TYPE_NIL and FadeScreen.has_method("fade_out"):
		await FadeScreen.fade_out(TitleConfig.FADE_DURATION)
	get_tree().change_scene_to_file(TitleConfig.GENDER_SCENE)


func _on_options() -> void:
	# TODO: escena de opciones
	push_warning("Opciones: aún no implementado.")
	_busy = false
