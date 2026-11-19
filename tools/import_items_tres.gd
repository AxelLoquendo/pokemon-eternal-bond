@tool
extends EditorScript
## MIGRACIÓN opcional: items.json → Datos/Items/Resources/*.tres + item_paths.res
## Una vez hecho, el flujo diario es editar .tres + rebuild_items_index.gd

const JSON_PATH: String = "res://Datos/Items/items.json"
const OUT_DIR: String = "res://Datos/Items/Resources"
const INDEX_PATH: String = "res://Datos/Items/item_paths.res"


func _run() -> void:
	if not FileAccess.file_exists(JSON_PATH):
		push_error("import_items_tres: no existe %s" % JSON_PATH)
		return
	var text: String = FileAccess.get_file_as_string(JSON_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("import_items_tres: JSON no es Array")
		return

	_ensure_dir(OUT_DIR)

	var index := ItemPathsIndex.new()
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
		if token.is_empty():
			skipped += 1
			continue
		var iid: ItemId.Id = ItemId.from_token(token)
		if iid == ItemId.Id.NONE:
			skipped += 1
			push_warning("import_items_tres: token desconocido %s" % token)
			continue

		var data: ItemData = _from_dict(d, iid)
		if data == null or data.id == ItemId.Id.NONE:
			errors += 1
			continue
		if data.display_name.is_empty():
			data.display_name = token.replace("_", " ").capitalize()

		# icon_name por defecto = token en minúsculas (poke_ball.png)
		if data.icon_name.is_empty():
			data.icon_name = token.to_lower()

		var pocket_folder: String = _pocket_folder(data.pocket)
		var folder: String = OUT_DIR.path_join(pocket_folder)
		_ensure_dir(folder)
		var path: String = folder.path_join("%s.tres" % token)

		var err: Error = ResourceSaver.save(data, path)
		if err != OK:
			errors += 1
			push_error("import_items_tres: no se pudo guardar %s" % path)
			continue

		var key: int = int(iid)
		index.paths[key] = path
		index.display_names[key] = data.display_name
		index.ids.append(key)
		ok += 1

	index.entry_count = index.ids.size()
	var ierr: Error = ResourceSaver.save(index, INDEX_PATH)
	if ierr != OK:
		push_error("import_items_tres: no se pudo guardar índice")
		return
	print("import_items_tres: OK — %d .tres, %d omitidos, %d errores → %s" % [ok, skipped, errors, INDEX_PATH])


func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)


func _pocket_folder(p: ItemPocket.Id) -> String:
	match p:
		ItemPocket.Id.MEDICINE:
			return "medicine"
		ItemPocket.Id.BALLS:
			return "balls"
		ItemPocket.Id.BATTLE:
			return "battle"
		ItemPocket.Id.BERRIES:
			return "berries"
		ItemPocket.Id.KEY_ITEMS:
			return "key_items"
		ItemPocket.Id.TMS:
			return "tms"
		ItemPocket.Id.NONE:
			return "other"
		_:
			return "items"


func _from_dict(e: Dictionary, id: ItemId.Id) -> ItemData:
	var data := ItemData.new()
	data.id = id
	data.display_name = str(e.get("display_name", ""))
	data.description = str(e.get("description", ""))
	data.pocket = _pocket(str(e.get("pocket", "ITEMS")))
	data.price = int(e.get("price", 0))
	data.important = bool(e.get("important", false))
	data.hold_effect = str(e.get("hold_effect", ""))
	data.hold_effect_param = int(e.get("hold_effect_param", 0))
	data.field_use = str(e.get("field_use", ""))
	data.battle_use = str(e.get("battle_use", ""))
	data.sort_type = str(e.get("sort_type", ""))
	data.fling_power = int(e.get("fling_power", 0))
	data.tm_move = MoveId.from_token(str(e.get("tm_move", "")))
	data.icon_name = str(e.get("icon_name", "")).strip_edges()
	if data.pocket == ItemPocket.Id.KEY_ITEMS or data.important:
		data.stack_limit = 1
	else:
		data.stack_limit = 999
	return data


func _pocket(token: String) -> ItemPocket.Id:
	match token:
		"MEDICINE":
			return ItemPocket.Id.MEDICINE
		"BALLS":
			return ItemPocket.Id.BALLS
		"BATTLE":
			return ItemPocket.Id.BATTLE
		"BERRIES":
			return ItemPocket.Id.BERRIES
		"KEY_ITEMS":
			return ItemPocket.Id.KEY_ITEMS
		"TMS":
			return ItemPocket.Id.TMS
		"NONE":
			return ItemPocket.Id.NONE
		_:
			return ItemPocket.Id.ITEMS
