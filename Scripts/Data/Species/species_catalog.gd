extends Node
## Autoload SpeciesCatalog — species en .tres + overrides de forma (JSON).

const RESOURCES_DIR: String = "res://Datos/Species/Resources/"
const FORMS_PATH: String = "res://Datos/Species/forms.json"

var _by_id: Dictionary = {}  # SpeciesId.Id → SpeciesData
## "VENUSAUR|1" → Dictionary de overrides
var _forms: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	_by_id.clear()
	_forms.clear()
	_load_species_tres()
	_load_forms()


func _load_species_tres() -> void:
	var dir: DirAccess = DirAccess.open(RESOURCES_DIR)
	if dir == null:
		push_warning("SpeciesCatalog: falta carpeta %s" % RESOURCES_DIR)
		return

	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".tres"):
			var path: String = RESOURCES_DIR.path_join(name)
			var res: Resource = load(path)
			if res is SpeciesData:
				var data: SpeciesData = res as SpeciesData
				if data.id != SpeciesId.Id.NONE:
					_by_id[data.id] = data
		name = dir.get_next()
	dir.list_dir_end()
	print("SpeciesCatalog: %d species (.tres)" % _by_id.size())


func _load_forms() -> void:
	if not FileAccess.file_exists(FORMS_PATH):
		push_warning("SpeciesCatalog: falta %s (sin formas)" % FORMS_PATH)
		return
	var f := FileAccess.open(FORMS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_ARRAY:
		return
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var key: String = "%s|%d" % [str(d.get("species", "")), int(d.get("form", 0))]
		_forms[key] = d
	print("SpeciesCatalog: %d formas" % _forms.size())


func get_species(id: SpeciesId.Id) -> SpeciesData:
	return _by_id.get(id) as SpeciesData


func get_display_name(id: SpeciesId.Id, form: int = 0) -> String:
	if form > 0:
		var over: Dictionary = get_form_override(id, form)
		var fn: String = str(over.get("form_name", ""))
		if not fn.is_empty():
			return fn
	var d: SpeciesData = get_species(id)
	if d != null and not d.name.is_empty():
		return d.name
	return SpeciesId.to_key(id)


func get_form_override(species: SpeciesId.Id, form: int) -> Dictionary:
	if form <= 0:
		return {}
	var key: String = "%s|%d" % [SpeciesId.to_key(species), form]
	return _forms.get(key, {}) as Dictionary


func has_form(species: SpeciesId.Id, form: int) -> bool:
	if form <= 0:
		return true
	return not get_form_override(species, form).is_empty()


## Forma 0 = base. Forma >0 = base + overrides (copia).
func get_species_resolved(species: SpeciesId.Id, form: int = 0) -> SpeciesData:
	var base: SpeciesData = get_species(species)
	if base == null:
		return null
	if form <= 0:
		return base
	var over: Dictionary = get_form_override(species, form)
	if over.is_empty():
		return base
	var merged: SpeciesData = base.duplicate(true) as SpeciesData
	_apply_form_override(merged, over)
	return merged


func _apply_form_override(data: SpeciesData, over: Dictionary) -> void:
	if over.has("base_hp"):
		data.base_hp = int(over["base_hp"])
	if over.has("base_atk"):
		data.base_atk = int(over["base_atk"])
	if over.has("base_def"):
		data.base_def = int(over["base_def"])
	if over.has("base_spe"):
		data.base_spe = int(over["base_spe"])
	if over.has("base_spa"):
		data.base_spa = int(over["base_spa"])
	if over.has("base_spd"):
		data.base_spd = int(over["base_spd"])
	if over.has("base_exp"):
		data.base_exp = int(over["base_exp"])
	if over.has("height_m"):
		data.height_m = float(over["height_m"])
	if over.has("weight_kg"):
		data.weight_kg = float(over["weight_kg"])
	if over.has("color"):
		data.color = str(over["color"])
	if over.has("shape"):
		data.shape = str(over["shape"])
	if over.has("category"):
		data.category = str(over["category"])
	if over.has("pokedex"):
		data.pokedex = str(over["pokedex"])
	if over.has("generation"):
		data.generation = int(over["generation"])
	if over.has("form_name"):
		data.form_name = str(over["form_name"])
	if over.has("types"):
		data.types.clear()
		for t: Variant in over["types"]:
			var tid: TypeId.Id = TypeId.from_token(str(t))
			if tid != TypeId.Id.NONE:
				data.types.append(tid)
	if over.has("abilities"):
		data.abilities.clear()
		for a: Variant in over["abilities"]:
			var aid: AbilityId.Id = AbilityId.from_token(str(a))
			if aid != AbilityId.Id.NONE:
				data.abilities.append(aid)
	if over.has("hidden_abilities"):
		data.hidden_abilities.clear()
		for a: Variant in over["hidden_abilities"]:
			var aid2: AbilityId.Id = AbilityId.from_token(str(a))
			if aid2 != AbilityId.Id.NONE:
				data.hidden_abilities.append(aid2)
	if over.has("level_moves"):
		data.level_moves.clear()
		for lm: Variant in over["level_moves"]:
			if lm is Dictionary:
				data.level_moves.append(lm)
	if over.has("evolutions"):
		data.evolutions.clear()
		for e: Variant in over["evolutions"]:
			if e is Dictionary:
				data.evolutions.append(e)
