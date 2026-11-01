extends Node
## Autoload ItemCatalog

const JSON_PATH: String = "res://Datos/Items/items.json"

var _by_id: Dictionary = {}  # ItemId.Id → ItemData


func _ready() -> void:
	reload()


func reload() -> void:
	_by_id.clear()
	if not FileAccess.file_exists(JSON_PATH):
		push_warning("ItemCatalog: falta %s — solo enum sin datos" % JSON_PATH)
		return
	var f: FileAccess = FileAccess.open(JSON_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_ARRAY:
		push_error("ItemCatalog: JSON inválido")
		return
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: ItemData = ItemData.from_dict(entry as Dictionary)
		if data.id == ItemId.Id.NONE:
			continue
		_by_id[data.id] = data
	print("ItemCatalog: %d ítems cargados" % _by_id.size())


func get_item(id: ItemId.Id) -> ItemData:
	return _by_id.get(id) as ItemData


func has_item(id: ItemId.Id) -> bool:
	return _by_id.has(id)


func get_display_name(id: ItemId.Id) -> String:
	var d: ItemData = get_item(id)
	if d != null and not d.name.is_empty():
		return d.name
	return ItemId.to_key(id)


func stack_limit(id: ItemId.Id) -> int:
	var d: ItemData = get_item(id)
	return d.stack_limit if d != null else 999
