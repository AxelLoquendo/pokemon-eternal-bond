@tool
extends EditorScript
## MIGRACIÓN: moves.json → Datos/Moves/Resources/*.tres + move_paths.res
## Una vez hecho, editar solo .tres + rebuild_moves_index.gd

const JSON_PATH: String = "res://Datos/Moves/moves.json"
const OUT_DIR: String = "res://Datos/Moves/Resources"
const INDEX_PATH: String = "res://Datos/Moves/move_paths.res"


func _run() -> void:
	if not FileAccess.file_exists(JSON_PATH):
		push_error("import_moves_tres: no existe %s" % JSON_PATH)
		return
	var text: String = FileAccess.get_file_as_string(JSON_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("import_moves_tres: JSON no es Array")
		return

	_ensure_dir(OUT_DIR)

	var index := MovePathsIndex.new()
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
		var mid: MoveId.Id = MoveId.from_token(token)
		if mid == MoveId.Id.NONE:
			skipped += 1
			push_warning("import_moves_tres: token desconocido %s" % token)
			continue

		var data: MoveData = _from_dict(d, mid)
		if data == null or data.id == MoveId.Id.NONE:
			errors += 1
			continue
		if data.display_name.is_empty():
			data.display_name = token.replace("_", " ").capitalize()

		var type_folder: String = _type_folder(data.type)
		var folder: String = OUT_DIR.path_join(type_folder)
		_ensure_dir(folder)
		var path: String = folder.path_join("%s.tres" % token)

		var err: Error = ResourceSaver.save(data, path)
		if err != OK:
			errors += 1
			push_error("import_moves_tres: no se pudo guardar %s" % path)
			continue

		var key: int = int(mid)
		index.paths[key] = path
		index.display_names[key] = data.display_name
		index.ids.append(key)
		ok += 1

	index.entry_count = index.ids.size()
	var ierr: Error = ResourceSaver.save(index, INDEX_PATH)
	if ierr != OK:
		push_error("import_moves_tres: no se pudo guardar índice")
		return
	print("import_moves_tres: OK — %d .tres, %d omitidos, %d errores → %s" % [ok, skipped, errors, INDEX_PATH])


func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)


func _type_folder(t: TypeId.Id) -> String:
	var token: String = TypeId.to_token(t).to_lower()
	if token.is_empty() or token == "none":
		return "other"
	return token


func _from_dict(e: Dictionary, id: MoveId.Id) -> MoveData:
	var data := MoveData.new()
	data.id = id
	data.display_name = str(e.get("display_name", ""))
	data.description = str(e.get("description", ""))
	data.type = TypeId.from_token(str(e.get("type", "NONE")))
	data.category = _category(str(e.get("category", "NONE")))
	data.power = int(e.get("power", 0))
	data.accuracy = int(e.get("accuracy", 100))
	data.pp = int(e.get("pp", 5))
	data.priority = int(e.get("priority", 0))
	data.target = str(e.get("target", "SELECTED")).replace("TARGET_", "")
	data.effect = str(e.get("effect", "EFFECT_HIT"))
	data.strike_count = int(e.get("strike_count", 1))
	data.critical_stage = int(e.get("critical_stage", 0))
	data.recoil = int(e.get("recoil", 0))
	data.makes_contact = bool(e.get("makes_contact", false))
	data.ignores_protect = bool(e.get("ignores_protect", false))
	data.sound = bool(e.get("sound", false))
	data.punch = bool(e.get("punch", false))
	data.bite = bool(e.get("bite", false))
	data.pulse = bool(e.get("pulse", false))
	data.ballistic = bool(e.get("ballistic", false))
	data.powder = bool(e.get("powder", false))
	data.slicing = bool(e.get("slicing", false))
	data.wind = bool(e.get("wind", false))
	data.dance = bool(e.get("dance", false))
	data.healing = bool(e.get("healing", false))
	data.ignores_substitute = bool(e.get("ignores_substitute", false))
	data.z_effect = str(e.get("z_effect", ""))
	data.extra_flags = PackedStringArray()
	for f: Variant in e.get("extra_flags", []):
		data.extra_flags.append(str(f))
	return data


func _category(token: String) -> MoveCategory.Id:
	match token:
		"PHYSICAL":
			return MoveCategory.Id.PHYSICAL
		"SPECIAL":
			return MoveCategory.Id.SPECIAL
		"STATUS":
			return MoveCategory.Id.STATUS
		_:
			return MoveCategory.Id.NONE
