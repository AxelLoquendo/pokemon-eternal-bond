extends CanvasLayer
## Party menu estilo juegos principales.

signal closed

const PARTY_SCENE: String = "res://Escenas/UI/Party_Menu/party_menu.tscn"
const CANCEL_SENTINEL: int = 99

enum Mode {
	BROWSE,   # elegir mon / cancel
	ACTION,   # multichoice Summary/Cambiar/Item
	SWITCH,   # elegir destino del swap
	ITEM,     # submenú item (stub)
}

@onready var bg_anim: AnimationPlayer = $BG/BG_Lluvia
@onready var _text_lbl: Label = $Text_Box/Mon_Name if has_node("Text_Box/Mon_Name") else null
@onready var _cancel: Sprite2D = $Cancel if has_node("Cancel") else null

@onready var slots: Array[Node2D] = [
	$Party_Slot,
	$Party_Slot2,
	$Party_Slot3,
	$Party_Slot4,
	$Party_Slot5,
	$Party_Slot6,
]

var player_data: PlayerData = null
var _index: int = 0
var _mode: Mode = Mode.BROWSE
var _switch_from: int = -1
var _busy: bool = false
var _return_start: CanvasLayer = null
var _summary: CanvasLayer = null


static func open(tree: SceneTree, pd: PlayerData = null, return_start: CanvasLayer = null) -> CanvasLayer:
	var packed: PackedScene = load(PARTY_SCENE) as PackedScene
	if packed == null:
		return null
	var scn: CanvasLayer = packed.instantiate() as CanvasLayer
	scn.set("player_data", pd)
	scn.set("_return_start", return_start)
	tree.root.add_child(scn)
	return scn


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if bg_anim:
		bg_anim.play("Lluvia_BG")
	_warm()
	if player_data == null:
		player_data = BagService.ensure_player_data(get_tree())
	if player_data == null:
		player_data = PlayerData.new()
	_mode = Mode.BROWSE
	_switch_from = -1
	_bind_all()
	_set_index(0)
	_set_prompt("Elegir un Pokémon.")
	_se(SFXGame.SoundEffectID.SE_GUI_MENU_OPEN)


func _warm() -> void:
	if SpeciesCatalog and SpeciesCatalog.has_method("warm_index"):
		SpeciesCatalog.warm_index()
	if MoveCatalog and MoveCatalog.has_method("warm_index"):
		MoveCatalog.warm_index()
	if ItemCatalog and ItemCatalog.has_method("warm_index"):
		ItemCatalog.warm_index()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _busy or _summary != null:
		return
	if event.is_echo():
		return
	# Durante ACTION/ITEM el MessageService consume el input
	if _mode == Mode.ACTION or _mode == Mode.ITEM:
		return
	if event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancel_back()
		return
	if event.is_action_pressed("Left") or event.is_action_pressed("ui_left"):
		_move(-1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Right") or event.is_action_pressed("ui_right"):
		_move(1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Up") or event.is_action_pressed("ui_up"):
		_move(0, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Down") or event.is_action_pressed("ui_down"):
		_move(0, 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirm()


func _bind_all() -> void:
	var male: bool = NewGameState == null or NewGameState.is_male
	var count: int = _filled_count()
	for i: int in slots.size():
		var slot: Node = slots[i]
		if slot == null:
			continue
		if slot.has_method("set_player_gender"):
			slot.call("set_player_gender", male)
		if i < count:
			var mon: PokemonInstance = player_data.get_pokemon(i)
			if slot.has_method("bind"):
				slot.call("bind", mon)
			slot.visible = true
		else:
			if slot.has_method("clear_slot"):
				slot.call("clear_slot")
			else:
				slot.visible = false


func _move(dx: int, dy: int) -> void:
	var count: int = _filled_count()
	# Cancel es navegable en BROWSE y SWITCH
	if _index == CANCEL_SENTINEL:
		if dy < 0 or dx != 0:
			if count > 0:
				_set_index(count - 1)
				_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		return
	if count <= 0:
		_set_index(CANCEL_SENTINEL)
		_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		return
	var col: int = _index % 2
	var row: int = _index / 2
	var max_row: int = (count - 1) / 2
	if dy > 0 and row >= max_row:
		_set_index(CANCEL_SENTINEL)
		_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		return
	col = clampi(col + dx, 0, 1)
	row = clampi(row + dy, 0, max_row)
	var next: int = row * 2 + col
	if next >= count:
		next = count - 1
	if next == _index and dx != 0:
		var alt: int = row * 2 + (1 - col)
		if alt < count:
			next = alt
	_set_index(next)
	_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)


func _set_index(i: int) -> void:
	_index = i
	_refresh_selection()
	if _mode == Mode.BROWSE:
		_set_prompt("Elegir un Pokémon.")
	elif _mode == Mode.SWITCH:
		_set_prompt("¿Mover a qué posición?")


func _refresh_selection() -> void:
	var count: int = _filled_count()
	for i: int in slots.size():
		var slot: Node = slots[i]
		if slot == null or not slot.has_method("set_box_state"):
			continue
		if i >= count:
			continue
		if _mode == Mode.SWITCH and i == _switch_from:
			slot.call("set_box_state", 2) # SWITCH
		elif i == _index:
			slot.call("set_box_state", 1) # SELECT
		else:
			slot.call("set_box_state", 0)
	if _cancel:
		# resaltar cancel si está seleccionado
		_cancel.modulate = Color(1, 1, 1, 1) if _index == CANCEL_SENTINEL else Color(0.7, 0.7, 0.7, 1)


func _set_prompt(t: String) -> void:
	if _text_lbl:
		_text_lbl.text = t


func _confirm() -> void:
	if _index == CANCEL_SENTINEL:
		_on_cancel_back()
		return
	var mon: PokemonInstance = _current_mon()
	if mon == null:
		_se(SFXGame.SoundEffectID.SE_GUI_SEL_BUZZER)
		return
	_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
	match _mode:
		Mode.BROWSE:
			await _open_action_menu()
		Mode.SWITCH:
			_finish_switch()
		_:
			pass


func _on_cancel_back() -> void:
	match _mode:
		Mode.SWITCH:
			_mode = Mode.BROWSE
			_switch_from = -1
			_set_prompt("Elegir un Pokémon.")
			_refresh_selection()
			_se(SFXGame.SoundEffectID.SE_GUI_SEL_CANCEL)
		_:
			_close()


func _open_action_menu() -> void:
	_mode = Mode.ACTION
	_set_prompt("Pokémon seleccionado.")
	_busy = true
	MessageService.show_texts(
		[""],
		"",
		["Summary", "Cambiar", "Item", "Cancelar"]
	)
	await MessageService.message_finished
	_busy = false
	var c: int = MessageService.get_last_choice()
	match c:
		0:
			_mode = Mode.BROWSE
			_set_prompt("Elegir un Pokémon.")
			_open_summary()
		1:
			_mode = Mode.SWITCH
			_switch_from = _index
			_set_prompt("¿Mover a qué posición?")
			_refresh_selection()
		2:
			await _open_item_menu()
		_:
			_mode = Mode.BROWSE
			_set_prompt("Elegir un Pokémon.")
			_refresh_selection()


func _open_item_menu() -> void:
	_mode = Mode.ITEM
	_set_prompt("¿Qué quieres hacer con él?")
	_busy = true
	MessageService.show_texts(
		[""],
		"",
		["Dar objeto", "Quitar objeto", "Atrás"]
	)
	await MessageService.message_finished
	_busy = false
	var c: int = MessageService.get_last_choice()
	match c:
		0, 1:
			# Stub hasta bag UI
			MessageService.show_texts(["Aún no implementado."])
			await MessageService.message_finished
		_:
			pass
	_mode = Mode.BROWSE
	_set_prompt("Elegir un Pokémon.")
	_refresh_selection()


func _finish_switch() -> void:
	if _switch_from < 0 or player_data == null:
		_mode = Mode.BROWSE
		return
	if _index == _switch_from:
		_mode = Mode.BROWSE
		_switch_from = -1
		_set_prompt("Elegir un Pokémon.")
		_refresh_selection()
		return
	var a: int = _switch_from
	var b: int = _index
	if a >= player_data.party.size() or b >= player_data.party.size():
		_mode = Mode.BROWSE
		_switch_from = -1
		return
	var tmp: PokemonInstance = player_data.party[a]
	player_data.party[a] = player_data.party[b]
	player_data.party[b] = tmp
	_mode = Mode.BROWSE
	_switch_from = -1
	_bind_all()
	_set_index(b)
	_set_prompt("Elegir un Pokémon.")
	_se(SFXGame.SoundEffectID.SE_GUI_PARTY_SWITCH)


func _open_summary() -> void:
	if player_data == null:
		return
	_busy = true
	if SpeciesCatalog and SpeciesCatalog.has_method("preload_ids"):
		var ids: Array = []
		for p: PokemonInstance in player_data.party:
			if p:
				ids.append(p.species_id)
		SpeciesCatalog.preload_ids(ids)
	var path: String = "res://Escenas/UI/Summary_Screen/summary_screen.tscn"
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_busy = false
		return
	_summary = packed.instantiate() as CanvasLayer
	_summary.set("player_data", player_data)
	_summary.set("party_index", _index)
	get_tree().root.add_child(_summary)
	if not _summary.tree_exiting.is_connected(_on_summary_exiting):
		_summary.tree_exiting.connect(_on_summary_exiting)


func _on_summary_exiting() -> void:
	_summary = null
	_busy = false
	_mode = Mode.BROWSE
	_bind_all()
	_set_index(clampi(_index, 0, maxi(0, _filled_count() - 1)))
	_set_prompt("Elegir un Pokémon.")
	visible = true


func _close() -> void:
	_se(SFXGame.SoundEffectID.SE_GUI_MENU_CLOSE)
	if _return_start != null and is_instance_valid(_return_start):
		_return_start.visible = true
		if _return_start.has_method("_refresh"):
			_return_start.call("_refresh")
	closed.emit()
	queue_free()


func _current_mon() -> PokemonInstance:
	if player_data == null or _index == CANCEL_SENTINEL:
		return null
	return player_data.get_pokemon(_index)


func _filled_count() -> int:
	return player_data.party_count() if player_data else 0


func _se(id: SFXGame.SoundEffectID) -> void:
	if MusicManager and MusicManager.has_method("reproducir_se"):
		MusicManager.reproducir_se(id)
