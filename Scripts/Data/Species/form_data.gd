class_name FormData
extends Resource
## Overrides de una forma. Solo rellena lo que cambia respecto a la species base.
## Campos numéricos en -1 = “no override”. Arrays vacíos = “no override”.

@export var species: SpeciesId.Id = SpeciesId.Id.NONE
@export var form: int = 1
@export var form_name: String = ""
## Sufijo bajo Graficos/Pokemon/{base}/  (ej. "mega", "alola", "fire")
@export var sprite_folder: String = ""

@export var types: Array[TypeId.Id] = []
@export var base_hp: int = -1
@export var base_atk: int = -1
@export var base_def: int = -1
@export var base_spe: int = -1
@export var base_spa: int = -1
@export var base_spd: int = -1
@export var base_exp: int = -1
@export var height_m: float = -1.0
@export var weight_kg: float = -1.0
@export var color: String = ""
@export var shape: String = ""
@export var category: String = ""
@export_multiline var pokedex: String = ""
@export var generation: int = -1
@export var gender_ratio: String = ""
@export var abilities: Array[AbilityId.Id] = []
@export var hidden_abilities: Array[AbilityId.Id] = []
@export var level_moves: Array[Dictionary] = []
@export var evolutions: Array[Dictionary] = []
@export var mega_stone: String = ""
@export var flags: PackedStringArray = PackedStringArray()


static func from_dict(d: Dictionary) -> FormData:
	var data := FormData.new()
	data.species = SpeciesId.from_token(str(d.get("species", "")))
	data.form = int(d.get("form", 1))
	data.form_name = str(d.get("form_name", ""))
	data.sprite_folder = str(d.get("sprite_folder", ""))
	data.color = str(d.get("color", ""))
	data.shape = str(d.get("shape", ""))
	data.category = str(d.get("category", ""))
	data.pokedex = str(d.get("pokedex", ""))
	data.gender_ratio = str(d.get("gender_ratio", ""))
	data.mega_stone = str(d.get("mega_stone", ""))

	if d.has("base_hp"):
		data.base_hp = int(d["base_hp"])
	if d.has("base_atk"):
		data.base_atk = int(d["base_atk"])
	if d.has("base_def"):
		data.base_def = int(d["base_def"])
	if d.has("base_spe"):
		data.base_spe = int(d["base_spe"])
	if d.has("base_spa"):
		data.base_spa = int(d["base_spa"])
	if d.has("base_spd"):
		data.base_spd = int(d["base_spd"])
	if d.has("base_exp"):
		data.base_exp = int(d["base_exp"])
	if d.has("height_m"):
		data.height_m = float(d["height_m"])
	if d.has("weight_kg"):
		data.weight_kg = float(d["weight_kg"])
	if d.has("generation"):
		data.generation = int(d["generation"])

	for t: Variant in d.get("types", []):
		var tid: TypeId.Id = TypeId.from_token(str(t))
		if tid != TypeId.Id.NONE:
			data.types.append(tid)

	for a: Variant in d.get("abilities", []):
		var aid: AbilityId.Id = AbilityId.from_token(str(a))
		if aid != AbilityId.Id.NONE:
			data.abilities.append(aid)

	for a: Variant in d.get("hidden_abilities", []):
		var hid: AbilityId.Id = AbilityId.from_token(str(a))
		if hid != AbilityId.Id.NONE:
			data.hidden_abilities.append(hid)

	for lm: Variant in d.get("level_moves", []):
		if lm is Dictionary:
			data.level_moves.append(lm)

	for e: Variant in d.get("evolutions", []):
		if e is Dictionary:
			data.evolutions.append(e)

	for x: Variant in d.get("flags", []):
		data.flags.append(str(x))

	return data


## Clave estable para el diccionario del catálogo.
func catalog_key() -> String:
	return "%s|%d" % [SpeciesId.to_key(species), form]
