extends Node
## Catálogo de especies — estilo PokeDot-Engine.
##
## Arranque: solo carga species_paths.res (id → path + nombres).
## get_data(id): ResourceLoader.load del .tres de esa especie y cachea.
##
## Genera recursos con: tools/import_species_tres.gd → File → Run

const INDEX_PATH: String = "res://Datos/Pokemon/species_paths.res"

## SpeciesId.Id → SpeciesData
var _cache: Dictionary = {}
var _index: SpeciesPathsIndex = null
var _loaded: bool = false
var _loading: bool = false


func _ready() -> void:
	call_deferred("warm_index")


func warm_index() -> void:
	if _loaded or _loading:
		return
	_loading = true
	_load_index()


func is_ready() -> bool:
	return _loaded


func count() -> int:
	_wait_ready()
	if _index == null:
		return 0
	return _index.entry_count


func all_ids() -> Array:
	_wait_ready()
	if _index == null:
		return []
	var out: Array = []
	out.resize(_index.ids.size())
	for i: int in _index.ids.size():
		out[i] = _index.ids[i] as SpeciesId.Id
	return out


func has_species(id: SpeciesId.Id) -> bool:
	if id == SpeciesId.Id.NONE:
		return false
	if _cache.has(id):
		return true
	_wait_ready()
	return _index != null and _index.has_id(int(id))


func get_data(id: SpeciesId.Id) -> SpeciesData:
	if id == SpeciesId.Id.NONE:
		return null
	if _cache.has(id):
		return _cache[id] as SpeciesData
	_wait_ready()
	if _index == null:
		return null
	var path: String = _index.path_for(int(id))
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("SpeciesCatalog: falta archivo %s (id %s)" % [path, SpeciesId.to_token(id)])
		return null
	var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res == null or not (res is SpeciesData):
		push_warning("SpeciesCatalog: recurso inválido %s" % path)
		return null
	var data: SpeciesData = res as SpeciesData
	if data.is_valid():
		_cache[id] = data
		return data
	return null


func get_display_name(id: SpeciesId.Id) -> String:
	if id == SpeciesId.Id.NONE:
		return ""
	if _cache.has(id):
		return (_cache[id] as SpeciesData).display_name
	_wait_ready()
	if _index != null and _index.display_names.has(int(id)):
		return str(_index.display_names[int(id)])
	return SpeciesId.to_token(id)


func get_national_dex(id: SpeciesId.Id) -> int:
	if id == SpeciesId.Id.NONE:
		return 0
	if _cache.has(id):
		return (_cache[id] as SpeciesData).national_dex
	_wait_ready()
	if _index != null and _index.national_dex.has(int(id)):
		return int(_index.national_dex[int(id)])
	return 0


## Precarga un conjunto de ids (p. ej. party + caja visible).
func preload_ids(ids: Array) -> void:
	for v: Variant in ids:
		var sid: SpeciesId.Id = v as SpeciesId.Id
		if sid != SpeciesId.Id.NONE:
			get_data(sid)


func clear_cache() -> void:
	_cache.clear()


func reload() -> void:
	_cache.clear()
	_index = null
	_loaded = false
	_loading = false
	warm_index()


func _wait_ready() -> void:
	if _loaded:
		return
	if not _loading:
		_load_index()
		return
	var spins: int = 0
	while _loading and not _loaded and spins < 1000:
		OS.delay_msec(1)
		spins += 1
	if not _loaded:
		_load_index()


func _load_index() -> void:
	_loading = true
	if not ResourceLoader.exists(INDEX_PATH):
		push_error(
			"SpeciesCatalog: no existe %s. "
			% INDEX_PATH
			+ "Ejecuta tools/import_species_tres.gd (File → Run) en el editor."
		)
		_index = null
		_loaded = true
		_loading = false
		return

	var res: Resource = load(INDEX_PATH)
	if res is SpeciesPathsIndex:
		_index = res as SpeciesPathsIndex
		_loaded = true
		_loading = false
		print(
			"SpeciesCatalog: índice paths %d especies (%s)"
			% [_index.entry_count, INDEX_PATH]
		)
		return

	push_error("SpeciesCatalog: %s no es SpeciesPathsIndex" % INDEX_PATH)
	_index = null
	_loaded = true
	_loading = false
