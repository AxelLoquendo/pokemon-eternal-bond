extends Node
## Catálogo de habilidades: índice crudo + AbilityData bajo demanda.

const PATH: String = "res://Datos/Abilities/abilities.json"

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


func has_ability(id: AbilityId.Id) -> bool:
	if id == AbilityId.Id.NONE:
		return false
	_ensure()
	return _cache.has(id) or _raw.has(id)


func get_ability(id: AbilityId.Id) -> AbilityData:
	if id == AbilityId.Id.NONE:
		return null
	if _cache.has(id):
		return _cache[id] as AbilityData
	_ensure()
	if not _raw.has(id):
		return null
	var data: AbilityData = _from_dict(_raw[id] as Dictionary)
	_raw.erase(id)
	if data != null and data.is_valid():
		_cache[id] = data
		return data
	return null


func get_display_name(id: AbilityId.Id) -> String:
	if id == AbilityId.Id.NONE:
		return ""
	if _cache.has(id):
		return (_cache[id] as AbilityData).display_name
	_ensure()
	if _raw.has(id):
		var n: String = str((_raw[id] as Dictionary).get("display_name", ""))
		if not n.is_empty():
			return n
	return AbilityId.to_token(id)


func clear_cache() -> void:
	_cache.clear()


func _ensure() -> void:
	if not _loaded:
		_build_index()


func _build_index() -> void:
	_raw.clear()
	_ids.clear()
	if not FileAccess.file_exists(PATH):
		push_error("AbilityCatalog: no existe %s" % PATH)
		_loaded = true
		return
	var text: String = FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(text)
	text = ""
	if typeof(parsed) != TYPE_ARRAY:
		push_error("AbilityCatalog: JSON inválido")
		_loaded = true
		return
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var aid: AbilityId.Id = AbilityId.from_token(str(d.get("id", "")))
		if aid == AbilityId.Id.NONE:
			continue
		_raw[aid] = d
		_ids.append(aid)
	_loaded = true
	print("AbilityCatalog: índice %d habilidades (lazy)" % _ids.size())


func _from_dict(e: Dictionary) -> AbilityData:
	var id: AbilityId.Id = AbilityId.from_token(str(e.get("id", "")))
	if id == AbilityId.Id.NONE:
		return null
	var data := AbilityData.new()
	data.id = id
	data.display_name = str(e.get("display_name", ""))
	data.description = str(e.get("description", ""))
	data.ai_rating = int(e.get("ai_rating", 0))
	data.cant_be_copied = bool(e.get("cant_be_copied", false))
	data.cant_be_swapped = bool(e.get("cant_be_swapped", false))
	data.cant_be_traced = bool(e.get("cant_be_traced", false))
	data.cant_be_suppressed = bool(e.get("cant_be_suppressed", false))
	data.cant_be_overwritten = bool(e.get("cant_be_overwritten", false))
	data.breakable = bool(e.get("breakable", false))
	data.fails_on_imposter = bool(e.get("fails_on_imposter", false))
	return data
