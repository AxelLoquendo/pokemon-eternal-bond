extends CanvasLayer
## Party menu: muestra el equipo, abre Summary y vuelve al Start Menu.

signal closed

const PARTY_SCENE: String = "res://Escenas/UI/Party_Menu/party_menu.tscn"
const SUMMARY_SCRIPT: String = "res://Scripts/UI/Summary_Screen/summary_screen.gd"

@onready var bg_anim: AnimationPlayer = $BG/BG_Lluvia
@onready var _text_name: Label = $Text_Box/Mon_Name if has_node("Text_Box/Mon_Name") else null
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
var _busy: bool = false
var _return_start: CanvasLayer = null
var _summary: CanvasLayer = null
var _slot_scripts: Array = [] ## party_slot instances


static func open(tree: SceneTree, pd: PlayerData = null, return_start: CanvasLayer = null) -> CanvasLayer:
	var packed: PackedScene = load(PARTY_SCENE) as PackedScene
	if packed == null:
		push_error("PartyMenu: no se pudo cargar %s" % PARTY_SCENE)
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
	_slot_scripts.clear()
	for s: Node2D in slots:
		_slot_scripts.append(s)
	if player_data == null:
		player_data = BagService.player_data_from_tree(get_tree())
	if player_data == null:
		player_data = PlayerData.new()
	_bind_all()
	_set_index(0)
	_se(SFXGame.SoundEffectID.SE_GUI_MENU_OPEN)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _busy or _summary != null:
		return
	if event.is_echo():
		return
	if event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
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
	var male: bool = true
	if NewGameState != null:
		male = NewGameState.is_male
	var count: int = player_data.party_count() if player_data else 0
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
	if count <= 0:
		_index = 0


func _move(dx: int, dy: int) -> void:
	var count: int = _filled_count()
	if count <= 0:
		return
	# Grid 2 columnas
	var col: int = _index % 2
	var row: int = _index / 2
	col = clampi(col + dx, 0, 1)
	row = clampi(row + dy, 0, 2)
	var next: int = row * 2 + col
	if next >= count:
		# Snap al último mon válido
		next = count - 1
	if next == _index:
		# Si quedó vacío al cambiar columna, probar el otro de la fila
		if dx != 0:
			var alt: int = row * 2 + (1 - col)
			if alt < count:
				next = alt
	_set_index(next)
	_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)


func _set_index(i: int) -> void:
	var count: int = _filled_count()
	if count <= 0:
		_index = 0
		_refresh_selection()
		return
	_index = clampi(i, 0, count - 1)
	_refresh_selection()
	_update_footer()


func _refresh_selection() -> void:
	var count: int = _filled_count()
	for i: int in slots.size():
		var slot: Node = slots[i]
		if slot == null or not slot.has_method("set_box_state"):
			continue
		if i >= count:
			continue
		if i == _index:
			slot.call("set_box_state", 1) # SELECT
		else:
			slot.call("set_box_state", 0) # NORMAL


func _update_footer() -> void:
	if _text_name == null:
		return
	var mon: PokemonInstance = _current_mon()
	_text_name.text = mon.display_name() if mon else ""


func _confirm() -> void:
	var mon: PokemonInstance = _current_mon()
	if mon == null:
		_se(SFXGame.SoundEffectID.SE_GUI_SEL_BUZZER)
		return
	_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
	_open_summary()


func _open_summary() -> void:
	if player_data == null:
		return
	_busy = true
	# SummaryScreen.open_from_party
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
	_bind_all()
	_set_index(_index)
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
	if player_data == null:
		return null
	return player_data.get_pokemon(_index)


func _filled_count() -> int:
	if player_data == null:
		return 0
	return player_data.party_count()


func _se(id: SFXGame.SoundEffectID) -> void:
	if MusicManager and MusicManager.has_method("reproducir_se"):
		MusicManager.reproducir_se(id)
