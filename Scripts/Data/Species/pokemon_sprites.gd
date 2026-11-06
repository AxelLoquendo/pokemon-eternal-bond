extends Node
## Autoload PokemonSprites — resuelve texturas por sprite_folder.

const SPRITES_ROOT: String = "res://Graficos/Pokemon/"

var _cache: Dictionary = {}


func folder_for(species: SpeciesId.Id, form: int = 0) -> String:
	var base: String = ""
	if SpeciesCatalog:
		var data: SpeciesData = SpeciesCatalog.get_species(species)
		if data != null and not data.sprite_folder.is_empty():
			base = data.sprite_folder
	if base.is_empty():
		base = SpeciesId.to_key(species).to_lower()

	if form <= 0:
		return base

	if SpeciesCatalog:
		var over: Dictionary = SpeciesCatalog.get_form_override(species, form)
		var sub: String = str(over.get("sprite_folder", ""))
		if not sub.is_empty():
			return "%s/%s" % [base, sub]
	return base


func get_front(
	species: SpeciesId.Id,
	form: int = 0,
	shiny: bool = false,
	female: bool = false
) -> Texture2D:
	return _load_kind(folder_for(species, form), "front", shiny, female)


func get_back(
	species: SpeciesId.Id,
	form: int = 0,
	shiny: bool = false,
	female: bool = false
) -> Texture2D:
	return _load_kind(folder_for(species, form), "back", shiny, female)


func get_icon(species: SpeciesId.Id, form: int = 0) -> Texture2D:
	return _load_kind(folder_for(species, form), "icon", false, false)


func get_for_pokemon(mon: PokemonInstance, kind: String) -> Texture2D:
	if mon == null:
		return null
	var female: bool = mon.gender == PokemonGender.FEMALE
	match kind:
		"front":
			return get_front(mon.species, mon.form, mon.shiny, female)
		"back":
			return get_back(mon.species, mon.form, mon.shiny, female)
		"icon":
			return get_icon(mon.species, mon.form)
		_:
			return null


func _load_kind(folder: String, kind: String, shiny: bool, female: bool) -> Texture2D:
	for stem: String in _stems(kind, shiny, female):
		var tex: Texture2D = _try_file(folder, stem)
		if tex != null:
			return tex
	if kind == "icon":
		var parent: String = _parent(folder)
		if not parent.is_empty():
			return _try_file(parent, "icon")
	return null


func _stems(kind: String, shiny: bool, female: bool) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if kind == "icon":
		out.append("icon")
		return out
	if female and shiny:
		out.append("%s_female_shiny" % kind)
	if female:
		out.append("%s_female" % kind)
	if shiny:
		out.append("%s_shiny" % kind)
	out.append(kind)
	return out


func _try_file(folder: String, stem: String) -> Texture2D:
	var path: String = SPRITES_ROOT.path_join(folder).path_join("%s.png" % stem)
	if _cache.has(path):
		return _cache[path] as Texture2D
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		_cache[path] = tex
	return tex


func _parent(folder: String) -> String:
	var i: int = folder.rfind("/")
	if i <= 0:
		return ""
	return folder.substr(0, i)
