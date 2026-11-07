extends Node
## Catálogo de movimientos: índice crudo + MoveData bajo demanda.

const PATH: String = "res://Datos/Moves/moves.json"

var _raw: Dictionary = {}
var _cache: Dictionary = {}
var _ids: Array = []
var _loaded: bool = false


func _ready() -> void:
	call_deferred("warm_index")


func warm_index() -> void:
	if _loaded:
		return
	_build_index()


func is_ready() -> bool:
	return _loaded


func count() -> int:
	_ensure()
	return _ids.size()


func has_move(id: MoveId.Id) -> bool:
	if id == MoveId.Id.NONE:
		return false
	_ensure()
	return _cache.has(id) or _raw.has(id)


func get_move(id: MoveId.Id) -> MoveData:
	if id == MoveId.Id.NONE:
		return null
	if _cache.has(id):
		return _cache[id] as MoveData
	_ensure()
	if not _raw.has(id):
		return null
	var data: MoveData = _from_dict(_raw[id] as Dictionary)
	_raw.erase(id)
	if data != null and data.is_valid():
		_cache[id] = data
		return data
	return null


func get_display_name(id: MoveId.Id) -> String:
	if id == MoveId.Id.NONE:
		return ""
	if _cache.has(id):
		return (_cache[id] as MoveData).display_name
	_ensure()
	if _raw.has(id):
		var n: String = str((_raw[id] as Dictionary).get("display_name", ""))
		if not n.is_empty():
			return n
	return MoveId.to_token(id)


func clear_cache() -> void:
	_cache.clear()


func _ensure() -> void:
	if not _loaded:
		_build_index()


func _build_index() -> void:
	_raw.clear()
	_ids.clear()
	if not FileAccess.file_exists(PATH):
		push_error("MoveCatalog: no existe %s" % PATH)
		_loaded = true
		return
	var text: String = FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(text)
	text = ""
	if typeof(parsed) != TYPE_ARRAY:
		push_error("MoveCatalog: JSON inválido")
		_loaded = true
		return
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var mid: MoveId.Id = MoveId.from_token(str(d.get("id", "")))
		if mid == MoveId.Id.NONE:
			continue
		_raw[mid] = d
		_ids.append(mid)
	_loaded = true
	print("MoveCatalog: índice %d movimientos (lazy)" % _ids.size())


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
