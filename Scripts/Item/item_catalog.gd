extends Node
## Catálogo de ítems: índice crudo + ItemData bajo demanda.

const PATH: String = "res://Datos/Items/items.json"

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


func has_item(id: ItemId.Id) -> bool:
	if id == ItemId.Id.NONE:
		return false
	_ensure()
	return _cache.has(id) or _raw.has(id)


func get_item(id: ItemId.Id) -> ItemData:
	if id == ItemId.Id.NONE:
		return null
	if _cache.has(id):
		return _cache[id] as ItemData
	_ensure()
	if not _raw.has(id):
		return null
	var data: ItemData = _from_dict(_raw[id] as Dictionary)
	_raw.erase(id)
	if data != null and data.is_valid():
		_cache[id] = data
		return data
	return null


func get_display_name(id: ItemId.Id) -> String:
	if id == ItemId.Id.NONE:
		return ""
	if _cache.has(id):
		return (_cache[id] as ItemData).display_name
	_ensure()
	if _raw.has(id):
		var n: String = str((_raw[id] as Dictionary).get("display_name", ""))
		if not n.is_empty():
			return n
	return ItemId.to_token(id)


func stack_limit(id: ItemId.Id) -> int:
	var data: ItemData = get_item(id)
	if data != null:
		return maxi(1, data.stack_limit)
	return 999


func clear_cache() -> void:
	_cache.clear()


func _ensure() -> void:
	if not _loaded:
		_build_index()


func _build_index() -> void:
	_raw.clear()
	_ids.clear()
	if not FileAccess.file_exists(PATH):
		push_error("ItemCatalog: no existe %s" % PATH)
		_loaded = true
		return
	var text: String = FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(text)
	text = ""
	if typeof(parsed) != TYPE_ARRAY:
		push_error("ItemCatalog: JSON inválido")
		_loaded = true
		return
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var iid: ItemId.Id = ItemId.from_token(str(d.get("id", "")))
		if iid == ItemId.Id.NONE:
			continue
		_raw[iid] = d
		_ids.append(iid)
	_loaded = true
	print("ItemCatalog: índice %d ítems (lazy)" % _ids.size())


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
