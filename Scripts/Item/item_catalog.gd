extends Node
## Carga Datos/Items/items.json (tools/import_expansion.py).

const PATH: String = "res://Datos/Items/items.json"

var _by_id: Dictionary = {} ## ItemId.Id -> ItemData


func _ready() -> void:
	_load_from_json()


func get_item(id: ItemId.Id) -> ItemData:
	return _by_id.get(id) as ItemData


func has_item(id: ItemId.Id) -> bool:
	return _by_id.has(id)


func count() -> int:
	return _by_id.size()


func get_display_name(id: ItemId.Id) -> String:
	var data: ItemData = get_item(id)
	if data != null and not data.display_name.is_empty():
		return data.display_name
	return ItemId.to_token(id)


func stack_limit(id: ItemId.Id) -> int:
	var data: ItemData = get_item(id)
	if data != null:
		return maxi(1, data.stack_limit)
	return 999


func _load_from_json() -> void:
	_by_id.clear()
	if not FileAccess.file_exists(PATH):
		push_error("ItemCatalog: no existe %s" % PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_ARRAY:
		push_error("ItemCatalog: JSON inválido")
		return
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: ItemData = _from_dict(entry as Dictionary)
		if data != null and data.is_valid():
			_by_id[data.id] = data
	print("ItemCatalog: %d ítems cargados" % _by_id.size())


func _from_dict(e: Dictionary) -> ItemData:
	var id: ItemId.Id = ItemId.from_token(str(e.get("id", "")))
	if id == ItemId.Id.NONE:
		return null
	var data := ItemData.new()
	data.id = id
	data.display_name = str(e.get("display_name", ""))
	data.description = str(e.get("description", ""))
	data.pocket = _pocket(str(e.get("pocket", "ITEMS")))
	data.price = int(e.get("price", 0))
	data.important = bool(e.get("important", false))
	data.hold_effect = str(e.get("hold_effect", ""))
	data.hold_effect_param = int(e.get("hold_effect_param", 0))
	data.field_use = str(e.get("field_use", ""))
	data.battle_use = str(e.get("battle_use", ""))
	data.sort_type = str(e.get("sort_type", ""))
	data.fling_power = int(e.get("fling_power", 0))
	data.tm_move = MoveId.from_token(str(e.get("tm_move", "")))
	if data.pocket == ItemPocket.Id.KEY_ITEMS or data.important:
		data.stack_limit = 1
	else:
		data.stack_limit = 999
	return data


func _pocket(token: String) -> ItemPocket.Id:
	match token:
		"MEDICINE":
			return ItemPocket.Id.MEDICINE
		"BALLS":
			return ItemPocket.Id.BALLS
		"BATTLE":
			return ItemPocket.Id.BATTLE
		"BERRIES":
			return ItemPocket.Id.BERRIES
		"KEY_ITEMS":
			return ItemPocket.Id.KEY_ITEMS
		"TMS":
			return ItemPocket.Id.TMS
		"NONE":
			return ItemPocket.Id.NONE
		_:
			return ItemPocket.Id.ITEMS
