extends Node
## Catálogo de ítems — mismo patrón que SpeciesCatalog.
##
## Arranque: solo carga item_paths.res (id → path).
## get_item(id): carga el .tres bajo demanda y cachea.
##
## Flujo diario: editar .tres → tools/rebuild_items_index.gd si creas/borras.
## Migración: tools/import_items_tres.gd desde items.json (una vez).

const INDEX_PATH: String = "res://Datos/Items/item_paths.res"
const ICONS_ROOT: String = "res://Graficos/Items/icons/"

var _cache: Dictionary = {} ## ItemId → ItemData
var _index: ItemPathsIndex = null
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
		out[i] = _index.ids[i] as ItemId.Id
	return out


func has_item(id: ItemId.Id) -> bool:
	if id == ItemId.Id.NONE:
		return false
	if _cache.has(id):
		return true
	_ensure()
	return _index != null and _index.has_id(int(id))


func get_item(id: ItemId.Id) -> ItemData:
	if id == ItemId.Id.NONE:
		return null
	if _cache.has(id):
		return _cache[id] as ItemData
	_ensure()
	if _index == null:
		return null
	var path: String = _index.path_for(int(id))
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("ItemCatalog: falta %s (id %s)" % [path, ItemId.to_token(id)])
		return null
	var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res == null or not (res is ItemData):
		push_warning("ItemCatalog: recurso inválido %s" % path)
		return null
	var data: ItemData = res as ItemData
	if data.is_valid():
		_cache[id] = data
		return data
	return null


func get_display_name(id: ItemId.Id) -> String:
	if id == ItemId.Id.NONE:
		return ""
	if _cache.has(id):
		return (_cache[id] as ItemData).display_name
	_ensure()
	if _index != null and _index.display_names.has(int(id)):
		return str(_index.display_names[int(id)])
	return ItemId.to_token(id)


func get_icon(id: ItemId.Id) -> Texture2D:
	var data: ItemData = get_item(id)
	var name: String = ""
	if data != null:
		name = data.resolved_icon_name()
	else:
		name = ItemId.to_token(id).to_lower()
	if name.is_empty():
		return null
	var path: String = ICONS_ROOT + name + ".png"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func stack_limit(id: ItemId.Id) -> int:
	var data: ItemData = get_item(id)
	if data != null:
		return maxi(1, data.stack_limit)
	return 999


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
			"ItemCatalog: no existe %s. Ejecuta tools/import_items_tres.gd o rebuild_items_index.gd"
			% INDEX_PATH
		)
		_index = null
		_loaded = true
		return
	var res: Resource = load(INDEX_PATH)
	if res is ItemPathsIndex:
		_index = res as ItemPathsIndex
		_loaded = true
		print("ItemCatalog: índice %d ítems (%s)" % [_index.entry_count, INDEX_PATH])
		return
	push_error("ItemCatalog: %s no es ItemPathsIndex" % INDEX_PATH)
	_index = null
	_loaded = true
