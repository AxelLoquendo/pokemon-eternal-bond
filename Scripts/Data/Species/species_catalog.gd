extends Node
## Autoload SpeciesCatalog — species .tres + formas .tres

const RESOURCES_DIR: String = "res://Datos/Species/Resources/"
const FORMS_DIR: String = "res://Datos/Species/Forms/"

var _by_id: Dictionary = {}   # SpeciesId.Id → SpeciesData
var _forms: Dictionary = {}   # "VENUSAUR|1" → FormData


func _ready() -> void:
	reload()


func reload() -> void:
	_by_id.clear()
	_forms.clear()
	_load_species_tres()
	_load_forms_tres()


func _load_species_tres() -> void:
	var dir: DirAccess = DirAccess.open(RESOURCES_DIR)
	if dir == null:
		push_warning("SpeciesCatalog: falta %s" % RESOURCES_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = load(RESOURCES_DIR.path_join(file_name))
			if res is SpeciesData:
				var data: SpeciesData = res as SpeciesData
				if data.id != SpeciesId.Id.NONE:
					_by_id[data.id] = data
		file_name = dir.get_next()
	dir.list_dir_end()
	print("SpeciesCatalog: %d species (.tres)" % _by_id.size())


func _load_forms_tres() -> void:
	var dir: DirAccess = DirAccess.open(FORMS_DIR)
	if dir == null:
		push_warning("SpeciesCatalog: falta %s (sin formas)" % FORMS_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = load(FORMS_DIR.path_join(file_name))
			if res is FormData:
				var fd: FormData = res as FormData
				if fd.species != SpeciesId.Id.NONE and fd.form > 0:
					_forms[fd.catalog_key()] = fd
		file_name = dir.get_next()
	dir.list_dir_end()
	print("SpeciesCatalog: %d formas (.tres)" % _forms.size())


func get_species(id: SpeciesId.Id) -> SpeciesData:
	return _by_id.get(id) as SpeciesData


func get_form(species: SpeciesId.Id, form: int) -> FormData:
	if form <= 0:
		return null
	var key: String = "%s|%d" % [SpeciesId.to_key(species), form]
	return _forms.get(key) as FormData


func get_form_override(species: SpeciesId.Id, form: int) -> Dictionary:
	## Compat: devuelve un Dictionary como el JSON antiguo.
	var fd: FormData = get_form(species, form)
	if fd == null:
		return {}
	return _form_to_dict(fd)


func has_form(species: SpeciesId.Id, form: int) -> bool:
	if form <= 0:
		return true
	return get_form(species, form) != null


func get_display_name(id: SpeciesId.Id, form: int = 0) -> String:
	if form > 0:
		var fd: FormData = get_form(id, form)
		if fd != null and not fd.form_name.is_empty():
			return fd.form_name
	var d: SpeciesData = get_species(id)
	if d != null and not d.name.is_empty():
		return d.name
	return SpeciesId.to_key(id)


func get_species_resolved(species: SpeciesId.Id, form: int = 0) -> SpeciesData:
	var base: SpeciesData = get_species(species)
	if base == null:
		return null
	if form <= 0:
		return base
	var fd: FormData = get_form(species, form)
	if fd == null:
		return base
	var merged: SpeciesData = base.duplicate(true) as SpeciesData
	_apply_form_data(merged, fd)
	return merged


func _apply_form_data(data: SpeciesData, fd: FormData) -> void:
	if not fd.form_name.is_empty():
		data.form_name = fd.form_name
	if not fd.sprite_folder.is_empty():
		# Carpeta completa para esta forma: base/sufijo (si base ya está en data).
		if not data.sprite_folder.is_empty():
			data.sprite_folder = "%s/%s" % [data.sprite_folder, fd.sprite_folder]
		else:
			data.sprite_folder = fd.sprite_folder
	if fd.base_hp >= 0:
		data.base_hp = fd.base_hp
	if fd.base_atk >= 0:
		data.base_atk = fd.base_atk
	if fd.base_def >= 0:
		data.base_def = fd.base_def
	if fd.base_spe >= 0:
		data.base_spe = fd.base_spe
	if fd.base_spa >= 0:
		data.base_spa = fd.base_spa
	if fd.base_spd >= 0:
		data.base_spd = fd.base_spd
	if fd.base_exp >= 0:
		data.base_exp = fd.base_exp
	if fd.height_m >= 0.0:
		data.height_m = fd.height_m
	if fd.weight_kg >= 0.0:
		data.weight_kg = fd.weight_kg
	if not fd.color.is_empty():
		data.color = fd.color
	if not fd.shape.is_empty():
		data.shape = fd.shape
	if not fd.category.is_empty():
		data.category = fd.category
	if not fd.pokedex.is_empty():
		data.pokedex = fd.pokedex
	if fd.generation >= 0:
		data.generation = fd.generation
	if not fd.gender_ratio.is_empty():
		data.gender_ratio = fd.gender_ratio
	if not fd.types.is_empty():
		data.types = fd.types.duplicate()
	if not fd.abilities.is_empty():
		data.abilities = fd.abilities.duplicate()
	if not fd.hidden_abilities.is_empty():
		data.hidden_abilities = fd.hidden_abilities.duplicate()
	if not fd.level_moves.is_empty():
		data.level_moves = fd.level_moves.duplicate(true)
	if not fd.evolutions.is_empty():
		data.evolutions = fd.evolutions.duplicate(true)
	if not fd.flags.is_empty():
		data.flags = fd.flags.duplicate()


func _form_to_dict(fd: FormData) -> Dictionary:
	## Para código que aún lea overrides como Dictionary.
	var d: Dictionary = {
		"species": SpeciesId.to_key(fd.species),
		"form": fd.form,
		"form_name": fd.form_name,
		"sprite_folder": fd.sprite_folder,
	}
	if fd.base_hp >= 0:
		d["base_hp"] = fd.base_hp
	if fd.base_atk >= 0:
		d["base_atk"] = fd.base_atk
	if fd.base_def >= 0:
		d["base_def"] = fd.base_def
	if fd.base_spe >= 0:
		d["base_spe"] = fd.base_spe
	if fd.base_spa >= 0:
		d["base_spa"] = fd.base_spa
	if fd.base_spd >= 0:
		d["base_spd"] = fd.base_spd
	if fd.base_exp >= 0:
		d["base_exp"] = fd.base_exp
	if fd.height_m >= 0.0:
		d["height_m"] = fd.height_m
	if fd.weight_kg >= 0.0:
		d["weight_kg"] = fd.weight_kg
	if not fd.color.is_empty():
		d["color"] = fd.color
	if not fd.pokedex.is_empty():
		d["pokedex"] = fd.pokedex
	if not fd.mega_stone.is_empty():
		d["mega_stone"] = fd.mega_stone
	if not fd.types.is_empty():
		var types_s: Array = []
		for t: TypeId.Id in fd.types:
			types_s.append(TypeId.to_key(t))
		d["types"] = types_s
	return d
