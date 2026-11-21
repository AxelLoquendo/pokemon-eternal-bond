extends Node
## Catálogo de habilidades — lazy .tres (sin JSON en runtime).
##
## Arranque: ability_paths.res
## get_ability(id): carga el .tres y cachea.
##
## Migración: tools/import_abilities_tres.gd
## Diario: editar .tres + tools/rebuild_abilities_index.gd

const INDEX_PATH: String = "res://Datos/Abilities/ability_paths.res"

var _cache: Dictionary = {}
var _index: AbilityPathsIndex = null
var _loaded: bool = false


func _ready() -> void:
	call_deferred("warm_index")


func warm_index() -> void:
	if _loaded:
		return
	_load_index()


func is_ready() -> bool:
	return _loaded


func count() -> int:
	_ensure()
	if _index == null:
		return 0
	return _index.entry_count


func all_ids() -> Array:
	_ensure()
	if _index == null:
		return []
	var out: Array = []
	out.resize(_index.ids.size())
	for i: int in _index.ids.size():
		out[i] = _index.ids[i] as AbilityId.Id
	return out


func has_ability(id: AbilityId.Id) -> bool:
	if id == AbilityId.Id.NONE:
		return false
	if _cache.has(id):
		return true
	_ensure()
	return _index != null and _index.has_id(int(id))


func get_ability(id: AbilityId.Id) -> AbilityData:
	if id == AbilityId.Id.NONE:
		return null
	if _cache.has(id):
		return _cache[id] as AbilityData
	_ensure()
	if _index == null:
		return null
	var path: String = _index.path_for(int(id))
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("AbilityCatalog: falta %s (id %s)" % [path, AbilityId.to_token(id)])
		return null
	var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res == null or not (res is AbilityData):
		push_warning("AbilityCatalog: recurso inválido %s" % path)
		return null
	var data: AbilityData = res as AbilityData
	if data.is_valid():
		_cache[id] = data
		return data
	return null


func get_display_name(id: AbilityId.Id) -> String:
	if id == AbilityId.Id.NONE:
		return ""
	if _cache.has(id):
		return (_cache[id] as AbilityData).display_name
	_ensure()
	if _index != null and _index.display_names.has(int(id)):
		return str(_index.display_names[int(id)])
	return AbilityId.to_token(id)


func clear_cache() -> void:
	_cache.clear()


func reload() -> void:
	_cache.clear()
	_index = null
	_loaded = false
	warm_index()


func _ensure() -> void:
	if not _loaded:
		_load_index()


func _load_index() -> void:
	if not ResourceLoader.exists(INDEX_PATH):
		push_error(
			"AbilityCatalog: no existe %s. Ejecuta tools/import_abilities_tres.gd o rebuild_abilities_index.gd"
			% INDEX_PATH
		)
		_index = null
		_loaded = true
		return
	var res: Resource = load(INDEX_PATH)
	if res is AbilityPathsIndex:
		_index = res as AbilityPathsIndex
		_loaded = true
		print("AbilityCatalog: índice %d habilidades (%s)" % [_index.entry_count, INDEX_PATH])
		return
	push_error("AbilityCatalog: %s no es AbilityPathsIndex" % INDEX_PATH)
	_index = null
	_loaded = true
