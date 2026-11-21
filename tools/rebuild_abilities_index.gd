@tool
extends EditorScript
## Escanea Datos/Abilities/Resources/*.tres → ability_paths.res

const RESOURCES_DIR: String = "res://Datos/Abilities/Resources"
const INDEX_PATH: String = "res://Datos/Abilities/ability_paths.res"


func _run() -> void:
	var index := AbilityPathsIndex.new()
	index.source_json = ""
	index.built_at = Time.get_datetime_string_from_system(true)
	index.paths = {}
	index.display_names = {}
	index.ids = []

	var dir := DirAccess.open(RESOURCES_DIR)
	if dir == null:
		push_error("rebuild_abilities_index: no existe %s" % RESOURCES_DIR)
		return

	var paths: PackedStringArray = PackedStringArray()
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if not name.begins_with(".") and name.ends_with(".tres"):
			paths.append(RESOURCES_DIR.path_join(name))
		name = dir.get_next()
	dir.list_dir_end()
	paths.sort()

	var ok: int = 0
	var errors: int = 0
	for path: String in paths:
		var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res == null or not (res is AbilityData):
			errors += 1
			continue
		var data: AbilityData = res as AbilityData
		if data.id == AbilityId.Id.NONE:
			errors += 1
			continue
		var key: int = int(data.id)
		if index.paths.has(key):
			push_warning("rebuild_abilities_index: id duplicado %s" % AbilityId.to_token(data.id))
		index.paths[key] = path
		index.display_names[key] = data.display_name
		if key not in index.ids:
			index.ids.append(key)
		ok += 1

	index.ids.sort()
	index.entry_count = index.ids.size()
	var err: Error = ResourceSaver.save(index, INDEX_PATH)
	if err != OK:
		push_error("rebuild_abilities_index: no se pudo guardar índice")
		return
	print("rebuild_abilities_index: OK — %d .tres, %d errores → %s" % [ok, errors, INDEX_PATH])
