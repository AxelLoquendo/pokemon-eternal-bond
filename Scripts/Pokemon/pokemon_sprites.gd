extends Node
## Resuelve texturas desde Graficos/Pokemon/.
## Carpeta: FOLDER_OVERRIDES → derivación por token+disco → mapa SpeciesId.

const ROOT: String = "res://Graficos/Pokemon/"

const FORM_ALIASES: Dictionary = {
	"pokeball": "poke_ball",
	"poke_ball": "poke_ball",
}

## Correcciones manuales (las que marcaste en species.json).
const FOLDER_OVERRIDES: Dictionary = {
	SpeciesId.Id.GENESECT_BURN: "genesect/burn_drive",
	SpeciesId.Id.GENESECT_CHILL: "genesect/chill_drive",
	SpeciesId.Id.GENESECT_DOUSE: "genesect/douse_drive",
	SpeciesId.Id.GENESECT_SHOCK: "genesect/shock_drive",
	SpeciesId.Id.MEOWSTIC_F_MEGA: "meowstic/mega",
	SpeciesId.Id.MEOWSTIC_M_MEGA: "meowstic/mega",
	SpeciesId.Id.ZYGARDE_10_AURA_BREAK: "zygarde/10_percent",
	SpeciesId.Id.ZYGARDE_10_POWER_CONSTRUCT: "zygarde/10_percent",
	SpeciesId.Id.MINIOR_CORE_BLUE: "minior/core/blue",
	SpeciesId.Id.MINIOR_CORE_GREEN: "minior/core/green",
	SpeciesId.Id.MINIOR_CORE_INDIGO: "minior/core/indigo",
	SpeciesId.Id.MINIOR_CORE_ORANGE: "minior/core/orange",
	SpeciesId.Id.MINIOR_CORE_RED: "minior/core/red",
	SpeciesId.Id.MINIOR_CORE_VIOLET: "minior/core/violet",
	SpeciesId.Id.MINIOR_CORE_YELLOW: "minior/core/yellow",
	SpeciesId.Id.MAGEARNA_ORIGINAL: "magearna/original_color",
	SpeciesId.Id.MAGEARNA_ORIGINAL_MEGA: "magearna/original_color/mega",
	SpeciesId.Id.TOXTRICITY_AMPED_GMAX: "toxtricity/gmax",
	SpeciesId.Id.TOXTRICITY_LOW_KEY_GMAX: "toxtricity/gmax",
	SpeciesId.Id.ZACIAN_CROWNED: "zacian/crowned_sword",
	SpeciesId.Id.ZAMAZENTA_CROWNED: "zamazenta/crowned_shield",
	SpeciesId.Id.TATSUGIRI_CURLY_MEGA: "tatsugiri/mega",
	SpeciesId.Id.TATSUGIRI_DROOPY_MEGA: "tatsugiri/droopy/mega",
	SpeciesId.Id.TATSUGIRI_STRETCHY_MEGA: "tatsugiri/stretchy/mega",
}

var _cache: Dictionary = {}
var _folder_cache: Dictionary = {}


func get_front(id: SpeciesId.Id, shiny: bool = false, female: bool = false) -> Texture2D:
	return _load_kind(id, "front", shiny, female)


func get_back(id: SpeciesId.Id, shiny: bool = false, female: bool = false) -> Texture2D:
	return _load_kind(id, "back", shiny, female)


func get_icon(id: SpeciesId.Id) -> Texture2D:
	return _load_kind(id, "icon", false, false)


func folder_for(id: SpeciesId.Id) -> String:
	if id == SpeciesId.Id.NONE:
		return ""
	if _folder_cache.has(id):
		return str(_folder_cache[id])
	var folder: String = _resolve_folder(id)
	_folder_cache[id] = folder
	return folder


func clear_cache() -> void:
	_cache.clear()
	_folder_cache.clear()


func _load_kind(id: SpeciesId.Id, kind: String, shiny: bool, female: bool) -> Texture2D:
	var token: String = SpeciesId.to_token(id)
	if token.begins_with("ALCREMIE_"):
		var tex_a: Texture2D = _load_alcremie(token, kind, shiny)
		if tex_a != null:
			return tex_a

	var folder: String = folder_for(id)
	if folder.is_empty():
		return null

	for path in _candidate_paths(folder, kind, shiny, female):
		var tex: Texture2D = _get_or_load(path)
		if tex != null:
			return tex

	var parent: String = _parent_folder(folder)
	if not parent.is_empty():
		for path2 in _candidate_paths(parent, kind, shiny, female):
			var tex2: Texture2D = _get_or_load(path2)
			if tex2 != null:
				return tex2
	return null


func _resolve_folder(id: SpeciesId.Id) -> String:
	if FOLDER_OVERRIDES.has(id):
		return str(FOLDER_OVERRIDES[id])

	var token: String = SpeciesId.to_token(id)
	if token.begins_with("ALCREMIE_"):
		return _alcremie_folder(token)

	var derived: String = _derive_folder_from_token(token)
	if not derived.is_empty():
		return derived

	var mapped: String = SpeciesId.sprite_folder(id)
	if _has_front(mapped):
		return mapped
	var parent: String = _parent_folder(mapped)
	if _has_front(parent):
		return parent
	return mapped if not mapped.is_empty() else ""


func _derive_folder_from_token(token: String) -> String:
	var parts: PackedStringArray = token.to_lower().split("_")
	if parts.is_empty():
		return ""
	for i: int in range(1, parts.size()):
		var base: String = "_".join(parts.slice(0, i))
		var form: String = "_".join(parts.slice(i, parts.size()))
		for form_try: String in _form_candidates(form, parts, i):
			var folder: String = base + "/" + form_try
			if _has_front(folder):
				return folder
	for i: int in range(parts.size(), 0, -1):
		var base2: String = "_".join(parts.slice(0, i))
		if _has_front(base2):
			return base2
	return ""


func _form_candidates(form: String, parts: PackedStringArray, form_start: int) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	out.append(form)
	if FORM_ALIASES.has(form):
		out.append(str(FORM_ALIASES[form]))
	if form_start < parts.size() and parts[form_start] != form:
		out.append(parts[form_start])
	return out


func _alcremie_folder(token: String) -> String:
	if token == "ALCREMIE_GMAX":
		return "alcremie/gmax" if _has_front("alcremie/gmax") else "alcremie"
	var parsed: Dictionary = _parse_alcremie(token)
	if parsed.is_empty():
		return "alcremie"
	for path: String in _alcremie_rel_paths(str(parsed["sweet"]), str(parsed["cream"]), "front", false):
		if _path_exists(path):
			return path.get_base_dir()
	return "alcremie"


func _parse_alcremie(token: String) -> Dictionary:
	var rest: String = token.substr("ALCREMIE_".length())
	for s: String in ["STRAWBERRY", "BERRY", "LOVE", "STAR", "CLOVER", "FLOWER", "RIBBON"]:
		if rest.begins_with(s + "_"):
			return {"sweet": s.to_lower(), "cream": rest.substr(s.length() + 1).to_lower()}
	return {}


func _alcremie_rel_paths(sweet: String, cream: String, kind: String, shiny: bool) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if kind == "icon":
		out.append("alcremie/%s/icon.png" % sweet)
		out.append("alcremie/icon.png")
		return out
	var shiny_suf: String = "_shiny" if shiny else ""
	var stem: String = kind
	if sweet == "strawberry" and cream == "vanilla_cream":
		out.append("alcremie/%s%s.png" % [stem, shiny_suf])
		out.append("alcremie/%s.png" % stem)
	elif sweet == "strawberry":
		out.append("alcremie/strawberry/%s_strawberry_%s.png" % [stem, cream])
		out.append("alcremie/%s.png" % stem)
	else:
		out.append("alcremie/%s/%s_%s_%s.png" % [sweet, stem, sweet, cream])
		out.append("alcremie/%s/%s%s.png" % [sweet, stem, shiny_suf])
		out.append("alcremie/%s/%s.png" % [sweet, stem])
		out.append("alcremie/%s.png" % stem)
	return out


func _load_alcremie(token: String, kind: String, shiny: bool) -> Texture2D:
	if token == "ALCREMIE_GMAX":
		for path: String in _candidate_paths("alcremie/gmax", kind, shiny, false):
			var t: Texture2D = _get_or_load(path)
			if t != null:
				return t
		return null
	var parsed: Dictionary = _parse_alcremie(token)
	if parsed.is_empty():
		return null
	for rel: String in _alcremie_rel_paths(str(parsed["sweet"]), str(parsed["cream"]), kind, shiny):
		var tex: Texture2D = _get_or_load(ROOT + rel)
		if tex != null:
			return tex
	if kind == "icon":
		return _get_or_load(ROOT + "alcremie/icon.png")
	return null


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


func _path_exists(rel: String) -> bool:
	return ResourceLoader.exists(ROOT + rel)


func _has_front(folder: String) -> bool:
	return not folder.is_empty() and _path_exists(folder + "/front.png")
