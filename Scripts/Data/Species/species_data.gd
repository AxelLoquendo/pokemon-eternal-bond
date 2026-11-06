class_name SpeciesData
extends Resource

@export var id: SpeciesId.Id = SpeciesId.Id.NONE
@export var name: String = ""
@export var types: Array[TypeId.Id] = []
@export var base_hp: int = 1
@export var base_atk: int = 1
@export var base_def: int = 1
@export var base_spe: int = 1
@export var base_spa: int = 1
@export var base_spd: int = 1
@export var catch_rate: int = 45
@export var base_exp: int = 0
@export var base_happiness: int = 50
@export var gender_ratio: String = "Female50Percent"
@export var growth_rate: String = "Medium"
@export var abilities: Array[AbilityId.Id] = []
@export var hidden_abilities: Array[AbilityId.Id] = []
@export var level_moves: Array[Dictionary] = []
@export var tutor_move_tokens: PackedStringArray = PackedStringArray()
@export var egg_move_tokens: PackedStringArray = PackedStringArray()
@export var egg_groups: PackedStringArray = PackedStringArray()
@export var hatch_steps: int = 0
@export var height_m: float = 0.0
@export var weight_kg: float = 0.0
@export var color: String = ""
@export var shape: String = ""
@export var category: String = ""
@export var habitat: String = ""
@export_multiline var pokedex: String = ""
@export var generation: int = 1
@export var evolutions: Array[Dictionary] = []

# EV que otorga al ser derrotado: { "hp", "atk", "def", "spe", "spa", "spd" }
@export var yield_evs: Dictionary = {}
@export var flags: PackedStringArray = PackedStringArray()
@export var wild_item_common: String = ""
@export var wild_item_uncommon: String = ""
@export var wild_item_rare: String = ""
@export var incense: String = ""
@export var offspring: PackedStringArray = PackedStringArray()
@export var form_name: String = ""
@export var sprite_folder: String = ""

static func from_dict(d: Dictionary) -> SpeciesData:
	var data := SpeciesData.new()
	data.id = SpeciesId.from_token(str(d.get("id", "")))
	data.name = str(d.get("name", ""))
	data.base_hp = int(d.get("base_hp", 1))
	data.base_atk = int(d.get("base_atk", 1))
	data.base_def = int(d.get("base_def", 1))
	data.base_spe = int(d.get("base_spe", 1))
	data.base_spa = int(d.get("base_spa", 1))
	data.base_spd = int(d.get("base_spd", 1))
	data.catch_rate = int(d.get("catch_rate", 45))
	data.base_exp = int(d.get("base_exp", 0))
	data.base_happiness = int(d.get("base_happiness", 50))
	data.gender_ratio = str(d.get("gender_ratio", "Female50Percent"))
	data.growth_rate = str(d.get("growth_rate", "Medium"))
	data.hatch_steps = int(d.get("hatch_steps", 0))
	data.height_m = float(d.get("height_m", 0.0))
	data.weight_kg = float(d.get("weight_kg", 0.0))
	data.color = str(d.get("color", ""))
	data.shape = str(d.get("shape", ""))
	data.category = str(d.get("category", ""))
	data.habitat = str(d.get("habitat", ""))
	data.pokedex = str(d.get("pokedex", ""))
	data.generation = int(d.get("generation", 1))
	data.form_name = str(d.get("form_name", ""))
	data.wild_item_common = str(d.get("wild_item_common", ""))
	data.wild_item_uncommon = str(d.get("wild_item_uncommon", ""))
	data.wild_item_rare = str(d.get("wild_item_rare", ""))
	data.incense = str(d.get("incense", ""))
	data.sprite_folder = str(d.get("sprite_folder", ""))

	var evs_raw: Variant = d.get("evs", {})
	if evs_raw is Dictionary:
		data.yield_evs = (evs_raw as Dictionary).duplicate()

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

	for x: Variant in d.get("tutor_moves", []):
		data.tutor_move_tokens.append(str(x))
	for x: Variant in d.get("egg_moves", []):
		data.egg_move_tokens.append(str(x))
	for x: Variant in d.get("egg_groups", []):
		data.egg_groups.append(str(x))
	for x: Variant in d.get("flags", []):
		data.flags.append(str(x))
	for x: Variant in d.get("offspring", []):
		data.offspring.append(str(x))
	for e: Variant in d.get("evolutions", []):
		if e is Dictionary:
			data.evolutions.append(e as Dictionary)

	return data


func get_level_up_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for lm: Dictionary in level_moves:
		out.append({
			"level": int(lm.get("level", 1)),
			"move_id": MoveId.from_token(str(lm.get("move", ""))),
		})
	return out
