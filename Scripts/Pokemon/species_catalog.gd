extends Node
## Catálogo de especies optimizado para poca RAM.
## - El JSON se indexa una vez (diccionarios crudos), no crea SpeciesData al arrancar.
## - SpeciesData se materializa solo al pedir get_data() y se cachea.
## - La indexación de species (el archivo grande) corre en hilo de fondo.

const PATH: String = "res://Datos/Pokemon/species.json"

## SpeciesId.Id -> Dictionary (entrada JSON sin convertir)
var _raw: Dictionary = {}
## SpeciesId.Id -> SpeciesData (solo los usados)
var _cache: Dictionary = {}
## Lista de ids válidos (para Pokédex / iteración ligera)
var _ids: Array = []
var _loaded: bool = false
var _loading: bool = false


func _ready() -> void:
	# No bloquea el primer frame del título / boot.
	call_deferred("warm_index")


## Arranca la indexación si aún no está. Seguro llamar varias veces.
func warm_index() -> void:
	if _loaded or _loading:
		return
	_loading = true
	WorkerThreadPool.add_task(_thread_build_index, true)


func is_ready() -> bool:
	return _loaded


func count() -> int:
	_wait_ready()
	return _ids.size()


func all_ids() -> Array:
	_wait_ready()
	return _ids.duplicate()


func has_species(id: SpeciesId.Id) -> bool:
	if id == SpeciesId.Id.NONE:
		return false
	if _cache.has(id):
		return true
	_wait_ready()
	return _raw.has(id) or _cache.has(id)


func get_data(id: SpeciesId.Id) -> SpeciesData:
	if id == SpeciesId.Id.NONE:
		return null
	if _cache.has(id):
		return _cache[id] as SpeciesData
	_wait_ready()
	if not _raw.has(id):
		return null
	var data: SpeciesData = _from_dict(_raw[id] as Dictionary)
	# Liberar el dict crudo: ya no hace falta duplicar en RAM.
	_raw.erase(id)
	if data != null and data.is_valid():
		_cache[id] = data
		return data
	return null


## Nombre sin materializar SpeciesData (listas, mensajes, Pokédex).
func get_display_name(id: SpeciesId.Id) -> String:
	if id == SpeciesId.Id.NONE:
		return ""
	if _cache.has(id):
		return (_cache[id] as SpeciesData).display_name
	_wait_ready()
	if _raw.has(id):
		var n: String = str((_raw[id] as Dictionary).get("display_name", ""))
		if not n.is_empty():
			return n
	return SpeciesId.to_token(id)


func get_national_dex(id: SpeciesId.Id) -> int:
	if id == SpeciesId.Id.NONE:
		return 0
	if _cache.has(id):
		return (_cache[id] as SpeciesData).national_dex
	_wait_ready()
	if _raw.has(id):
		return int((_raw[id] as Dictionary).get("national_dex", 0))
	return 0


## Libera SpeciesData cacheados (p. ej. al volver al título). El índice crudo se mantiene.
func clear_cache() -> void:
	_cache.clear()


## Vuelve a cargar desde disco (debug / hot-reload de JSON).
func reload() -> void:
	_cache.clear()
	_raw.clear()
	_ids.clear()
	_loaded = false
	_loading = false
	warm_index()


func _wait_ready() -> void:
	if _loaded:
		return
	if not _loading:
		# Nadie indexando: hacerlo ya en este hilo.
		_build_index_from_file()
		return
	# Hilo en curso: esperar un poco; si no termina, fallback síncrono.
	var spins: int = 0
	while _loading and not _loaded and spins < 3000:
		OS.delay_msec(1)
		spins += 1
	if not _loaded:
		_build_index_from_file()


func _thread_build_index() -> void:
	var raw: Dictionary = {}
	var ids: Array = []
	var err: String = _parse_file_into(raw, ids)
	call_deferred("_apply_index", raw, ids, err)


func _apply_index(raw: Dictionary, ids: Array, err: String) -> void:
	if not err.is_empty():
		push_error("SpeciesCatalog: %s" % err)
	_raw = raw
	_ids = ids
	_loaded = true
	_loading = false
	print("SpeciesCatalog: índice %d especies (lazy SpeciesData)" % _ids.size())


func _build_index_from_file() -> void:
	var raw: Dictionary = {}
	var ids: Array = []
	var err: String = _parse_file_into(raw, ids)
	if not err.is_empty():
		push_error("SpeciesCatalog: %s" % err)
	_raw = raw
	_ids = ids
	_loaded = true
	_loading = false
	print("SpeciesCatalog: índice %d especies (sync)" % _ids.size())


func _parse_file_into(raw: Dictionary, ids: Array) -> String:
	if not FileAccess.file_exists(PATH):
		return "no existe %s" % PATH
	var text: String = FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(text)
	text = "" # ayudar al GC
	if typeof(parsed) != TYPE_ARRAY:
		return "JSON inválido"
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry
		var token: String = str(d.get("id", ""))
		var sid: SpeciesId.Id = SpeciesId.from_token(token)
		if sid == SpeciesId.Id.NONE:
			continue
		raw[sid] = d
		ids.append(sid)
	return ""


func _from_dict(e: Dictionary) -> SpeciesData:
	var id: SpeciesId.Id = SpeciesId.from_token(str(e.get("id", "")))
	if id == SpeciesId.Id.NONE:
		return null
	var data := SpeciesData.new()
	data.id = id
	data.display_name = str(e.get("display_name", ""))
	data.category = str(e.get("category", ""))
	data.national_dex = int(e.get("national_dex", 0))
	data.pokedex = str(e.get("pokedex", ""))

	data.types.clear()
	for t: Variant in e.get("types", []):
		var tid: TypeId.Id = TypeId.from_token(str(t))
		if tid != TypeId.Id.NONE:
			data.types.append(tid)
	data.force_tera_type = TypeId.from_token(str(e.get("force_tera_type", "NONE")))

	data.base_hp = int(e.get("base_hp", 1))
	data.base_atk = int(e.get("base_atk", 1))
	data.base_def = int(e.get("base_def", 1))
	data.base_spa = int(e.get("base_spa", 1))
	data.base_spd = int(e.get("base_spd", 1))
	data.base_spe = int(e.get("base_spe", 1))

	data.ev_hp = int(e.get("ev_hp", 0))
	data.ev_atk = int(e.get("ev_atk", 0))
	data.ev_def = int(e.get("ev_def", 0))
	data.ev_spa = int(e.get("ev_spa", 0))
	data.ev_spd = int(e.get("ev_spd", 0))
	data.ev_spe = int(e.get("ev_spe", 0))

	data.catch_rate = int(e.get("catch_rate", 45))
	data.base_exp = int(e.get("base_exp", 0))
	data.base_friendship = int(e.get("base_friendship", 50))
	data.gender_ratio = int(e.get("gender_ratio", 127))
	data.growth_rate = _growth(str(e.get("growth_rate", "MEDIUM_FAST")))
	data.egg_cycles = int(e.get("egg_cycles", 20))

	data.egg_groups.clear()
	for g: Variant in e.get("egg_groups", []):
		data.egg_groups.append(_egg_group(str(g)))

	data.abilities.clear()
	for a: Variant in e.get("abilities", []):
		data.abilities.append(AbilityId.from_token(str(a)))
	while data.abilities.size() < SpeciesData.ABILITY_SLOTS:
		data.abilities.append(AbilityId.Id.NONE)

	data.item_common = ItemId.from_token(str(e.get("item_common", "")))
	data.item_rare = ItemId.from_token(str(e.get("item_rare", "")))

	data.height_dm = int(e.get("height_dm", 0))
	data.weight_hg = int(e.get("weight_hg", 0))
	data.body_color = _body_color(str(e.get("body_color", "RED")))
	data.no_flip = bool(e.get("no_flip", false))
	data.perfect_iv_count = int(e.get("perfect_iv_count", 0))
	data.cannot_be_traded = bool(e.get("cannot_be_traded", false))

	data.is_restricted_legendary = bool(e.get("is_restricted_legendary", false))
	data.is_sub_legendary = bool(e.get("is_sub_legendary", false))
	data.is_mythical = bool(e.get("is_mythical", false))
	data.is_ultra_beast = bool(e.get("is_ultra_beast", false))
	data.is_paradox = bool(e.get("is_paradox", false))
	data.is_totem = bool(e.get("is_totem", false))
	data.is_mega = bool(e.get("is_mega", false))
	data.is_primal = bool(e.get("is_primal", false))
	data.is_ultra_burst = bool(e.get("is_ultra_burst", false))
	data.is_gigantamax = bool(e.get("is_gigantamax", false))
	data.is_tera_form = bool(e.get("is_tera_form", false))
	data.is_alolan = bool(e.get("is_alolan", false))
	data.is_galarian = bool(e.get("is_galarian", false))
	data.is_hisuian = bool(e.get("is_hisuian", false))
	data.is_paldean = bool(e.get("is_paldean", false))

	data.level_moves.clear()
	for m: Variant in e.get("level_moves", []):
		if typeof(m) != TYPE_DICTIONARY:
			continue
		var md: Dictionary = m
		data.level_moves.append({
			"level": int(md.get("level", 1)),
			"move": MoveId.from_token(str(md.get("move", ""))),
		})

	data.tutor_moves.clear()
	for m: Variant in e.get("tutor_moves", []):
		var mid: MoveId.Id = MoveId.from_token(str(m))
		if mid != MoveId.Id.NONE:
			data.tutor_moves.append(mid)

	data.egg_moves.clear()
	for m: Variant in e.get("egg_moves", []):
		var mid: MoveId.Id = MoveId.from_token(str(m))
		if mid != MoveId.Id.NONE:
			data.egg_moves.append(mid)

	data.evolutions.clear()
	for raw: Variant in e.get("evolutions", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var ed: Dictionary = raw
		var evo := EvolutionData.new()
		evo.method = str(ed.get("method", ""))
		evo.param = str(ed.get("param", ""))
		evo.target = SpeciesId.from_token(str(ed.get("target", "")))
		data.evolutions.append(evo)

	data.form_species.clear()
	for s: Variant in e.get("form_species", []):
		var sid: SpeciesId.Id = SpeciesId.from_token(str(s))
		if sid != SpeciesId.Id.NONE:
			data.form_species.append(sid)

	return data


func _growth(token: String) -> PokemonEnums.Growth:
	match token:
		"ERRATIC":
			return PokemonEnums.Growth.ERRATIC
		"FLUCTUATING":
			return PokemonEnums.Growth.FLUCTUATING
		"MEDIUM_SLOW":
			return PokemonEnums.Growth.MEDIUM_SLOW
		"FAST":
			return PokemonEnums.Growth.FAST
		"SLOW":
			return PokemonEnums.Growth.SLOW
		_:
			return PokemonEnums.Growth.MEDIUM_FAST


func _egg_group(token: String) -> PokemonEnums.EggGroup:
	match token:
		"MONSTER":
			return PokemonEnums.EggGroup.MONSTER
		"WATER_1":
			return PokemonEnums.EggGroup.WATER_1
		"BUG":
			return PokemonEnums.EggGroup.BUG
		"FLYING":
			return PokemonEnums.EggGroup.FLYING
		"FIELD":
			return PokemonEnums.EggGroup.FIELD
		"FAIRY":
			return PokemonEnums.EggGroup.FAIRY
		"GRASS":
			return PokemonEnums.EggGroup.GRASS
		"HUMAN_LIKE":
			return PokemonEnums.EggGroup.HUMAN_LIKE
		"WATER_3":
			return PokemonEnums.EggGroup.WATER_3
		"MINERAL":
			return PokemonEnums.EggGroup.MINERAL
		"AMORPHOUS":
			return PokemonEnums.EggGroup.AMORPHOUS
		"WATER_2":
			return PokemonEnums.EggGroup.WATER_2
		"DITTO":
			return PokemonEnums.EggGroup.DITTO
		"DRAGON":
			return PokemonEnums.EggGroup.DRAGON
		"NO_EGGS":
			return PokemonEnums.EggGroup.NO_EGGS
		_:
			return PokemonEnums.EggGroup.NONE


func _body_color(token: String) -> PokemonEnums.BodyColor:
	match token:
		"BLUE":
			return PokemonEnums.BodyColor.BLUE
		"YELLOW":
			return PokemonEnums.BodyColor.YELLOW
		"GREEN":
			return PokemonEnums.BodyColor.GREEN
		"BLACK":
			return PokemonEnums.BodyColor.BLACK
		"BROWN":
			return PokemonEnums.BodyColor.BROWN
		"PURPLE":
			return PokemonEnums.BodyColor.PURPLE
		"GRAY", "GREY":
			return PokemonEnums.BodyColor.GRAY
		"WHITE":
			return PokemonEnums.BodyColor.WHITE
		"PINK":
			return PokemonEnums.BodyColor.PINK
		_:
			return PokemonEnums.BodyColor.RED
