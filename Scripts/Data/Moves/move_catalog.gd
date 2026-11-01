extends Node

const JSON_PATH: String = "res://Datos/Moves/moves.json"

var _by_id: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	_by_id.clear()
	if not FileAccess.file_exists(JSON_PATH):
		push_warning("MoveCatalog: falta %s" % JSON_PATH)
		return
	var f := FileAccess.open(JSON_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_ARRAY:
		return
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: MoveData = MoveData.from_dict(entry)
		if data.id == MoveId.Id.NONE:
			continue
		_by_id[data.id] = data
	print("MoveCatalog: %d movimientos" % _by_id.size())


func get_move(id: MoveId.Id) -> MoveData:
	return _by_id.get(id) as MoveData


func get_display_name(id: MoveId.Id) -> String:
	var d: MoveData = get_move(id)
	if d != null and not d.name.is_empty():
		return d.name
	return MoveId.to_key(id)
