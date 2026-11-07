extends Node
## Catálogo de especies. Por ahora registra un set de prueba en código.
## Más adelante podrá cargar .tres o JSON generados desde expansion.

var _by_id: Dictionary = {} # SpeciesId.Id -> SpeciesData


func _ready() -> void:
	_register_starter_set()


func get_data(id: SpeciesId.Id) -> SpeciesData:
	return _by_id.get(id) as SpeciesData


func has_species(id: SpeciesId.Id) -> bool:
	return _by_id.has(id)


func all_ids() -> Array:
	return _by_id.keys()


func _register_starter_set() -> void:
	_add(_make(SpeciesId.Id.BULBASAUR, "Bulbasaur", [TypeId.Id.GRASS, TypeId.Id.POISON],
		45, 49, 49, 65, 65, 45, 45, 64))
	_add(_make(SpeciesId.Id.IVYSAUR, "Ivysaur", [TypeId.Id.GRASS, TypeId.Id.POISON],
		60, 62, 63, 80, 80, 60, 45, 142))
	_add(_make(SpeciesId.Id.VENUSAUR, "Venusaur", [TypeId.Id.GRASS, TypeId.Id.POISON],
		80, 82, 83, 100, 100, 80, 45, 263))
	_add(_make(SpeciesId.Id.VENUSAUR_MEGA, "Mega Venusaur", [TypeId.Id.GRASS, TypeId.Id.POISON],
		80, 100, 123, 122, 120, 80, 45, 281))
	_add(_make(SpeciesId.Id.VENUSAUR_GMAX, "Gigantamax Venusaur", [TypeId.Id.GRASS, TypeId.Id.POISON],
		80, 82, 83, 100, 100, 80, 45, 263))

	_add(_make(SpeciesId.Id.CHARMANDER, "Charmander", [TypeId.Id.FIRE],
		39, 52, 43, 60, 50, 65, 45, 62))
	_add(_make(SpeciesId.Id.CHARMELEON, "Charmeleon", [TypeId.Id.FIRE],
		58, 64, 58, 80, 65, 80, 45, 142))
	_add(_make(SpeciesId.Id.CHARIZARD, "Charizard", [TypeId.Id.FIRE, TypeId.Id.FLYING],
		78, 84, 78, 109, 85, 100, 45, 267))
	_add(_make(SpeciesId.Id.CHARIZARD_MEGA_X, "Mega Charizard X", [TypeId.Id.FIRE, TypeId.Id.DRAGON],
		78, 130, 111, 130, 85, 100, 45, 285))
	_add(_make(SpeciesId.Id.CHARIZARD_MEGA_Y, "Mega Charizard Y", [TypeId.Id.FIRE, TypeId.Id.FLYING],
		78, 104, 78, 159, 115, 100, 45, 285))
	_add(_make(SpeciesId.Id.CHARIZARD_GMAX, "Gigantamax Charizard", [TypeId.Id.FIRE, TypeId.Id.FLYING],
		78, 84, 78, 109, 85, 100, 45, 267))

	_add(_make(SpeciesId.Id.PIKACHU, "Pikachu", [TypeId.Id.ELECTRIC],
		35, 55, 40, 50, 50, 90, 190, 112))
	_add(_make(SpeciesId.Id.PIKACHU_HOENN, "Pikachu Hoenn Cap", [TypeId.Id.ELECTRIC],
		35, 55, 40, 50, 50, 90, 190, 112))

	_add(_make(SpeciesId.Id.NIDORAN_F, "Nidoran♀", [TypeId.Id.POISON],
		55, 47, 52, 40, 40, 41, 235, 55))
	_add(_make(SpeciesId.Id.NIDORAN_M, "Nidoran♂", [TypeId.Id.POISON],
		46, 57, 40, 40, 40, 50, 235, 55))
	_add(_make(SpeciesId.Id.WOCHIEN, "Wo-Chien", [TypeId.Id.DARK, TypeId.Id.GRASS],
		85, 85, 100, 95, 135, 70, 3, 285))


func _make(
		id: SpeciesId.Id,
		name: String,
		types: Array,
		hp: int, atk: int, def: int, spa: int, spd: int, spe: int,
		catch_rate: int, base_exp: int
	) -> SpeciesData:
	var data := SpeciesData.new()
	data.id = id
	data.display_name = name
	for t: TypeId.Id in types:
		data.types.append(t as TypeId.Id)
	data.base_hp = hp
	data.base_atk = atk
	data.base_def = def
	data.base_spa = spa
	data.base_spd = spd
	data.base_spe = spe
	data.catch_rate = catch_rate
	data.base_exp = base_exp
	return data


func _add(data: SpeciesData) -> void:
	if data == null or not data.is_valid():
		push_warning("SpeciesCatalog: entrada inválida")
		return
	_by_id[data.id] = data
