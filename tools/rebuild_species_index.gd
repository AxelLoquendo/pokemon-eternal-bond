@tool
extends EditorScript
## Escanea Datos/Pokemon/Resources/**/*.tres y regenera species_paths.res.
## No usa JSON. Tras crear/editar/borrar un SpeciesData .tres, ejecuta esto:
##   File → Run

const RESOURCES_DIR: String = "res://Datos/Pokemon/Resources"
const INDEX_PATH: String = "res://Datos/Pokemon/species_paths.res"


func _run() -> void:
	var index := SpeciesPathsIndex.new()
	index.source_json = "" # ya no depende de JSON
	index.built_at = Time.get_datetime_string_from_system(true)
	index.paths = {}
	index.display_names = {}
	index.national_dex = {}
	index.ids = []

	var paths: PackedStringArray = _collect_tres(RESOURCES_DIR)
	paths.sort()

	var ok: int = 0
	var errors: int = 0
	for path: String in paths:
		var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res == null or not (res is SpeciesData):
			errors += 1
			push_warning("rebuild_species_index: no es SpeciesData %s" % path)
			continue
		var data: SpeciesData = res as SpeciesData
		if data.id == SpeciesId.Id.NONE:
			errors += 1
			push_warning("rebuild_species_index: id NONE en %s" % path)
			continue
		if data.display_name.is_empty():
			data.display_name = SpeciesId.to_token(data.id)
		var key: int = int(data.id)
		if index.paths.has(key):
			push_warning(
				"rebuild_species_index: id duplicado %s\n  %s\n  %s"
				% [SpeciesId.to_token(data.id), index.paths[key], path]
			)
		index.paths[key] = path
		index.display_names[key] = data.display_name
		index.national_dex[key] = data.national_dex
		if key not in index.ids:
			index.ids.append(key)
		ok += 1

	index.ids.sort()
	index.entry_count = index.ids.size()
	var err: Error = ResourceSaver.save(index, INDEX_PATH)
	if err != OK:
		push_error("rebuild_species_index: no se pudo guardar %s (%s)" % [INDEX_PATH, error_string(err)])
		return
	print(
		"rebuild_species_index: OK — %d .tres, %d errores → %s"
		% [ok, errors, INDEX_PATH]
	)


func _collect_tres(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("rebuild_species_index: no existe %s" % dir_path)
		return out
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full: String = dir_path.path_join(name)
		if dir.current_is_dir():
			out.append_array(_collect_tres(full))
		elif name.ends_with(".tres"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
	return out
