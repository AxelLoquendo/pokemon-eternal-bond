extends Node
## Gráficos de especie.
##
## Fuente ÚNICA de ruta: SpeciesData.sprite_folder (el .tres).
## Carga PNGs en res://Graficos/Pokemon/<sprite_folder>/.
## Si falta un archivo (p.ej. icon de una forma), prueba la carpeta padre.
## Alcremie usa nombres compuestos dentro de su carpeta cuando aplica.

const ROOT: String = "res://Graficos/Pokemon/"

var _cache: Dictionary = {} # path -> Texture2D


func get_front(id: SpeciesId.Id, shiny: bool = false, female: bool = false) -> Texture2D:
	return _load_kind(id, "front", shiny, female)


func get_back(id: SpeciesId.Id, shiny: bool = false, female: bool = false) -> Texture2D:
	return _load_kind(id, "back", shiny, female)


func get_icon(id: SpeciesId.Id) -> Texture2D:
	return _load_kind(id, "icon", false, false)


func folder_for(id: SpeciesId.Id) -> String:
	if id == SpeciesId.Id.NONE:
		return ""
	var data: SpeciesData = SpeciesCatalog.get_data(id)
	if data == null:
		return ""
	return str(data.sprite_folder).strip_edges()


func clear_cache() -> void:
	_cache.clear()


func _load_kind(id: SpeciesId.Id, kind: String, shiny: bool, female: bool) -> Texture2D:
	var folder: String = folder_for(id)
	if folder.is_empty():
		return null

	# Alcremie: archivos front_berry_lemon_cream.png etc. dentro de la carpeta
	var token: String = SpeciesId.to_token(id)
	if token.begins_with("ALCREMIE_") and token != "ALCREMIE_GMAX":
		var tex_a: Texture2D = _try_alcremie_files(folder, token, kind, shiny)
		if tex_a != null:
			return tex_a

	for path in _candidate_paths(folder, kind, shiny, female):
		var tex: Texture2D = _get_or_load(path)
		if tex != null:
			return tex

	# Forma sin icon propio → carpeta padre
	var parent: String = _parent_folder(folder)
	if not parent.is_empty():
		for path2 in _candidate_paths(parent, kind, shiny, female):
			var tex2: Texture2D = _get_or_load(path2)
			if tex2 != null:
				return tex2
	return null


func _try_alcremie_files(folder: String, token: String, kind: String, shiny: bool) -> Texture2D:
	if kind == "icon":
		return null
	var parsed: Dictionary = _parse_alcremie(token)
	if parsed.is_empty():
		return null
	var sweet: String = str(parsed["sweet"])
	var cream: String = str(parsed["cream"])
	var stem: String = kind
	var candidates: PackedStringArray = PackedStringArray()
	if sweet == "strawberry" and cream != "vanilla_cream":
		candidates.append(ROOT + "alcremie/strawberry/%s_strawberry_%s.png" % [stem, cream])
	elif sweet != "strawberry":
		candidates.append(ROOT + "alcremie/%s/%s_%s_%s.png" % [sweet, stem, sweet, cream])
	for path: String in candidates:
		var tex: Texture2D = _get_or_load(path)
		if tex != null:
			return tex
	return null


func _parse_alcremie(token: String) -> Dictionary:
	var rest: String = token.substr("ALCREMIE_".length())
	for s: String in ["STRAWBERRY", "BERRY", "LOVE", "STAR", "CLOVER", "FLOWER", "RIBBON"]:
		if rest.begins_with(s + "_"):
			return {"sweet": s.to_lower(), "cream": rest.substr(s.length() + 1).to_lower()}
	return {}


func _parent_folder(folder: String) -> String:
	var idx: int = folder.rfind("/")
	if idx <= 0:
		return ""
	return folder.substr(0, idx)


func _candidate_paths(folder: String, kind: String, shiny: bool, female: bool) -> PackedStringArray:
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
	for file_name: String in names:
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
