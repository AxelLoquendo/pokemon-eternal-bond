extends Node
## Carga Datos/Abilities/abilities.json (tools/import_expansion.py).

const PATH: String = "res://Datos/Abilities/abilities.json"

var _by_id: Dictionary = {} ## AbilityId.Id -> AbilityData


func _ready() -> void:
	_load_from_json()


func get_ability(id: AbilityId.Id) -> AbilityData:
	return _by_id.get(id) as AbilityData


func has_ability(id: AbilityId.Id) -> bool:
	return _by_id.has(id)


func count() -> int:
	return _by_id.size()


func get_display_name(id: AbilityId.Id) -> String:
	var data: AbilityData = get_ability(id)
	if data != null and not data.display_name.is_empty():
		return data.display_name
	return AbilityId.to_token(id)


func _load_from_json() -> void:
	_by_id.clear()
	if not FileAccess.file_exists(PATH):
		push_error("AbilityCatalog: no existe %s" % PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_ARRAY:
		push_error("AbilityCatalog: JSON inválido")
		return
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: AbilityData = _from_dict(entry as Dictionary)
		if data != null and data.is_valid():
			_by_id[data.id] = data
	print("AbilityCatalog: %d habilidades cargadas" % _by_id.size())


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
