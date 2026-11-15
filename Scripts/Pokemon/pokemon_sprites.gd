extends Node
## Resuelve texturas desde Graficos/Pokemon/<carpeta>/.
## Caché por path. Incluye:
##  1) Fallback a carpeta padre (iconos de formas size/segment)
##  2) Overrides de folder (Squawkabilly, Deerling, …)
##  3) Resolver especial Alcremie (sweet + cream)

const ROOT: String = "res://Graficos/Pokemon/"

var _cache: Dictionary = {} # path -> Texture2D

## Corrige mapeos rotos / incompletos de SpeciesId._SPRITE_FOLDER
## sin regenerar species_id.gd entero.
const FOLDER_OVERRIDES: Dictionary = {
	# Squawkabilly — carpetas de color existen
	SpeciesId.Id.SQUAWKABILLY_GREEN: "squawkabilly",
	SpeciesId.Id.SQUAWKABILLY_BLUE: "squawkabilly/blue",
	SpeciesId.Id.SQUAWKABILLY_YELLOW: "squawkabilly/yellow",
	SpeciesId.Id.SQUAWKABILLY_WHITE: "squawkabilly/white",
	# Deerling — seasons
	SpeciesId.Id.DEERLING_SPRING: "deerling",
	SpeciesId.Id.DEERLING_SUMMER: "deerling/summer",
	SpeciesId.Id.DEERLING_AUTUMN: "deerling/autumn",
	SpeciesId.Id.DEERLING_WINTER: "deerling/winter",
	# Sawsbuck (summer/autumn/winter ya estaban bien; spring base)
	SpeciesId.Id.SAWSBUCK_SPRING: "sawsbuck",
	SpeciesId.Id.SAWSBUCK_SUMMER: "sawsbuck/summer",
	SpeciesId.Id.SAWSBUCK_AUTUMN: "sawsbuck/autumn",
	SpeciesId.Id.SAWSBUCK_WINTER: "sawsbuck/winter",
	# Alcremie GMAX (el resto se resuelve por token)
	SpeciesId.Id.ALCREMIE_GMAX: "alcremie/gmax",
	# Base strawberry vanilla no debe ir a gmax
	SpeciesId.Id.ALCREMIE_STRAWBERRY_VANILLA_CREAM: "alcremie",
}


func get_front(id: SpeciesId.Id, shiny: bool = false, female: bool = false) -> Texture2D:
	return _load_kind(id, "front", shiny, female)


func get_back(id: SpeciesId.Id, shiny: bool = false, female: bool = false) -> Texture2D:
	return _load_kind(id, "back", shiny, female)


func get_icon(id: SpeciesId.Id) -> Texture2D:
	return _load_kind(id, "icon", false, false)


func folder_for(id: SpeciesId.Id) -> String:
	## Útil para el sprite test / debug.
	if FOLDER_OVERRIDES.has(id):
		return str(FOLDER_OVERRIDES[id])
	var token: String = SpeciesId.to_token(id)
	if token.begins_with("ALCREMIE_") and token != "ALCREMIE_GMAX":
		var parsed: Dictionary = _parse_alcremie(token)
		if not parsed.is_empty():
			return str(parsed.get("folder", "alcremie"))
	return SpeciesId.sprite_folder(id)


func _load_kind(id: SpeciesId.Id, kind: String, shiny: bool, female: bool) -> Texture2D:
	# --- Alcremie: paths compuestos ---
	var token: String = SpeciesId.to_token(id)
	if token.begins_with("ALCREMIE_") and id != SpeciesId.Id.ALCREMIE_GMAX:
		var tex_a: Texture2D = _load_alcremie(token, kind, shiny)
		if tex_a != null:
			return tex_a
		# si falla, sigue con folder genérico

	var folder: String = folder_for(id)
	if folder.is_empty():
		return null

	for path in _candidate_paths(folder, kind, shiny, female):
		var tex: Texture2D = _get_or_load(path)
		if tex != null:
			return tex

	# Fallback carpeta padre (p.ej. pumpkaboo/super → pumpkaboo)
	var parent: String = _parent_folder(folder)
	if not parent.is_empty():
		for path2 in _candidate_paths(parent, kind, shiny, female):
			var tex2: Texture2D = _get_or_load(path2)
			if tex2 != null:
				return tex2

	return null


# ---------------------------------------------------------------------------
# Alcremie
# Token: ALCREMIE_<SWEET>_<CREAM>
#   SWEET: STRAWBERRY | BERRY | LOVE | STAR | CLOVER | FLOWER | RIBBON
#   CREAM: VANILLA_CREAM | RUBY_CREAM | MATCHA_CREAM | MINT_CREAM |
#          LEMON_CREAM | SALTED_CREAM | RUBY_SWIRL | CARAMEL_SWIRL | RAINBOW_SWIRL
#
# Archivos del pack:
#   strawberry + vanilla  → alcremie/front.png
#   strawberry + other    → alcremie/<cream>/front.png  (si existe)
#   other sweet + cream   → alcremie/<sweet>/front_<sweet>_<cream>.png
#   fallback              → alcremie/<sweet>/front.png  o  alcremie/front.png
# ---------------------------------------------------------------------------

func _parse_alcremie(token: String) -> Dictionary:
	# Quita prefijo ALCREMIE_
	var rest: String = token.substr("ALCREMIE_".length())
	var sweets: PackedStringArray = PackedStringArray([
		"STRAWBERRY", "BERRY", "LOVE", "STAR", "CLOVER", "FLOWER", "RIBBON"
	])
	var sweet: String = ""
	var cream: String = ""
	for s: String in sweets:
		if rest.begins_with(s + "_"):
			sweet = s
			cream = rest.substr(s.length() + 1)
			break
	if sweet.is_empty() or cream.is_empty():
		return {}
	var sweet_l: String = sweet.to_lower()
	var cream_l: String = cream.to_lower()
	var folder: String = "alcremie"
	if sweet_l != "strawberry":
		folder = "alcremie/" + sweet_l
	elif cream_l != "vanilla_cream":
		folder = "alcremie/" + cream_l
	return {
		"sweet": sweet_l,
		"cream": cream_l,
		"folder": folder,
	}


func _load_alcremie(token: String, kind: String, shiny: bool) -> Texture2D:
	var parsed: Dictionary = _parse_alcremie(token)
	if parsed.is_empty():
		return null
	var sweet: String = str(parsed["sweet"])
	var cream: String = str(parsed["cream"])
	var folder: String = str(parsed["folder"])

	var candidates: PackedStringArray = PackedStringArray()

	if kind == "icon":
		# Casi nunca hay icon por crema; padre alcremie/icon.png
		candidates.append(ROOT + folder + "/icon.png")
		candidates.append(ROOT + "alcremie/icon.png")
	else:
		var base: String = kind
		var shiny_suf: String = "_shiny" if shiny else ""
		if sweet == "strawberry":
			if cream == "vanilla_cream":
				candidates.append(ROOT + "alcremie/%s%s.png" % [base, shiny_suf])
				candidates.append(ROOT + "alcremie/%s.png" % base)
			else:
				# alcremie/lemon_cream/front.png
				candidates.append(ROOT + "alcremie/%s/%s%s.png" % [cream, base, shiny_suf])
				candidates.append(ROOT + "alcremie/%s/%s.png" % [cream, base])
				candidates.append(ROOT + "alcremie/%s%s.png" % [base, shiny_suf])
				candidates.append(ROOT + "alcremie/%s.png" % base)
		else:
			# alcremie/berry/front_berry_lemon_cream.png
			candidates.append(ROOT + "alcremie/%s/%s_%s_%s%s.png" % [sweet, base, sweet, cream, shiny_suf])
			candidates.append(ROOT + "alcremie/%s/%s_%s_%s.png" % [sweet, base, sweet, cream])
			# genérico del sweet
			candidates.append(ROOT + "alcremie/%s/%s%s.png" % [sweet, base, shiny_suf])
			candidates.append(ROOT + "alcremie/%s/%s.png" % [sweet, base])
			# raíz
			candidates.append(ROOT + "alcremie/%s%s.png" % [base, shiny_suf])
			candidates.append(ROOT + "alcremie/%s.png" % base)

	for path: String in candidates:
		var tex: Texture2D = _get_or_load(path)
		if tex != null:
			return tex
	return null


# ---------------------------------------------------------------------------
# Paths genéricos
# ---------------------------------------------------------------------------

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


func clear_cache() -> void:
	_cache.clear()
