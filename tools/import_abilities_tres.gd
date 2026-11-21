@tool
extends EditorScript
## MIGRACIÓN: abilities.json → Datos/Abilities/Resources/*.tres + ability_paths.res

const JSON_PATH: String = "res://Datos/Abilities/abilities.json"
const OUT_DIR: String = "res://Datos/Abilities/Resources"
const INDEX_PATH: String = "res://Datos/Abilities/ability_paths.res"


func _run() -> void:
	if not FileAccess.file_exists(JSON_PATH):
		push_error("import_abilities_tres: no existe %s" % JSON_PATH)
		return
	var text: String = FileAccess.get_file_as_string(JSON_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("import_abilities_tres: JSON no es Array")
		return

	_ensure_dir(OUT_DIR)

	var index := AbilityPathsIndex.new()
	index.source_json = JSON_PATH
	index.built_at = Time.get_datetime_string_from_system(true)
	index.paths = {}
	index.display_names = {}
	index.ids = []

	var ok: int = 0
	var skipped: int = 0
	var errors: int = 0

	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			skipped += 1
			continue
		var d: Dictionary = entry
		var token: String = str(d.get("id", "")).strip_edges()
		if token.is_empty() or token == "NONE":
			skipped += 1
			continue
		var aid: AbilityId.Id = AbilityId.from_token(token)
		if aid == AbilityId.Id.NONE:
			skipped += 1
			push_warning("import_abilities_tres: token desconocido %s" % token)
			continue

		var data: AbilityData = _from_dict(d, aid)
		if data == null or data.id == AbilityId.Id.NONE:
			errors += 1
			continue
		if data.display_name.is_empty():
			data.display_name = token.replace("_", " ").capitalize()

		var path: String = OUT_DIR.path_join("%s.tres" % token)
		var err: Error = ResourceSaver.save(data, path)
		if err != OK:
			errors += 1
			push_error("import_abilities_tres: no se pudo guardar %s" % path)
			continue

		var key: int = int(aid)
		index.paths[key] = path
		index.display_names[key] = data.display_name
		index.ids.append(key)
		ok += 1

	index.entry_count = index.ids.size()
	var ierr: Error = ResourceSaver.save(index, INDEX_PATH)
	if ierr != OK:
		push_error("import_abilities_tres: no se pudo guardar índice")
		return
	print("import_abilities_tres: OK — %d .tres, %d omitidos, %d errores → %s" % [ok, skipped, errors, INDEX_PATH])


func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)


func _from_dict(e: Dictionary, id: AbilityId.Id) -> AbilityData:
	var data := AbilityData.new()
	data.id = id
	data.display_name = str(e.get("display_name", ""))
	data.description = str(e.get("description", ""))
	data.ai_rating = int(e.get("ai_rating", 0))
	data.cant_be_copied = bool(e.get("cant_be_copied", false))
	data.cant_be_swapped = bool(e.get("cant_be_swapped", false))
	data.cant_be_traced = bool(e.get("cant_be_traced", false))
	data.cant_be_suppressed = bool(e.get("cant_be_suppressed", false))
	data.cant_be_overwritten = bool(e.get("cant_be_overwritten", false))
	data.breakable = bool(e.get("breakable", false))
	data.fails_on_imposter = bool(e.get("fails_on_imposter", false))
	return data
