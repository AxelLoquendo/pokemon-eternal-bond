extends Node2D
## Página de movimientos del summary.
## Vista: rellena slots y el detalle del movimiento seleccionado.
## El cursor lo mueve el controlador (select_slot).

const CATEGORY_DIR: String = "res://Graficos/UI/Summary_Screen/Move_Page/move_"
const TYPE_BOX_DIR: String = "res://Graficos/UI/Summary_Screen/Move_Page/move_box_"
const TYPE_ICON_DIR: String = "res://Graficos/Types/"

const CATEGORY_FILE: Dictionary = {
	MoveCategory.Id.PHYSICAL: "physical_box",
	MoveCategory.Id.SPECIAL: "special_box",
	MoveCategory.Id.STATUS: "status_box",
}

const TYPE_FILE: Dictionary = {
	TypeId.Id.NORMAL: "normal",
	TypeId.Id.FIGHTING: "fighting",
	TypeId.Id.FLYING: "flying",
	TypeId.Id.POISON: "poison",
	TypeId.Id.GROUND: "ground",
	TypeId.Id.ROCK: "rock",
	TypeId.Id.BUG: "bug",
	TypeId.Id.GHOST: "ghost",
	TypeId.Id.STEEL: "steel",
	TypeId.Id.MYSTERY: "mystery",
	TypeId.Id.FIRE: "fire",
	TypeId.Id.WATER: "water",
	TypeId.Id.GRASS: "grass",
	TypeId.Id.ELECTRIC: "electric",
	TypeId.Id.PSYCHIC: "psychic",
	TypeId.Id.ICE: "ice",
	TypeId.Id.DRAGON: "dragon",
	TypeId.Id.DARK: "dark",
	TypeId.Id.FAIRY: "fairy",
	TypeId.Id.STELLAR: "stellar",
}

@onready var _slots: Array[Node2D] = [
	$Move_Box/Slot_1,
	$Move_Box/Slot_2,
	$Move_Box/Slot_3,
	$Move_Box/Slot_4,
]
@onready var _cursor: Sprite2D = $Move_Box/Cursor_Move
@onready var _power: Label = $Move_Box/Power_Number
@onready var _accuracy: Label = $Move_Box/Accuracy_Number
@onready var _type_icon: Sprite2D = $Move_Box/Type
@onready var _category_name: Label = $Move_Box/Category_Name
@onready var _description: Label = $Move_Box/Move_Description
@onready var _mon_icon: Sprite2D = $Move_Box/Mon_Icon

var _mon: PokemonInstance = null
var _selected: int = 0
## Cursor activo solo tras buttonA. _held >= 0 = movimiento marcado para intercambiar.
var _active: bool = false
var _held: int = -1
var _cursor_held: Sprite2D = null
var _icon_t: float = 0.0
const ICON_FRAME_TIME: float = 0.35
const CURSOR_SELECTED: String = "res://Graficos/UI/Summary_Screen/Move_Page/move_cursor_selected.png"

func _ready() -> void:
	if _cursor:
		_cursor.visible = false
		_cursor_held = Sprite2D.new()
		_cursor_held.name = "Cursor_Move_Selected"
		_cursor_held.centered = _cursor.centered
		_cursor_held.z_index = _cursor.z_index - 1
		_cursor_held.visible = false
		if ResourceLoader.exists(CURSOR_SELECTED):
			_cursor_held.texture = load(CURSOR_SELECTED)
		_cursor.get_parent().add_child(_cursor_held)

func _process(delta: float) -> void:
	if _mon_icon == null or not is_visible_in_tree():
		return
	if _mon_icon.texture == null or _mon_icon.vframes < 2:
		return
	_icon_t += delta
	if _icon_t < ICON_FRAME_TIME:
		return
	_icon_t = 0.0
	_mon_icon.frame = (_mon_icon.frame + 1) % _mon_icon.vframes

func is_active() -> bool:
	return _active

## buttonA. true si la página consumió la pulsación.
func confirm() -> bool:
	if _mon == null or move_count() <= 0:
		return true
	if not _active:
		_active = true
		_held = -1
		_hide_held()
		select_slot(_first_filled())
		return true
	if _held < 0:
		_held = _selected
		_place_held()
		return true
	if _held == _selected:
		_held = -1
		_hide_held()
		return true
	_swap_slots(_held, _selected)
	_held = -1
	_hide_held()
	_refresh_slots()
	select_slot(_selected)
	return true

## buttonB. true si no hay que cerrar el summary.
func cancel() -> bool:
	if _held >= 0:
		_held = -1
		_hide_held()
		return true
	if _active:
		_active = false
		if _cursor:
			_cursor.visible = false
		return true
	return false

func exit_mode() -> void:
	_active = false
	_held = -1
	_hide_held()
	if _cursor:
		_cursor.visible = false



func bind(mon: PokemonInstance) -> void:
	_mon = mon
	_selected = 0
	exit_mode()
	_refresh_slots()
	if _mon_icon and mon != null:
		_mon_icon.texture = mon.icon_texture()
		_mon_icon.vframes = 2
		_mon_icon.frame = 0
	# Detalle del primer movimiento, sin cursor hasta buttonA.
	_show_detail(_first_filled())


func move_count() -> int:
	if _mon == null:
		return 0
	var n: int = 0
	for i: int in _mon.moves.size():
		if _mon.moves[i] != MoveId.Id.NONE:
			n += 1
	return n


func select_slot(index: int) -> void:
	if _mon == null or move_count() <= 0:
		_selected = 0
		if _cursor:
			_cursor.visible = false
		_clear_detail()
		return
	_selected = _wrap_to_filled(index)
	if _active:
		_place_cursor()
	elif _cursor:
		_cursor.visible = false
	_show_detail(_selected)


func select_delta(delta: int) -> void:
	if move_count() <= 0:
		return
	select_slot(_selected + delta)


func _refresh_slots() -> void:
	for i: int in _slots.size():
		_fill_slot(i)


func _fill_slot(index: int) -> void:
	var slot: Node2D = _slots[index]
	var category_spr: Sprite2D = slot.get_node_or_null("Category") as Sprite2D
	var type_spr: Sprite2D = slot.get_node_or_null("Move_Type") as Sprite2D
	var name_lbl: Label = slot.get_node_or_null("Move_Type/Move_Name") as Label
	var mid: MoveId.Id = _move_at(index)
	var data: MoveData = _move_data(mid)
	var filled: bool = data != null
	if category_spr:
		category_spr.visible = filled
		if filled:
			category_spr.texture = _category_tex(data.category)
	if type_spr:
		type_spr.visible = filled
		if filled:
			type_spr.texture = _type_box_tex(_effective_type(data))
	if name_lbl:
		name_lbl.text = data.display_name if filled else ""


func _show_detail(index: int) -> void:
	var data: MoveData = _move_data(_move_at(index))
	if data == null:
		_clear_detail()
		return
	var type_id: TypeId.Id = _effective_type(data)
	if _power:
		if data.power <= 0:
			_power.text = "—"
		else:
			_power.text = str(data.power)
	if _accuracy:
		if data.accuracy <= 0:
			_accuracy.text = "—"
		else:
			_accuracy.text = str(data.accuracy)
	if _type_icon:
		_type_icon.texture = _type_icon_tex(type_id)
		_type_icon.visible = _type_icon.texture != null
	if _category_name:
		_category_name.text = _category_label(data.category)
	if _description:
		_description.text = data.description


func _clear_detail() -> void:
	if _power:
		_power.text = "—"
	if _accuracy:
		_accuracy.text = "—"
	if _type_icon:
		_type_icon.texture = null
		_type_icon.visible = false
	if _category_name:
		_category_name.text = ""
	if _description:
		_description.text = ""


func _place_held() -> void:
	if _cursor_held == null:
		return
	if _held < 0 or _held >= _slots.size():
		_cursor_held.visible = false
		return
	# Misma posición visual que el cursor activo al marcar el movimiento.
	if _cursor:
		_cursor_held.position = _cursor.position
	else:
		_cursor_held.position = _slots[_held].position
	_cursor_held.visible = true


func _hide_held() -> void:
	if _cursor_held:
		_cursor_held.visible = false


func _swap_slots(a: int, b: int) -> void:
	if _mon == null or a == b:
		return
	_swap_moves(_mon.moves, a, b)
	_swap_ints(_mon.move_pp, a, b)
	_swap_ints(_mon.move_pp_ups, a, b)


func _swap_moves(arr: Array[MoveId.Id], a: int, b: int) -> void:
	var need: int = maxi(a, b)
	while arr.size() <= need:
		arr.append(MoveId.Id.NONE)
	var tmp: MoveId.Id = arr[a]
	arr[a] = arr[b]
	arr[b] = tmp


func _swap_ints(arr: Array[int], a: int, b: int) -> void:
	var need: int = maxi(a, b)
	while arr.size() <= need:
		arr.append(0)
	var tmp: int = arr[a]
	arr[a] = arr[b]
	arr[b] = tmp


func _place_cursor() -> void:
	if _cursor == null:
		return
	if _selected < 0 or _selected >= _slots.size():
		_cursor.visible = false
		return
	_cursor.visible = true
	_cursor.position = _slots[_selected].position


func _move_at(index: int) -> MoveId.Id:
	if _mon == null or index < 0 or index >= _mon.moves.size():
		return MoveId.Id.NONE
	return _mon.moves[index]


func _move_data(mid: MoveId.Id) -> MoveData:
	if mid == MoveId.Id.NONE or MoveCatalog == null:
		return null
	return MoveCatalog.get_move(mid)


func _effective_type(data: MoveData) -> TypeId.Id:
	if data == null:
		return TypeId.Id.NONE
	if data.id == MoveId.Id.HIDDEN_POWER and _mon != null and _mon.has_method("hidden_power_type"):
		return _mon.hidden_power_type()
	return data.type


func _first_filled() -> int:
	for i: int in _slots.size():
		if _move_at(i) != MoveId.Id.NONE:
			return i
	return 0


func _wrap_to_filled(start: int) -> int:
	if move_count() <= 0:
		return 0
	var i: int = posmod(start, _slots.size())
	for _step: int in _slots.size():
		if _move_at(i) != MoveId.Id.NONE:
			return i
		i = posmod(i + 1, _slots.size())
	return 0


func _category_tex(cat: MoveCategory.Id) -> Texture2D:
	if not CATEGORY_FILE.has(cat):
		return null
	return _load_tex(CATEGORY_DIR + str(CATEGORY_FILE[cat]) + ".png")


func _type_box_tex(type_id: TypeId.Id) -> Texture2D:
	if not TYPE_FILE.has(type_id):
		return null
	return _load_tex(TYPE_BOX_DIR + str(TYPE_FILE[type_id]) + ".png")


func _type_icon_tex(type_id: TypeId.Id) -> Texture2D:
	if type_id == TypeId.Id.NONE:
		return null
	var token: String = TypeId.to_token(type_id).to_lower()
	if token.is_empty():
		return null
	var path: String = TYPE_ICON_DIR + token + ".png"
	if token == "mystery" and not ResourceLoader.exists(path):
		path = TYPE_ICON_DIR + "mistery.png"
	return _load_tex(path)


func _category_label(cat: MoveCategory.Id) -> String:
	match cat:
		MoveCategory.Id.PHYSICAL:
			return "Fís."
		MoveCategory.Id.SPECIAL:
			return "Esp."
		MoveCategory.Id.STATUS:
			return "Est."
		_:
			return ""


func _load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
