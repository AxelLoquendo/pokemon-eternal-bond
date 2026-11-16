extends Node
## Resuelve texturas desde Graficos/Pokemon/.
##
## NO confía ciegamente en SpeciesId._SPRITE_FOLDER (está incompleto y
## a veces apunta a otra especie). Orden:
##   1) Resolver por token contra carpetas que existen en disco
##   2) Casos especiales (Alcremie sweet+cream, alias poke_ball)
##   3) Fallback al mapa de SpeciesId
##   4) Carpeta padre (iconos de formas size/segment)
##
## Caché por path. No precarga el pack entero.

const ROOT: String = "res://Graficos/Pokemon/"

## Sufijos de forma cuyo nombre de carpeta no coincide 1:1 con el token.
const FORM_ALIASES: Dictionary = {
	"pokeball": "poke_ball",
	"poke_ball": "poke_ball",
}

var _cache: Dictionary = {} # path -> Texture2D
var _folder_cache: Dictionary = {} # SpeciesId.Id -> String folder


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
	var token: String = SpeciesId.to_token(id)
	var folder: String = _resolve_folder(token)
	_folder_cache[id] = folder
	return folder


func clear_cache() -> void:
	_cache.clear()
	_folder_cache.clear()


# ---------------------------------------------------------------------------
# Carga
# ---------------------------------------------------------------------------

func _load_kind(id: SpeciesId.Id, kind: String, shiny: bool, female: bool) -> Texture2D:
	var token: String = SpeciesId.to_token(id)

	# Alcremie: archivos compuestos front_berry_lemon_cream.png, etc.
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

	# Icon / missing form art → carpeta padre
	var parent: String = _parent_folder(folder)
	if not parent.is_empty():
		for path2 in _candidate_paths(parent, kind, shiny, female):
			var tex2: Texture2D = _get_or_load(path2)
			if tex2 != null:
				return tex2

	return null


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


func _parent_folder(folder: String) -> String:
	var idx: int = folder.rfind("/")
	if idx <= 0:
		return ""
	return folder.substr(0, idx)


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
	## rel relativo a ROOT, p.ej. "scatterbug/front.png"
	return ResourceLoader.exists(ROOT + rel)


func _has_front(folder: String) -> bool:
	if folder.is_empty():
		return false
	return _path_exists(folder + "/front.png")


# ---------------------------------------------------------------------------
# Resolver de carpeta por token (fuente de verdad = disco)
# ---------------------------------------------------------------------------

func _resolve_folder(token: String) -> String:
	if token.is_empty():
		return ""

	if token.begins_with("ALCREMIE_"):
		return _alcremie_folder(token)

	var parts: PackedStringArray = token.to_lower().split("_")
	if parts.is_empty():
		return ""

	# 1) Forma más específica: base/form si existe front.png
	#    i=1 → base corta, form largo (squawkabilly/blue, vivillon/high_plains)
	for i: int in range(1, parts.size()):
		var base: String = "_".join(parts.slice(0, i))
		var form: String = "_".join(parts.slice(i, parts.size()))
		for form_try: String in _form_candidates(form, parts, i):
			var folder: String = base + "/" + form_try
			if _has_front(folder):
				return folder

	# 2) Carpeta base, de la más larga a la más corta
	#    (mr_mime_galar ya se resolvió arriba; nidoran_f, ho_oh, type_null…)
	for i: int in range(parts.size(), 0, -1):
		var base2: String = "_".join(parts.slice(0, i))
		if _has_front(base2):
			return base2

	# 3) Último recurso: mapa de SpeciesId (puede estar mal; solo si hay front)
	var mapped: String = SpeciesId.sprite_folder(SpeciesId.from_token(token))
	if _has_front(mapped):
		return mapped
	var parent: String = _parent_folder(mapped)
	if _has_front(parent):
		return parent

	return ""


func _form_candidates(form: String, parts: PackedStringArray, form_start: int) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	out.append(form)
	if FORM_ALIASES.has(form):
		out.append(str(FORM_ALIASES[form]))
	# MINIOR_CORE_RED → minior/core (primera palabra de la forma)
	if form_start < parts.size() and parts[form_start] != form:
		out.append(parts[form_start])
	return out


# ---------------------------------------------------------------------------
# Alcremie
# ---------------------------------------------------------------------------

func _alcremie_folder(token: String) -> String:
	if token == "ALCREMIE_GMAX":
		if _has_front("alcremie/gmax"):
			return "alcremie/gmax"
		return "alcremie"
	var parsed: Dictionary = _parse_alcremie(token)
	if parsed.is_empty():
		return "alcremie"
	var sweet: String = str(parsed["sweet"])
	var cream: String = str(parsed["cream"])
	# Preferir carpeta donde está el PNG específico
	for path: String in _alcremie_rel_paths(sweet, cream, "front", false):
		if _path_exists(path):
			return path.get_base_dir()
	return "alcremie"


func _parse_alcremie(token: String) -> Dictionary:
	var rest: String = token.substr("ALCREMIE_".length())
	var sweets: PackedStringArray = PackedStringArray([
		"STRAWBERRY", "BERRY", "LOVE", "STAR", "CLOVER", "FLOWER", "RIBBON"
	])
	for s: String in sweets:
		if rest.begins_with(s + "_"):
			return {
				"sweet": s.to_lower(),
				"cream": rest.substr(s.length() + 1).to_lower(),
			}
	return {}


func _alcremie_rel_paths(sweet: String, cream: String, kind: String, shiny: bool) -> PackedStringArray:
	## kind: front | back | icon
	var out: PackedStringArray = PackedStringArray()
	if kind == "icon":
		out.append("alcremie/%s/icon.png" % sweet)
		out.append("alcremie/icon.png")
		return out

	var shiny_suf: String = "_shiny" if shiny else ""
	var stem: String = kind # front / back

	if sweet == "strawberry" and cream == "vanilla_cream":
		out.append("alcremie/%s%s.png" % [stem, shiny_suf])
		out.append("alcremie/%s.png" % stem)
	elif sweet == "strawberry":
		# Pack real: alcremie/strawberry/front_strawberry_ruby_cream.png
		out.append("alcremie/strawberry/%s_strawberry_%s.png" % [stem, cream])
		if shiny:
			out.append("alcremie/strawberry/%s_shiny.png" % stem)
		out.append("alcremie/%s/%s%s.png" % [cream, stem, shiny_suf])
		out.append("alcremie/%s/%s.png" % [cream, stem])
		out.append("alcremie/%s%s.png" % [stem, shiny_suf])
		out.append("alcremie/%s.png" % stem)
	else:
		# alcremie/berry/front_berry_lemon_cream.png
		out.append("alcremie/%s/%s_%s_%s.png" % [sweet, stem, sweet, cream])
		if cream == "vanilla_cream":
			out.append("alcremie/%s/%s%s.png" % [sweet, stem, shiny_suf])
			out.append("alcremie/%s/%s.png" % [sweet, stem])
		else:
			out.append("alcremie/%s/%s%s.png" % [sweet, stem, shiny_suf])
			out.append("alcremie/%s/%s.png" % [sweet, stem])
		out.append("alcremie/%s%s.png" % [stem, shiny_suf])
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
	var sweet: String = str(parsed["sweet"])
	var cream: String = str(parsed["cream"])

	for rel: String in _alcremie_rel_paths(sweet, cream, kind, shiny):
		var tex: Texture2D = _get_or_load(ROOT + rel)
		if tex != null:
			return tex
	# Icon sin crema
	if kind == "icon":
		return _get_or_load(ROOT + "alcremie/icon.png")
	return null
