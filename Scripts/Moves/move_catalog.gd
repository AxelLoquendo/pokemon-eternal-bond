extends Node
## Catálogo de movimientos — lazy .tres (sin JSON en runtime).
##
## Arranque: move_paths.res
## get_move(id): carga el .tres y cachea.
##
## Migración: tools/import_moves_tres.gd
## Diario: editar .tres + tools/rebuild_moves_index.gd

const INDEX_PATH: String = "res://Datos/Moves/move_paths.res"

var _cache: Dictionary = {}
var _index: MovePathsIndex = null
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
		out[i] = _index.ids[i] as MoveId.Id
	return out


func has_move(id: MoveId.Id) -> bool:
	if id == MoveId.Id.NONE:
		return false
	if _cache.has(id):
		return true
	_ensure()
	return _index != null and _index.has_id(int(id))


func get_move(id: MoveId.Id) -> MoveData:
	if id == MoveId.Id.NONE:
		return null
	if _cache.has(id):
		return _cache[id] as MoveData
	_ensure()
	if _index == null:
		return null
	var path: String = _index.path_for(int(id))
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("MoveCatalog: falta %s (id %s)" % [path, MoveId.to_token(id)])
		return null
	var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res == null or not (res is MoveData):
		push_warning("MoveCatalog: recurso inválido %s" % path)
		return null
	var data: MoveData = res as MoveData
	if data.is_valid():
		_cache[id] = data
		return data
	return null


func get_display_name(id: MoveId.Id) -> String:
	if id == MoveId.Id.NONE:
		return ""
	if _cache.has(id):
		return (_cache[id] as MoveData).display_name
	_ensure()
	if _index != null and _index.display_names.has(int(id)):
		return str(_index.display_names[int(id)])
	return MoveId.to_token(id)


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
			"MoveCatalog: no existe %s. Ejecuta tools/import_moves_tres.gd o rebuild_moves_index.gd"
			% INDEX_PATH
		)
		_index = null
		_loaded = true
		return
	var res: Resource = load(INDEX_PATH)
	if res is MovePathsIndex:
		_index = res as MovePathsIndex
		_loaded = true
		print("MoveCatalog: índice %d moves (%s)" % [_index.entry_count, INDEX_PATH])
		return
	push_error("MoveCatalog: %s no es MovePathsIndex" % INDEX_PATH)
	_index = null
	_loaded = true
