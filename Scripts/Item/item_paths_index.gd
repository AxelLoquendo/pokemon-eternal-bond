class_name ItemPathsIndex
extends Resource
## Índice ligero: ItemId → path del .tres + nombre.
## Generado por tools/rebuild_items_index.gd (o import_items_tres una vez).

@export var paths: Dictionary = {} ## int(ItemId) → String path
@export var display_names: Dictionary = {} ## int → String
@export var ids: Array = [] ## Array[int]
@export var entry_count: int = 0
@export var built_at: String = ""
@export var source_json: String = ""


func has_id(key: int) -> bool:
	return paths.has(key)


func path_for(key: int) -> String:
	if paths.has(key):
		return str(paths[key])
	return ""
