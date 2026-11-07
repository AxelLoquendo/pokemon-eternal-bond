extends Node
## Carga Datos/Moves/moves.json (tools/import_expansion.py).

const PATH: String = "res://Datos/Moves/moves.json"

var _by_id: Dictionary = {} ## MoveId.Id -> MoveData


func _ready() -> void:
	_load_from_json()


func get_move(id: MoveId.Id) -> MoveData:
	return _by_id.get(id) as MoveData


func has_move(id: MoveId.Id) -> bool:
	return _by_id.has(id)


func count() -> int:
	return _by_id.size()


func get_display_name(id: MoveId.Id) -> String:
	var data: MoveData = get_move(id)
	if data != null and not data.display_name.is_empty():
		return data.display_name
	return MoveId.to_token(id)


func _load_from_json() -> void:
	_by_id.clear()
	if not FileAccess.file_exists(PATH):
		push_error("MoveCatalog: no existe %s" % PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_ARRAY:
		push_error("MoveCatalog: JSON inválido")
		return
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: MoveData = _from_dict(entry as Dictionary)
		if data != null and data.is_valid():
			_by_id[data.id] = data
	print("MoveCatalog: %d movimientos cargados" % _by_id.size())


func _from_dict(e: Dictionary) -> MoveData:
	var id: MoveId.Id = MoveId.from_token(str(e.get("id", "")))
	if id == MoveId.Id.NONE:
		return null
	var data := MoveData.new()
	data.id = id
	data.display_name = str(e.get("display_name", ""))
	data.description = str(e.get("description", ""))
	data.type = TypeId.from_token(str(e.get("type", "NORMAL")))
	data.category = _category(str(e.get("category", "STATUS")))
	data.power = int(e.get("power", 0))
	data.accuracy = int(e.get("accuracy", 100))
	data.pp = int(e.get("pp", 5))
	data.priority = int(e.get("priority", 0))
	data.target = str(e.get("target", "TARGET_SELECTED")).replace("TARGET_", "")
	data.effect = str(e.get("effect", "EFFECT_HIT"))
	data.strike_count = int(e.get("strike_count", 1))
	data.critical_stage = int(e.get("critical_stage", 0))
	data.recoil = int(e.get("recoil", 0))
	data.makes_contact = bool(e.get("makes_contact", false))
	data.ignores_protect = bool(e.get("ignores_protect", false))
	data.sound = bool(e.get("sound", false))
	data.punch = bool(e.get("punch", false))
	data.bite = bool(e.get("bite", false))
	data.pulse = bool(e.get("pulse", false))
	data.ballistic = bool(e.get("ballistic", false))
	data.powder = bool(e.get("powder", false))
	data.slicing = bool(e.get("slicing", false))
	data.wind = bool(e.get("wind", false))
	data.dance = bool(e.get("dance", false))
	data.healing = bool(e.get("healing", false))
	data.ignores_substitute = bool(e.get("ignores_substitute", false))
	data.z_effect = str(e.get("z_effect", ""))
	data.extra_flags = PackedStringArray()
	for f: Variant in e.get("extra_flags", []):
		data.extra_flags.append(str(f))
	return data


func _category(token: String) -> MoveCategory.Id:
	match token:
		"PHYSICAL":
			return MoveCategory.Id.PHYSICAL
		"SPECIAL":
			return MoveCategory.Id.SPECIAL
		"STATUS":
			return MoveCategory.Id.STATUS
		_:
			return MoveCategory.Id.NONE
