extends Node
## Resuelve texturas desde Graficos/Pokemon/<carpeta>/.
## No carga todo al inicio: solo lo que pidas, con caché.

const ROOT: String = "res://Graficos/Pokemon/"

var _cache: Dictionary = {} # path -> Texture2D


func get_front(id: SpeciesId.Id, shiny: bool = false, female: bool = false) -> Texture2D:
	return _load_kind(id, "front", shiny, female)


func get_back(id: SpeciesId.Id, shiny: bool = false, female: bool = false) -> Texture2D:
	return _load_kind(id, "back", shiny, female)


func get_icon(id: SpeciesId.Id) -> Texture2D:
	return _load_kind(id, "icon", false, false)


func _load_kind(id: SpeciesId.Id, kind: String, shiny: bool, female: bool) -> Texture2D:
	var folder: String = SpeciesId.sprite_folder(id)
	if folder.is_empty():
		return null

	for path in _candidate_paths(folder, kind, shiny, female):
		var tex: Texture2D = _get_or_load(path)
		if tex != null:
			return tex
	return null


func _candidate_paths(folder: String, kind: String, shiny: bool, female: bool) -> PackedStringArray:
	## Orden: lo más específico primero; si falta, cae a normal.
	var names: PackedStringArray = PackedStringArray()
	if kind == "icon":
		names.append("icon.png")
	else:
		if female and shiny:
			names.append("%s_female_shiny.png" % kind)
		if female:
			names.append("%s_female.png" % kind)
		if shiny:
			names.append("%s_shiny.png" % kind)
		names.append("%s.png" % kind)

	var out: PackedStringArray = PackedStringArray()
	for file_name in names:
		out.append(ROOT + folder + "/" + file_name)
	return out


func _get_or_load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path] as Texture2D
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		_cache[path] = tex
	return tex


func clear_cache() -> void:
	_cache.clear()
