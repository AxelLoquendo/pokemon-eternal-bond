extends Node

const JSON_PATH: String = "res://Datos/Species/species.json"

var _by_id: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	_by_id.clear()
	if not FileAccess.file_exists(JSON_PATH):
		push_warning("SpeciesCatalog: falta %s" % JSON_PATH)
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
		var data: SpeciesData = SpeciesData.from_dict(entry)
		if data.id == SpeciesId.Id.NONE:
			continue
		_by_id[data.id] = data
	print("SpeciesCatalog: %d species" % _by_id.size())


func get_species(id: SpeciesId.Id) -> SpeciesData:
	return _by_id.get(id) as SpeciesData


func get_display_name(id: SpeciesId.Id) -> String:
	var d: SpeciesData = get_species(id)
	if d != null and not d.name.is_empty():
		return d.name
	return SpeciesId.to_key(id)
